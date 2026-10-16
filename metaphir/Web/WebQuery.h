#ifndef METAPHIR_WEB_WEBQUERY_H
#define METAPHIR_WEB_WEBQUERY_H

#include "metaphir/Index/Postings.h"
#include "metaphir/Web/WebIndex.h"
#include "llvm/ADT/ArrayRef.h"
#include "llvm/ADT/StringRef.h"
#include "llvm/Support/Error.h"
#include <cstdint>
#include <memory>
#include <optional>
#include <string>
#include <vector>

namespace llvm {
class raw_ostream;
namespace metaphir {

class FeatureQuery;

/// A function's IR as LLVM prints it, and the line of each of its
/// instructions (counted from 1), in order.
struct PrintedFunction {
  std::string IR;
  std::vector<unsigned> Lines;
};

/// Something said about a pattern: the message, and where in the pattern's
/// source it is about (line and column from 1), or 0 and 0 when it is not in
/// the pattern's source.
struct PatternNote {
  std::string Message;
  unsigned Line = 0;
  unsigned Column = 0;
};

/// A constraint that rejected all the structural matches of a function.
struct RejectingConstraint {
  /// The function, as "@name".
  std::string Function;
  /// The constraint, printed, and where it is.
  PatternNote Constraint;
  /// Why it could not be evaluated; empty if it was false.
  std::string Reason;
  /// The first structural match it rejected, printed as a match is: its
  /// bindings, and the instructions it matched.
  std::string Bindings;
  std::string Instructions;
};

/// A pattern matched against a published corpus, in stages that each tell
/// which bytes the next one reads: the caller reads them into a ByteCache,
/// from files or over HTTP, and goes on.
///
///   1. getKeyRanges: the blocks of the pattern's posting keys;
///   2. findLists: the lists of the keys that narrow the candidates most;
///   3. findCandidates: the index entries of the functions on all of them;
///   4. findFeatures: the features of those functions;
///   5. filterCandidates: the packs of the functions whose features may
///      match (getMatchable);
///   6. match: each such function against the pattern.
///
/// Matching one function needs no other stage, so it can be done by another
/// query of the same pattern, such as one per thread.
class WebQuery {
public:
  /// Compiles the pattern Source, named Name in diagnostics, to match
  /// against Index.
  static Expected<std::unique_ptr<WebQuery>>
  compile(const WebIndex &Index, StringRef Source, StringRef Name);

  ~WebQuery();

  std::vector<ByteRange> getKeyRanges() const;
  Expected<std::vector<ByteRange>> findLists(const ByteCache &Cache);
  Expected<std::vector<ByteRange>> findCandidates(const ByteCache &Cache);
  Expected<std::vector<ByteRange>> findFeatures(const ByteCache &Cache);
  Expected<std::vector<ByteRange>> filterCandidates(const ByteCache &Cache);

  /// The warnings the pattern was compiled with.
  ArrayRef<PatternNote> getWarnings() const;

  /// The functions on the lists, once found.
  ArrayRef<uint32_t> getCandidates() const { return Candidates; }
  /// The candidates whose features may match, once filtered.
  ArrayRef<uint32_t> getMatchable() const { return Matchable; }
  /// Where the pack of a matchable function is.
  ByteRange getPackRange(uint32_t Function) const;

  /// The function whose pack is Frame, printed.
  static Expected<PrintedFunction> printFunction(const WebIndex &Index,
                                                 StringRef Frame);

  /// Matches the function numbered Function, whose pack is Frame, and
  /// prints its matches to Out, one per line: the module, @function and
  /// bindings, and with PrintInstructions the instructions matched (see
  /// Instantiation::printInstructions), separated by tabs. With Rejecting,
  /// a function with structural matches but none satisfying the constraints
  /// adds the constraints that rejected them, as metaphir-match prints.
  Error match(uint32_t Function, StringRef Frame, raw_ostream &Out,
              bool PrintInstructions = false,
              std::vector<RejectingConstraint> *Rejecting = nullptr);

private:
  struct Compiled;

  explicit WebQuery(const WebIndex &Index);

  /// Where the features and pack of the candidate at Position are.
  Expected<std::pair<ByteRange, ByteRange>>
  locate(size_t Position, const ByteCache &Cache) const;

  const WebIndex &Index;
  std::unique_ptr<Compiled> Pattern;
  std::vector<SmallVector<PostingKey, 3>> Chosen;
  /// The lists of the chosen keys: where they are and their lengths.
  struct ChosenList {
    PostingKey Key;
    ByteRange Range;
    uint32_t Count;
  };
  std::vector<ChosenList> Lists;
  std::vector<uint32_t> Candidates;
  std::vector<uint32_t> Matchable;
  /// The packs of the matchable functions, in the same order.
  std::vector<ByteRange> Packs;
};

} // namespace metaphir
} // namespace llvm

#endif
