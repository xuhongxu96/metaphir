#include "metaphir/Web/WebQuery.h"
#include "metaphir/IR/Constraint.h"
#include "metaphir/IR/Instruction.h"
#include "metaphir/IR/MIRContext.h"
#include "metaphir/IR/PatternLowering.h"
#include "metaphir/IR/PatternVariants.h"
#include "metaphir/IR/SourceRange.h"
#include "metaphir/Index/FeatureCoding.h"
#include "metaphir/Index/FunctionPack.h"
#include "metaphir/Matching/FeatureQuery.h"
#include "metaphir/Matching/PatternMatcher.h"
#include "metaphir/Matching/Target.h"
#include "metaphir/Parser/MIRParser.h"
#include "llvm/ADT/STLExtras.h"
#include "llvm/IR/AssemblyAnnotationWriter.h"
#include "llvm/IR/Function.h"
#include "llvm/IR/LLVMContext.h"
#include "llvm/IR/ModuleSlotTracker.h"
#include "llvm/Support/Endian.h"
#include "llvm/Support/FormattedStream.h"
#include "llvm/Support/MemoryBuffer.h"
#include "llvm/Support/SourceMgr.h"
#include "llvm/Support/raw_ostream.h"
#include <map>

namespace llvm {
namespace metaphir {

/// A parsed and lowered pattern.
struct WebQuery::Compiled {
  SourceMgr Source;
  MIRContext Context;
  std::vector<PatternNote> Warnings;
  std::optional<PatternVariants> Variants;
  FeatureQuery Query;
};

WebQuery::WebQuery(const WebIndex &Index) : Index(Index) {}
WebQuery::~WebQuery() = default;

Expected<std::unique_ptr<WebQuery>>
WebQuery::compile(const WebIndex &Index, StringRef Source, StringRef Name) {
  std::unique_ptr<WebQuery> Query(new WebQuery(Index));
  Query->Pattern = std::make_unique<Compiled>();
  Compiled &Pattern = *Query->Pattern;
  // Warnings are not errors: they are kept for the page.
  Pattern.Source.setDiagHandler(
      [](const SMDiagnostic &Diag, void *Warnings) {
        bool Located = Diag.getLineNo() > 0;
        static_cast<std::vector<PatternNote> *>(Warnings)->push_back(
            {Diag.getMessage().str(), Located ? unsigned(Diag.getLineNo()) : 0,
             Located ? unsigned(Diag.getColumnNo() + 1) : 0});
      },
      &Pattern.Warnings);
  metaphir::Pattern *RawPattern = nullptr;
  SMDiagnostic Diag;
  if (parseMIRBuffer(MemoryBuffer::getMemBufferCopy(Source, Name),
                     Pattern.Source, Pattern.Context, RawPattern, Diag)) {
    std::string Message;
    raw_string_ostream OS(Message);
    Diag.print(/*ProgName=*/nullptr, OS, /*ShowColors=*/false);
    return createStringError(Message);
  }
  Expected<PatternVariants> Lowered =
      PatternLowering(Pattern.Context).lower(RawPattern);
  if (!Lowered) {
    std::string Message;
    raw_string_ostream OS(Message);
    printLoweringErrors(Lowered.takeError(), Pattern.Source, Pattern.Context,
                        OS);
    return createStringError(Message);
  }
  Pattern.Variants = std::move(*Lowered);
  Pattern.Query = FeatureQuery::compute(*Pattern.Variants, &Pattern.Context);
  return Query;
}

std::vector<ByteRange> WebQuery::getKeyRanges() const {
  std::vector<ByteRange> Ranges;
  for (unsigned Variant = 0; Variant != Pattern->Query.size(); ++Variant)
    for (const PostingKey &Key :
         getPostingKeys(Pattern->Query.getRequirement(Variant)))
      if (std::optional<ByteRange> Block = Index.getKeyBlock(Key))
        Ranges.push_back(*Block);
  return mergeRanges(std::move(Ranges));
}

Expected<std::vector<ByteRange>> WebQuery::findLists(const ByteCache &Cache) {
  std::map<PostingKey, std::optional<WebPosting>> Postings;
  for (unsigned Variant = 0; Variant != Pattern->Query.size(); ++Variant)
    for (const PostingKey &Key :
         getPostingKeys(Pattern->Query.getRequirement(Variant))) {
      if (Postings.count(Key))
        continue;
      Expected<std::optional<WebPosting>> Found = Index.findPosting(Key, Cache);
      if (!Found)
        return Found.takeError();
      Postings[Key] = *Found;
    }
  std::optional<std::vector<SmallVector<PostingKey, 3>>> Keys =
      choosePostingKeys(Pattern->Query, [&](const PostingKey &Key) {
        const std::optional<WebPosting> &Found = Postings[Key];
        return Found ? Found->Record.Count : 0;
      });
  if (!Keys)
    return createStringError(
        "the pattern needs no instruction, so it could match any function "
        "of the corpus");
  Chosen = std::move(*Keys);
  Lists.clear();
  std::vector<ByteRange> Ranges;
  for (const SmallVector<PostingKey, 3> &VariantKeys : Chosen)
    for (const PostingKey &Key : VariantKeys) {
      const WebPosting &Found = *Postings[Key];
      Lists.push_back({Key, Found.List, Found.Record.Count});
      Ranges.push_back(Found.List);
    }
  return mergeRanges(std::move(Ranges));
}

Expected<std::vector<ByteRange>>
WebQuery::findCandidates(const ByteCache &Cache) {
  std::map<PostingKey, std::vector<uint32_t>> Numbers;
  for (const ChosenList &List : Lists) {
    if (Numbers.count(List.Key))
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
  Candidates = combinePostings(Chosen, [&](const PostingKey &Key) {
    return ArrayRef<uint32_t>(Numbers[Key]);
  });
  std::vector<ByteRange> Ranges;
  for (uint32_t Function : Candidates)
    Ranges.push_back(ByteRange{WebFile::Index,
                               uint64_t(Function) * WebIndexEntrySize,
                               2 * WebIndexEntrySize});
  return mergeRanges(std::move(Ranges));
}

Expected<std::pair<ByteRange, ByteRange>>
WebQuery::locate(size_t Position, const ByteCache &Cache) const {
  uint32_t Function = Candidates[Position];
  Expected<StringRef> Entries = Cache.read(
      ByteRange{WebFile::Index, uint64_t(Function) * WebIndexEntrySize,
                2 * WebIndexEntrySize});
  if (!Entries)
    return Entries.takeError();
  const char *Entry = Entries->data();
  uint64_t Features = support::endian::read64le(Entry);
  uint64_t Pack = support::endian::read64le(Entry + 8);
  uint64_t FeaturesEnd = support::endian::read64le(Entry + 16);
  uint64_t PackEnd = support::endian::read64le(Entry + 24);
  if (FeaturesEnd < Features || PackEnd < Pack)
    return createStringError("function index out of order");
  return std::make_pair(
      ByteRange{WebFile::Features, Features, FeaturesEnd - Features},
      ByteRange{WebFile::Packs, Pack, PackEnd - Pack});
}

Expected<std::vector<ByteRange>>
WebQuery::findFeatures(const ByteCache &Cache) {
  std::vector<ByteRange> Ranges;
  for (size_t Position = 0; Position != Candidates.size(); ++Position) {
    Expected<std::pair<ByteRange, ByteRange>> Location =
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
    Expected<std::pair<ByteRange, ByteRange>> Location =
        locate(Position, Cache);
    if (!Location)
      return Location.takeError();
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
    if (!Pattern->Query.mayMatch(*Features))
      continue;
    Matchable.push_back(Candidates[Position]);
    Packs.push_back(Location->second);
  }
  return mergeRanges(Packs);
}

ByteRange WebQuery::getPackRange(uint32_t Function) const {
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

Expected<PrintedFunction> WebQuery::printFunction(const WebIndex &Index,
                                                  StringRef Frame) {
  Expected<std::string> Bytes = Index.getPackDictionary().decompress(Frame);
  if (!Bytes)
    return Bytes.takeError();
  Expected<FunctionPack> Pack = FunctionPack::decode(*Bytes);
  if (!Pack)
    return Pack.takeError();
  LLVMContext Context;
  Expected<std::unique_ptr<UnpackedFunction>> Unpacked =
      UnpackedFunction::read(*Pack, Context);
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

Error WebQuery::match(uint32_t Function, StringRef Frame, raw_ostream &Out,
                      bool PrintInstructions,
                      std::vector<RejectingConstraint> *Rejecting) {
  const WebModule &Module = Index.getModuleOf(Function);
  auto Located = [&](Error E) {
    return createStringError(Module.Path + ": function " +
                             Twine(Function - Module.FirstFunction) + ": " +
                             toString(std::move(E)));
  };
  Expected<std::string> Bytes = Index.getPackDictionary().decompress(Frame);
  if (!Bytes)
    return Located(Bytes.takeError());
  Expected<FunctionPack> Pack = FunctionPack::decode(*Bytes);
  if (!Pack)
    return Located(Pack.takeError());
  LLVMContext Context;
  Expected<std::unique_ptr<UnpackedFunction>> Unpacked =
      UnpackedFunction::read(*Pack, Context);
  if (!Unpacked)
    return Located(Unpacked.takeError());
  const llvm::Function &F = (*Unpacked)->getFunction();

  PatternMatcher Matcher(&Pattern->Context);
  Matcher.setUseOracle(Unpacked->get());
  Target Program(F);
  bool HadStructuralMatch = false;
  SmallVector<UnsatisfiedConstraint, 4> Unsatisfied;
  MatchResults Matches = Matcher.match(
      *Pattern->Variants, Program, Rejecting ? &Unsatisfied : nullptr,
      Rejecting ? &HadStructuralMatch : nullptr, &Pattern->Query);
  if (Matches.empty()) {
    if (HadStructuralMatch)
      for (const UnsatisfiedConstraint &U : Unsatisfied) {
        RejectingConstraint &R = Rejecting->emplace_back();
        R.Function = ("@" + F.getName()).str();
        raw_string_ostream(R.Constraint.Message) << *U.Expression;
        SMLoc Loc = U.Expression->getSourceRange().Begin;
        const SourceMgr &SM = Pattern->Source;
        if (getMainFileLine(SM, Loc))
          std::tie(R.Constraint.Line, R.Constraint.Column) =
              SM.getLineAndColumn(Loc, SM.getMainFileID());
        R.Reason = U.Reason;
      }
    return Error::success();
  }
  ModuleSlotTracker Slots(F.getParent(), /*ShouldInitializeAllMetadata=*/false);
  Slots.incorporateFunction(F);
  for (const Instantiation &Match : Matches) {
    Out << Module.Path << "\t@" << F.getName() << '\t';
    Match.print(Out, &Slots);
    if (PrintInstructions) {
      Out << '\t';
      Match.printInstructions(Out, [&](const metaphir::Instruction &I) {
        return getMainFileLine(Pattern->Source, I.getSourceRange().Begin);
      });
    }
    Out << '\n';
  }
  return Error::success();
}

} // namespace metaphir
} // namespace llvm
