//===- ConstraintEmitter.cpp - the constraint operators
//--------------------===//
//
// -gen-constraint-operators: metaphir/IR/Constraint.inc, the operators of
// constraint expressions (IDs, spellings, schemas, argument sorts) and which
// sorts coerce to which.
// -gen-constraint-dispatch: metaphir/Exec/ConstraintDispatch.inc, which
// calls the C++ operator of an operator ID.
//
//===----------------------------------------------------------------------===//

#include "Emit.h"
#include "Records.h"
#include "llvm/ADT/StringMap.h"
#include "llvm/ADT/StringSet.h"

using namespace llvm;
using namespace metaphir_tblgen;

namespace {

/// The IDs of the sorts, checked as operators and coercions name them.
StringSet<> getSortIDs(const RecordKeeper &Records) {
  StringSet<> IDs;
  for (const Record *S : getDefinitionsInOrder(Records, "Sort"))
    IDs.insert(S->getValueAsString("ID"));
  return IDs;
}

void checkSort(const StringSet<> &IDs, const Record *At, StringRef ID) {
  if (!IDs.count(ID))
    PrintFatalError(At, "no sort has the ID '" + ID + "'");
}

void emitConstraintOperators(const RecordKeeper &Records, raw_ostream &OS) {
  auto Operators = getDefinitionsInOrder(Records, "ConstraintOperator");
  auto Aliases = getDefinitionsInOrder(Records, "OperatorAlias");
  auto Coercions = getDefinitionsInOrder(Records, "Coercion");
  StringSet<> Sorts = getSortIDs(Records);

  // The spellings of each kind of operator are unique.
  StringSet<> Seen;
  size_t MaxArguments = 1;
  auto CheckSpelling = [&](const Record *At, StringRef Name, StringRef Kind) {
    if (Kind != "Unary" && Kind != "Binary" && Kind != "Call")
      PrintFatalError(At, "unknown operator kind '" + Kind + "'");
    if (!Seen.insert((Kind + " " + Name).str()).second)
      PrintFatalError(At, "the " + Kind.lower() + " operator '" + Name +
                              "' is defined twice");
  };
  StringSet<> IDs;
  for (const Record *Op : Operators) {
    if (!IDs.insert(Op->getValueAsString("ID")).second)
      PrintFatalError(Op, "the operator ID is defined twice");
    CheckSpelling(Op, Op->getValueAsString("Name"),
                  Op->getValueAsString("Kind"));
    checkSort(Sorts, Op, Op->getValueAsString("Result"));
    checkSort(Sorts, Op, Op->getValueAsString("RestSort"));
    for (StringRef S : Op->getValueAsListOfStrings("ArgumentSorts"))
      checkSort(Sorts, Op, S);
    MaxArguments = std::max(
        MaxArguments, Op->getValueAsListOfStrings("ArgumentSorts").size());
    if (Op->getValueAsInt("MaxArity") < Op->getValueAsInt("MinArity"))
      PrintFatalError(Op,
                      "the operator takes fewer arguments than its minimum");
  }
  for (const Record *A : Aliases)
    CheckSpelling(A, A->getValueAsString("Name"), A->getValueAsString("Kind"));
  for (const Record *C : Coercions) {
    checkSort(Sorts, C, C->getValueAsString("Src"));
    checkSort(Sorts, C, C->getValueAsString("Dst"));
  }

  beginHeader(OS, Records, "The constraint operators",
              "METAPHIR_IR_CONSTRAINT_INC",
              {"metaphir/IR/Sort.inc", "llvm/ADT/StringRef.h"}, {"constraint"});
  OS << "// The data of the operators; metaphir/IR/Constraint.h reads it. The "
        "tables of\n// operators are indexed by OperatorID - 1.\n\n"
        "/// How an operator is written.\n"
        "enum OperatorKind { Unary, Binary, Call };\n\n"
        "enum OperatorID {\n  UnknownOperator,\n";
  for (const Record *Op : Operators)
    OS << "  O_" << Op->getValueAsString("ID") << ",\n";
  OS << "};\n\ninline constexpr unsigned NumOperators = " << Operators.size()
     << ";\n\nstruct OperatorSchema {\n  Sort Result;\n  unsigned MinArity;\n"
        "  unsigned MaxArity;\n};\n\n";
  using OpRef = const Record *;
  emitArray<decltype(Operators), OpRef>(
      OS, "OperatorSchema Schemas[]", Operators,
      [](raw_ostream &OS, const OpRef &Op) {
        OS << "{Sort::" << Op->getValueAsString("Result") << ", "
           << Op->getValueAsInt("MinArity") << ", "
           << Op->getValueAsInt("MaxArity") << "}";
      });
  emitArray<decltype(Operators), OpRef>(
      OS, "StringRef OperatorNames[]", Operators,
      [](raw_ostream &OS, const OpRef &Op) {
        OS << '"' << Op->getValueAsString("Name") << '"';
      });

  OS << "/// The sorts of an operator's first arguments; the rest are Rest.\n"
        "inline constexpr unsigned MaxExplicitArguments = "
     << MaxArguments << ";\n\nstruct ArgumentSorts {\n"
     << "  Sort Explicit[MaxExplicitArguments];\n  unsigned NumExplicit;\n"
        "  Sort Rest;\n};\n\n";
  emitArray<decltype(Operators), OpRef>(
      OS, "ArgumentSorts Signatures[]", Operators,
      [&](raw_ostream &OS, const OpRef &Op) {
        auto Args = Op->getValueAsListOfStrings("ArgumentSorts");
        OS << "{{";
        for (size_t I = 0; I != MaxArguments; ++I)
          OS << (I ? ", " : "")
             << "Sort::" << (I < Args.size() ? Args[I] : StringRef("Unknown"));
        OS << "}, " << Args.size()
           << ", Sort::" << Op->getValueAsString("RestSort") << "}";
      });

  // Every spelling: an operator's own, then the aliases'.
  struct Spelling {
    StringRef Name, Kind, ID;
  };
  SmallVector<Spelling, 128> Spellings;
  for (const Record *Op : Operators)
    Spellings.push_back({Op->getValueAsString("Name"),
                         Op->getValueAsString("Kind"),
                         Op->getValueAsString("ID")});
  for (const Record *A : Aliases)
    Spellings.push_back({A->getValueAsString("Name"),
                         A->getValueAsString("Kind"),
                         A->getValueAsDef("Operator")->getValueAsString("ID")});
  OS << "/// A name an operator is written with, and how.\n"
        "struct OperatorSpelling {\n  StringRef Name;\n  OperatorKind Kind;\n"
        "  OperatorID ID;\n};\n\n";
  emitArray<decltype(Spellings), Spelling>(
      OS, "OperatorSpelling Spellings[]", Spellings,
      [](raw_ostream &OS, const Spelling &S) {
        OS << "{\"" << S.Name << "\", " << S.Kind << ", O_" << S.ID << "}";
      });

  OS << "/// A coercion between the representations of two sorts.\n"
        "struct SortPair {\n  Sort From;\n  Sort To;\n};\n\n";
  emitArray<decltype(Coercions), OpRef>(
      OS, "SortPair Coercions[]", Coercions,
      [](raw_ostream &OS, const OpRef &C) {
        OS << "{Sort::" << C->getValueAsString("Src")
           << ", Sort::" << C->getValueAsString("Dst") << "}";
      });

  // A phrase for each sort, from the sort that represents it at runtime.
  auto SortRecords = getDefinitionsInOrder(Records, "Sort");
  StringMap<const Record *> ByID;
  for (const Record *S : SortRecords)
    ByID[S->getValueAsString("ID")] = S;
  for (const Record *S : SortRecords)
    if (ByID[S->getValueAsString("Representation")]
            ->getValueAsString("Description")
            .empty())
      PrintFatalError(ByID[S->getValueAsString("Representation")],
                      "a sort that represents another needs a description");
  OS << "/// A phrase naming each sort for diagnostics, e.g. \"an "
        "integer\".\n";
  emitArray<decltype(SortRecords), OpRef>(
      OS, "StringRef SortDescriptions[]", SortRecords,
      [&](raw_ostream &OS, const OpRef &S) {
        OS << '"'
           << ByID[S->getValueAsString("Representation")]->getValueAsString(
                  "Description")
           << '"';
      });
  endHeader(OS, "METAPHIR_IR_CONSTRAINT_INC", {"constraint"});
}

void emitConstraintDispatch(const RecordKeeper &Records, raw_ostream &OS) {
  auto Operators = getDefinitionsInOrder(Records, "ConstraintOperator");
  beginHeader(OS, Records, "Calling the operator of an operator ID",
              "METAPHIR_EXEC_CONSTRAINT_DISPATCH_INC",
              {"metaphir/IR/Constraint.h",
               "metaphir/Matching/Operators/Arithmetic.h",
               "metaphir/Matching/Operators/CmpPredicates.h",
               "metaphir/Matching/Operators/ValuePredicates.h",
               "metaphir/Matching/Operators/ValueTracking.h"});
  OS << "/// Calls Builtin(Op<ID>()) for the operator ID, or, for a "
        "value-tracking\n/// one, ValueTrack(Op<ID>(), BaseArity); Default() "
        "if there is none. Both take\n/// the operator generically, so each "
        "instantiates for every operator.\n"
        "template <class Result, class BuiltinFn, class ValueTrackFn, "
        "class DefaultFn>\n"
        "Result visitOperator(constraint::OperatorID ID, BuiltinFn Builtin,\n"
        "                     ValueTrackFn ValueTrack, DefaultFn Default) {\n"
        "  switch (ID) {\n";
  for (const Record *Op : Operators) {
    StringRef ID = Op->getValueAsString("ID");
    OS << "  case constraint::O_" << ID << ":\n    return ";
    if (Op->getValueAsBit("ValueTracking"))
      OS << "ValueTrack(Op" << ID << "(), " << Op->getValueAsInt("MinArity")
         << ");\n";
    else
      OS << "Builtin(Op" << ID << "());\n";
  }
  OS << "  case constraint::UnknownOperator:\n    break;\n  }\n"
        "  return Default();\n}\n\n";
  endHeader(OS, "METAPHIR_EXEC_CONSTRAINT_DISPATCH_INC");
}

TableGen::Emitter::Opt X("gen-constraint-operators", emitConstraintOperators,
                         "Generate the constraint operators");
TableGen::Emitter::Opt Y("gen-constraint-dispatch", emitConstraintDispatch,
                         "Generate the dispatch to the operators' C++");

} // namespace
