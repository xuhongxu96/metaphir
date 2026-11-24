//===- SortEmitter.cpp - the sorts
//-----------------------------------------===//
//
// -gen-sorts: metaphir/IR/Sort.inc, the sorts, their names and
// representations, and the subsort order.
//
//===----------------------------------------------------------------------===//

#include "Emit.h"
#include "Records.h"
#include "llvm/ADT/StringMap.h"
#include "llvm/Support/Format.h"
#include "llvm/TableGen/Error.h"
#include <array>

using namespace llvm;
using namespace metaphir_tblgen;

namespace {

void emitSorts(const RecordKeeper &Records, raw_ostream &OS) {
  auto Sorts = getDefinitionsInOrder(Records, "Sort");
  auto Edges = getDefinitionsInOrder(Records, "Subsort");
  const unsigned N = Sorts.size();
  if (N > 64)
    PrintFatalError("the subsort order is a matrix of 64-bit rows");

  StringMap<unsigned> Index;
  for (auto [I, S] : enumerate(Sorts))
    if (!Index.try_emplace(S->getValueAsString("ID"), I).second)
      PrintFatalError(S, "the sort is defined twice");
  auto Find = [&](const Record *At, StringRef ID) {
    auto It = Index.find(ID);
    if (It == Index.end())
      PrintFatalError(At, "no sort has the ID '" + ID + "'");
    return It->second;
  };
  if (!Index.count("Unknown"))
    PrintFatalError("the sorts need an Unknown, the top of the order");

  // The reflexive-transitive closure of the edges, with Unknown above every
  // sort.
  std::array<std::array<bool, 64>, 64> M{};
  for (unsigned I = 0; I != N; ++I) {
    M[I][I] = true;
    M[I][Index["Unknown"]] = true;
  }
  for (const Record *E : Edges)
    M[Find(E, E->getValueAsDef("Sub")->getValueAsString("ID"))]
     [Find(E, E->getValueAsDef("Super")->getValueAsString("ID"))] = true;
  for (unsigned K = 0; K != N; ++K)
    for (unsigned I = 0; I != N; ++I)
      if (M[I][K])
        for (unsigned J = 0; J != N; ++J)
          if (M[K][J])
            M[I][J] = true;

  beginHeader(OS, Records, "The sorts", "METAPHIR_IR_SORT_INC",
              {"llvm/ADT/StringRef.h", "cstdint"});
  OS << "// The data of the sorts; metaphir/IR/Sort.h reads it.\n\n"
        "/// The sort of a meta variable or a constraint expression.\n"
        "enum class Sort {\n";
  for (const Record *S : Sorts)
    OS << "  " << S->getValueAsString("ID") << ",\n";
  OS << "};\n\ninline constexpr unsigned NumSorts = " << N << ";\n\n"
     << "/// What a sort is called, and the sort that represents it at "
        "runtime.\nstruct SortInfo {\n  StringRef Name;\n  StringRef Keyword;\n"
        "  Sort Representation;\n};\n\n";
  using SortRef = const Record *;
  emitArray<decltype(Sorts), SortRef>(
      OS, "SortInfo SortInfos[]", Sorts,
      [&](raw_ostream &OS, const SortRef &S) {
        OS << "{\"" << S->getValueAsString("Name") << "\", \""
           << S->getValueAsString("ID") << "\", Sort::"
           << Sorts[Find(S, S->getValueAsString("Representation"))]
                  ->getValueAsString("ID")
           << "}";
      });
  OS << "/// Row Sub has bit Super set when Sub lies below Super; Unknown is "
        "the top.\n";
  SmallVector<uint64_t, 64> Rows;
  for (unsigned I = 0; I != N; ++I) {
    uint64_t Row = 0;
    for (unsigned J = 0; J != N; ++J)
      if (M[I][J])
        Row |= uint64_t(1) << J;
    Rows.push_back(Row);
  }
  emitArray<decltype(Rows), uint64_t>(OS, "uint64_t SubsortRows[]", Rows,
                                      [](raw_ostream &OS, const uint64_t &Row) {
                                        OS << format_hex(Row, 0) << "ull";
                                      });
  endHeader(OS, "METAPHIR_IR_SORT_INC");
}

TableGen::Emitter::Opt X("gen-sorts", emitSorts, "Generate the sorts");

} // namespace
