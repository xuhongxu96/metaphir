// JavaScript bindings for matching a published corpus (see
// metaphir/Web/WebQuery.h). A Session holds the corpus's header and the bytes
// read so far; the page reads what each stage asks for and hands it over with
// add(). Every result is a plain object: {error} on failure.
#include "metaphir/Web/WebIndex.h"
#include "metaphir/Web/WebQuery.h"
#include "llvm/Support/raw_ostream.h"
#include <emscripten/bind.h>
#include <emscripten/val.h>

using namespace llvm;
using namespace llvm::metaphir;
using emscripten::val;

namespace {

val errorValue(Error E) {
  val Result = val::object();
  Result.set("error", toString(std::move(E)));
  return Result;
}

val rangeValue(const ByteRange &Range) {
  val Result = val::object();
  Result.set("file", std::string(getWebFileName(Range.File)));
  Result.set("offset", double(Range.Offset));
  Result.set("size", double(Range.Size));
  return Result;
}

val rangesValue(const std::vector<ByteRange> &Ranges) {
  val Array = val::array();
  for (const ByteRange &Range : Ranges)
    Array.call<void>("push", rangeValue(Range));
  val Result = val::object();
  Result.set("ranges", Array);
  return Result;
}

val noteValue(const PatternNote &Note) {
  val Result = val::object();
  Result.set("message", Note.Message);
  Result.set("line", Note.Line);
  Result.set("column", Note.Column);
  return Result;
}

class Session {
public:
  explicit Session(const std::string &Header) {
    Expected<std::unique_ptr<WebIndex>> Read = WebIndex::read(Header);
    if (!Read)
      Problem = toString(Read.takeError());
    else
      Index = std::move(*Read);
  }

  /// Why the header could not be read, if it could not.
  std::string error() const { return Problem; }
  unsigned numFunctions() const { return Index ? Index->getNumFunctions() : 0; }
  size_t numModules() const {
    return Index ? Index->getHeader().Modules.size() : 0;
  }

  /// Holds the bytes of the published file named File from Offset.
  void add(const std::string &File, double Offset, const std::string &Bytes) {
    for (unsigned F = 0; F != NumWebFiles; ++F)
      if (getWebFileName(WebFile(F)) == File)
        Cache.add(WebFile(F), uint64_t(Offset), Bytes);
  }

  /// Compiles Pattern, named Name in diagnostics, for the stages and match.
  val compile(const std::string &Pattern, const std::string &Name) {
    Query.reset();
    // Each query reads its bytes anew, from the page's cache: the session
    // does not keep every query's.
    Cache.clear();
    Expected<std::unique_ptr<WebQuery>> Compiled =
        WebQuery::compile(*Index, Pattern, Name);
    if (!Compiled)
      return errorValue(Compiled.takeError());
    Query = std::move(*Compiled);
    val Result = rangesValue(Query->getKeyRanges());
    val Warnings = val::array();
    for (const PatternNote &Warning : Query->getWarnings())
      Warnings.call<void>("push", noteValue(Warning));
    Result.set("warnings", Warnings);
    return Result;
  }

  val findLists() { return stage(&WebQuery::findLists); }
  val findCandidates() { return stage(&WebQuery::findCandidates); }
  val findFeatures() { return stage(&WebQuery::findFeatures); }
  val filterCandidates() { return stage(&WebQuery::filterCandidates); }

  unsigned numCandidates() const { return Query->getCandidates().size(); }

  /// The functions whose features may match, each with where its pack is.
  val matchable() const {
    val Array = val::array();
    for (uint32_t Function : Query->getMatchable()) {
      val Entry = rangeValue(Query->getPackRange(Function));
      Entry.set("function", Function);
      Array.call<void>("push", Entry);
    }
    return Array;
  }

  /// The matches of Function, whose pack is Frame, one per line, with the
  /// instructions each matched; and if it has none, the constraints that
  /// rejected its structural matches.
  val match(uint32_t Function, const std::string &Frame) {
    std::string Lines;
    raw_string_ostream OS(Lines);
    std::vector<RejectingConstraint> Rejecting;
    if (Error E = Query->match(Function, Frame, OS, /*PrintInstructions=*/true,
                               &Rejecting))
      return errorValue(std::move(E));
    val Result = val::object();
    Result.set("lines", Lines);
    val Rejected = val::array();
    for (const RejectingConstraint &R : Rejecting) {
      val Entry = noteValue(R.Constraint);
      Entry.set("reason", R.Reason);
      Rejected.call<void>("push", Entry);
    }
    Result.set("rejected", Rejected);
    return Result;
  }

  /// The module of Function.
  std::string moduleOf(uint32_t Function) const {
    return Index->getModuleOf(Function).Path;
  }

  /// The IR of the function whose pack is Frame, and the line of each of
  /// its instructions.
  val printFunction(const std::string &Frame) const {
    Expected<PrintedFunction> Printed = WebQuery::printFunction(*Index, Frame);
    if (!Printed)
      return errorValue(Printed.takeError());
    val Lines = val::array();
    for (unsigned Line : Printed->Lines)
      Lines.call<void>("push", Line);
    val Result = val::object();
    Result.set("ir", Printed->IR);
    Result.set("lines", Lines);
    return Result;
  }

private:
  using Stage =
      Expected<std::vector<ByteRange>> (WebQuery::*)(const ByteCache &);

  val stage(Stage Next) {
    Expected<std::vector<ByteRange>> Ranges = ((*Query).*Next)(Cache);
    if (!Ranges)
      return errorValue(Ranges.takeError());
    return rangesValue(*Ranges);
  }

  std::string Problem;
  std::unique_ptr<WebIndex> Index;
  std::unique_ptr<WebQuery> Query;
  ByteCache Cache;
};

} // namespace

EMSCRIPTEN_BINDINGS(metaphir) {
  emscripten::class_<Session>("Session")
      .constructor<const std::string &>()
      .function("error", &Session::error)
      .function("numFunctions", &Session::numFunctions)
      .function("numModules", &Session::numModules)
      .function("add", &Session::add)
      .function("compile", &Session::compile)
      .function("findLists", &Session::findLists)
      .function("findCandidates", &Session::findCandidates)
      .function("findFeatures", &Session::findFeatures)
      .function("filterCandidates", &Session::filterCandidates)
      .function("numCandidates", &Session::numCandidates)
      .function("matchable", &Session::matchable)
      .function("match", &Session::match)
      .function("moduleOf", &Session::moduleOf)
      .function("printFunction", &Session::printFunction);
}
