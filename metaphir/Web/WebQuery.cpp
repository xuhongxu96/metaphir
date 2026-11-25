#include "metaphir/Web/WebQuery.h"
#include "metaphir/Dialect/Pattern/SourceLocation.h"
#include "metaphir/Dialect/Surface/SurfacePrinter.h"
#include "metaphir/Exec/CompiledPattern.h"
#include "metaphir/Exec/PlanMatcher.h"
#include "metaphir/Index/FeatureCoding.h"
#include "metaphir/Index/FunctionPack.h"
#include "llvm/ADT/STLExtras.h"
#include "llvm/ADT/Sequence.h"
#include "llvm/IR/AssemblyAnnotationWriter.h"
#include "llvm/IR/Function.h"
#include "llvm/IR/LLVMContext.h"
#include "llvm/IR/ModuleSlotTracker.h"
#include "llvm/Support/DataExtractor.h"
#include "llvm/Support/Endian.h"
#include "llvm/Support/FormattedStream.h"
#include "llvm/Support/MemoryBuffer.h"
#include "llvm/Support/SourceMgr.h"
#include "llvm/Support/raw_ostream.h"
#include <map>
#include <numeric>

namespace llvm {
namespace metaphir {

/// A compiled pattern, and the warnings it was compiled with.
struct WebQuery::Compiled {
  std::vector<PatternNote> Warnings;
  std::unique_ptr<CompiledPattern> Pattern;
};

WebQuery::WebQuery(const WebIndex &Index) : Index(Index) {}
WebQuery::~WebQuery() = default;

Expected<std::unique_ptr<WebQuery>>
WebQuery::compile(const WebIndex &Index, StringRef Source, StringRef Name) {
  std::unique_ptr<WebQuery> Query(new WebQuery(Index));
  Query->Pattern = std::make_unique<Compiled>();
  Compiled &Pattern = *Query->Pattern;
  std::string Message;
  raw_string_ostream Err(Message);
  // Warnings are not errors: they are kept for the page.
  Pattern.Pattern = CompiledPattern::compile(
      MemoryBuffer::getMemBufferCopy(Source, Name), Err, /*ProgName=*/nullptr,
      {}, [&](SourceMgr &SM) {
        SM.setDiagHandler(
            [](const SMDiagnostic &Diag, void *Warnings) {
              bool Located = Diag.getLineNo() > 0;
              static_cast<std::vector<PatternNote> *>(Warnings)->push_back(
                  {Diag.getMessage().str(),
                   Located ? unsigned(Diag.getLineNo()) : 0,
                   Located ? unsigned(Diag.getColumnNo() + 1) : 0});
            },
            &Pattern.Warnings);
      });
  if (!Pattern.Pattern)
    return createStringError(Message);
  return Query;
}

std::vector<ByteRange> WebQuery::getKeyRanges() const {
  std::vector<ByteRange> Ranges;
  if (Mode == WebQueryMode::NoIndex)
    return Ranges;
  for (const PostingKey &Key :
       Pattern->Pattern->Query->getRetrieval()->getKeys())
    if (std::optional<ByteRange> Block = Index.getKeyBlock(Key))
      Ranges.push_back(*Block);
  return mergeRanges(std::move(Ranges));
}

Expected<std::vector<ByteRange>> WebQuery::findLists(const ByteCache &Cache) {
  if (Mode == WebQueryMode::NoIndex)
    return std::vector<ByteRange>();
  const RetrievalPlan &Plan = *Pattern->Pattern->Query->getRetrieval();
  std::map<PostingKey, std::optional<WebPosting>> Postings;
  for (const PostingKey &Key : Plan.getKeys()) {
    Expected<std::optional<WebPosting>> Found = Index.findPosting(Key, Cache);
    if (!Found)
      return Found.takeError();
    Postings[Key] = *Found;
  }
  auto Count = [&](const PostingKey &Key) -> uint64_t {
    const std::optional<WebPosting> &Found = Postings[Key];
    return Found ? Found->Record.Count : 0;
  };
  std::optional<SmallVector<PostingKey, 8>> Keys = Plan.chooseLists(Count);
  if (!Keys)
    return createStringError(
        "the pattern needs no instruction, so it could match any function "
        "of the corpus");
  Lists.clear();
  std::vector<ByteRange> Ranges;
  for (auto &[Key, Found] : Postings) {
    // No function has a key without a record: its list is empty.
    bool Read = is_contained(*Keys, Key) && Found;
    Lists.push_back({Key, Found ? Found->List : ByteRange{WebFile::Lists, 0, 0},
                     Found ? Found->Record.Count : 0, Read});
    if (Read)
      Ranges.push_back(Found->List);
  }
  return mergeRanges(std::move(Ranges));
}

Expected<std::vector<ByteRange>>
WebQuery::findCandidates(const ByteCache &Cache) {
  if (Mode == WebQueryMode::NoIndex) {
    // Every function, so the entries of all of them.
    Candidates.resize(Index.getNumFunctions());
    std::iota(Candidates.begin(), Candidates.end(), 0);
    return std::vector<ByteRange>{
        ByteRange{WebFile::Index, 0,
                  (uint64_t(Candidates.size()) + 1) * WebIndexEntrySize}};
  }
  std::map<PostingKey, std::vector<uint32_t>> Numbers;
  for (const ChosenList &List : Lists) {
    if (Numbers.count(List.Key) || !List.Read)
      continue;
    Expected<StringRef> Bytes = Cache.read(List.Range);
    if (!Bytes)
      return Bytes.takeError();
    Expected<std::vector<uint32_t>> Read =
        readPostingList(*Bytes, 0, List.Count, Index.getNumFunctions());
    if (!Read)
      return Read.takeError();
    Numbers[List.Key] = std::move(*Read);
  }
  // The lists read are those the plan chose, from the same counts.
  std::map<PostingKey, uint64_t> Counts;
  for (const ChosenList &List : Lists)
    Counts[List.Key] = List.Count;
  Expected<std::optional<std::vector<uint32_t>>> Found =
      Pattern->Pattern->Query->getRetrieval()->evaluate(
          [&](const PostingKey &Key) -> uint64_t {
            auto It = Counts.find(Key);
            return It == Counts.end() ? 0 : It->second;
          },
          [&](const PostingKey &Key) -> Expected<ArrayRef<uint32_t>> {
            auto It = Numbers.find(Key);
            if (It != Numbers.end())
              return ArrayRef<uint32_t>(It->second);
            // A key no function has has no list to read.
            if (Counts[Key] == 0)
              return ArrayRef<uint32_t>();
            return createStringError("a posting list was not read");
          });
  if (!Found)
    return Found.takeError();
  Candidates = std::move(**Found);
  std::vector<ByteRange> Ranges;
  for (uint32_t Function : Candidates)
    Ranges.push_back(ByteRange{WebFile::Index,
                               uint64_t(Function) * WebIndexEntrySize,
                               2 * WebIndexEntrySize});
  return mergeRanges(std::move(Ranges));
}

Expected<std::pair<ByteRange, PackLocation>>
WebQuery::locate(size_t Position, const ByteCache &Cache) const {
  uint32_t Function = Candidates[Position];
  Expected<StringRef> Entries = Cache.read(
      ByteRange{WebFile::Index, uint64_t(Function) * WebIndexEntrySize,
                2 * WebIndexEntrySize});
  if (!Entries)
    return Entries.takeError();
  const char *Entry = Entries->data();
  uint64_t Features = support::endian::read64le(Entry);
  PackLocation Pack =
      PackLocation::decode(support::endian::read64le(Entry + 8));
  uint64_t FeaturesEnd = support::endian::read64le(Entry + 16);
  if (FeaturesEnd < Features)
    return createStringError("function index out of order");
  return std::make_pair(
      ByteRange{WebFile::Features, Features, FeaturesEnd - Features}, Pack);
}

Expected<std::vector<ByteRange>>
WebQuery::findFeatures(const ByteCache &Cache) {
  std::vector<ByteRange> Ranges;
  if (Mode == WebQueryMode::NoIndex)
    return Ranges;
  for (size_t Position = 0; Position != Candidates.size(); ++Position) {
    Expected<std::pair<ByteRange, PackLocation>> Location =
        locate(Position, Cache);
    if (!Location)
      return Location.takeError();
    Ranges.push_back(Location->first);
  }
  return mergeRanges(std::move(Ranges));
}

Expected<std::vector<ByteRange>>
WebQuery::filterCandidates(const ByteCache &Cache) {
  Matchable.clear();
  Packs.clear();
  for (size_t Position = 0; Position != Candidates.size(); ++Position) {
    Expected<std::pair<ByteRange, PackLocation>> Location =
        locate(Position, Cache);
    if (!Location)
      return Location.takeError();
    if (Mode == WebQueryMode::NoIndex) {
      Matchable.push_back(Candidates[Position]);
      Packs.push_back(Location->second);
      continue;
    }
    Expected<StringRef> Frame = Cache.read(Location->first);
    if (!Frame)
      return Frame.takeError();
    Expected<std::string> Bytes =
        Index.getFeatureDictionary().decompress(*Frame);
    if (!Bytes)
      return Bytes.takeError();
    Expected<FunctionFeatures> Features = readFunctionFeatures(*Bytes);
    if (!Features)
      return Features.takeError();
    const IndexQuery &Query = *Pattern->Pattern->Query;
    if (Mode == WebQueryMode::NoConstraints
            ? !any_of(seq<unsigned>(0, Query.size()),
                      [&](unsigned Variant) {
                        return Query.mayMatchStructure(Variant, *Features);
                      })
            : !Query.mayMatch(*Features))
      continue;
    Matchable.push_back(Candidates[Position]);
    Packs.push_back(Location->second);
  }
  std::vector<ByteRange> Frames;
  for (const PackLocation &Pack : Packs)
    Frames.push_back(Pack.Frame);
  return mergeRanges(std::move(Frames));
}

PackLocation WebQuery::getPackLocation(uint32_t Function) const {
  auto It = llvm::lower_bound(Matchable, Function);
  assert(It != Matchable.end() && *It == Function &&
         "not a matchable function");
  return Packs[It - Matchable.begin()];
}

namespace {
/// Records the line each instruction is printed on.
class LineRecorder : public AssemblyAnnotationWriter {
public:
  explicit LineRecorder(std::vector<unsigned> &Lines) : Lines(Lines) {}
  void emitInstructionAnnot(const llvm::Instruction *,
                            formatted_raw_ostream &OS) override {
    Lines.push_back(OS.getLine() + 1);
  }

private:
  std::vector<unsigned> &Lines;
};
} // namespace

/// The function whose pack is the one at PackIndex of Frame, read into Context.
static Expected<std::unique_ptr<UnpackedFunction>>
unpack(const WebIndex &Index, StringRef Frame, unsigned PackIndex,
       LLVMContext &Context) {
  Expected<std::string> Bytes = Index.getPackDictionary().decompress(Frame);
  if (!Bytes)
    return Bytes.takeError();
  // The frame's packs, each after its size.
  DataExtractor Data(*Bytes, /*IsLittleEndian=*/true);
  DataExtractor::Cursor C(0);
  StringRef Packed;
  for (unsigned I = 0; I <= PackIndex && C; ++I) {
    uint64_t Size = Data.getULEB128(C);
    if (C && Size > Bytes->size() - C.tell())
      return createStringError("pack frame: a pack past the end");
    Packed = Data.getBytes(C, Size);
  }
  if (!C)
    return createStringError("pack frame: no pack " + Twine(PackIndex) + ": " +
                             toString(C.takeError()));
  Expected<FunctionPack> Pack = FunctionPack::decode(Packed);
  if (!Pack)
    return Pack.takeError();
  return UnpackedFunction::read(*Pack, Context);
}

Expected<PrintedFunction> WebQuery::printFunction(const WebIndex &Index,
                                                  StringRef Frame,
                                                  unsigned PackIndex) {
  LLVMContext Context;
  Expected<std::unique_ptr<UnpackedFunction>> Unpacked =
      unpack(Index, Frame, PackIndex, Context);
  if (!Unpacked)
    return Unpacked.takeError();
  PrintedFunction Printed;
  raw_string_ostream OS(Printed.IR);
  LineRecorder Recorder(Printed.Lines);
  (*Unpacked)->getFunction().print(OS, &Recorder);
  return Printed;
}

ArrayRef<PatternNote> WebQuery::getWarnings() const {
  return Pattern->Warnings;
}

Error WebQuery::match(uint32_t Function, StringRef Frame, unsigned PackIndex,
                      raw_ostream &Out, bool PrintInstructions,
                      std::vector<RejectingConstraint> *Rejecting,
                      bool *HadStructuralMatch) {
  const WebModule &Module = Index.getModuleOf(Function);
  auto Located = [&](Error E) {
    return createStringError(Module.Path + ": function " +
                             Twine(Function - Module.FirstFunction) + ": " +
                             toString(std::move(E)));
  };
  LLVMContext Context;
  Expected<std::unique_ptr<UnpackedFunction>> Unpacked =
      unpack(Index, Frame, PackIndex, Context);
  if (!Unpacked)
    return Located(Unpacked.takeError());
  const llvm::Function &F = (*Unpacked)->getFunction();

  PlanMatcher Matcher(*Pattern->Pattern->Program);
  Matcher.setUseOracle(Unpacked->get());
  bool Structural = false;
  SmallVector<PlanRejection, 4> Unsatisfied;
  // No filter: the candidate's features were checked against the pattern
  // when it was found, and finding them again in its IR would take most of
  // the time matching it does.
  std::vector<PlanMatch> Matches =
      Matcher.match(F, Rejecting ? &Unsatisfied : nullptr,
                    Rejecting || HadStructuralMatch ? &Structural : nullptr);
  if (HadStructuralMatch)
    *HadStructuralMatch = Structural;
  ModuleSlotTracker Slots(F.getParent());
  Slots.incorporateFunction(F);
  if (Matches.empty()) {
    if (Structural && Rejecting)
      for (const PlanRejection &U : Unsatisfied) {
        RejectingConstraint &R = Rejecting->emplace_back();
        R.Function = ("@" + F.getName()).str();
        raw_string_ostream Message(R.Constraint.Message);
        printSurfaceExpression(Message, U.Expression);
        SMLoc Loc = U.Range.Start;
        const SourceMgr &SM = Pattern->Pattern->Source;
        if (getMainFileLine(SM, Loc))
          std::tie(R.Constraint.Line, R.Constraint.Column) =
              SM.getLineAndColumn(Loc, SM.getMainFileID());
        R.Reason = U.Reason;
        raw_string_ostream Bindings(R.Bindings);
        U.Rejected.print(Bindings, &Slots);
        raw_string_ostream Instructions(R.Instructions);
        U.Rejected.printInstructions(Instructions, Pattern->Pattern->Source);
      }
    return Error::success();
  }
  for (const PlanMatch &Match : Matches)
    Match.printLine(Out, Module.Path, F, &Slots,
                    PrintInstructions ? &Pattern->Pattern->Source : nullptr);
  return Error::success();
}

} // namespace metaphir
} // namespace llvm
