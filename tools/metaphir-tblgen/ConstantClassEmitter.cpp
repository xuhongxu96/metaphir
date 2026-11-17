//===- ConstantClassEmitter.cpp - constant classes and predicate operators
//-===//
//
// -gen-constant-classes: metaphir/Matching/Operators/ConstantClassOps.inc,
// the C++ operator of each constant class.
// -gen-cmp-predicate-operators:
// metaphir/Matching/Operators/CmpPredicateOps.inc, the C++ operator of each
// operator on comparison predicates.
//
//===----------------------------------------------------------------------===//

#include "Emit.h"
#include "Records.h"

using namespace llvm;
using namespace metaphir_tblgen;

namespace {

void emitConstantClasses(const RecordKeeper &Records, raw_ostream &OS) {
  auto Classes = getDefinitionsInOrder(Records, "ConstantClass");
  beginHeader(OS, Records, "The operators of the constant classes",
              "METAPHIR_MATCHING_OPERATORS_CONSTANT_CLASS_OPS_INC",
              {"metaphir/Matching/Operators/AbstractCall.h",
               "metaphir/Matching/Operators/Facts.h",
               "metaphir/Matching/Operators/OperatorCall.h",
               "metaphir/Matching/Operators/ValuePredicateSupport.h",
               "llvm/IR/PatternMatch.h"});
  OS << "// A constant class on an LLVM value is its PatternMatch matcher; on "
        "a "
        "plain\n// integer V it is its integer test, if it has one. A recorded "
        "class is a fact\n// the index records: holds() decides it on the IR "
        "for both the matcher\n// (concrete) and the index (record); "
        "abstract() is false where the index\n// lacks the fact.\n\n";
  for (const Record *C : Classes) {
    StringRef ID = C->getValueAsString("ID");
    bool Recorded = C->getValueAsBit("Recorded");
    StringRef Test = C->getValueAsString("IntegerTest");
    OS << "struct Op" << ID << " {\n"
       << "  static constexpr bool ShortCircuits = false;\n";
    if (Recorded)
      OS << "  static constexpr fact::Predicate Fact = fact::" << ID << ";\n";
    OS << "  static bool holds(const llvm::Value &V) {\n"
       << "    return PatternMatch::match(&V, PatternMatch::"
       << C->getValueAsString("Matcher") << "());\n  }\n"
       << "  static Expected<ConstraintValue> concrete(const ConcreteCall "
          "&Call) {\n    return integerPredicate<Op"
       << ID
       << ">(\n        Call, [](const APSInt &V) -> std::optional<bool> {\n"
       << "          (void)V;\n          return "
       << (Test.empty() ? "std::nullopt" : Test) << ";\n        });\n  }\n";
    if (Recorded)
      OS << "  static void record(const RecordCall &Call) {\n"
            "    recordIfHolds<Op"
         << ID
         << ">(Call);\n  }\n"
            "  static AbstractValue abstract(const AbstractCall &Call) {\n"
            "    return lacksFact(Call, 0, Fact);\n  }\n";
    OS << "};\n\n";
  }
  OS << "/// Records the facts of the recorded constant classes.\n"
        "inline void recordConstantClasses(const RecordCall &Call) {\n";
  for (const Record *C : Classes)
    if (C->getValueAsBit("Recorded"))
      OS << "  Op" << C->getValueAsString("ID") << "::record(Call);\n";
  OS << "}\n\n";
  endHeader(OS, "METAPHIR_MATCHING_OPERATORS_CONSTANT_CLASS_OPS_INC");
}

void emitCmpPredicateOperators(const RecordKeeper &Records, raw_ostream &OS) {
  auto Tests = getDefinitionsInOrder(Records, "CmpPredicateTest");
  auto Maps = getDefinitionsInOrder(Records, "CmpPredicateMap");
  beginHeader(OS, Records, "The operators on comparison predicates",
              "METAPHIR_MATCHING_OPERATORS_CMP_PREDICATE_OPS_INC",
              {"metaphir/Matching/Operators/CmpPredicateSupport.h",
               "metaphir/Matching/Operators/OperatorCall.h"});
  OS << "// Pure functions of their operand, the same on the IR and on the "
        "index.\n\n";
  // Tests and maps, in the order of the operators.
  SmallVector<const Record *, 16> All(Tests.begin(), Tests.end());
  All.append(Maps.begin(), Maps.end());
  sort(All, [](const Record *L, const Record *R) {
    return L->getID() < R->getID();
  });
  for (const Record *R : All) {
    bool IsTest = R->isSubClassOf("CmpPredicateTest");
    OS << "struct Op" << R->getValueAsString("ID") << " {\n"
       << "  static constexpr bool ShortCircuits = false;\n"
       << "  static Expected<ConstraintValue> concrete(const ConcreteCall "
          "&Call) {\n    return "
       << (IsTest ? "testPredicate" : "mapPredicate")
       << "(Call, [](CmpInst::Predicate P) { return "
       << R->getValueAsString("Expression") << "; });\n  }\n};\n\n";
  }
  endHeader(OS, "METAPHIR_MATCHING_OPERATORS_CMP_PREDICATE_OPS_INC");
}

TableGen::Emitter::Opt X("gen-constant-classes", emitConstantClasses,
                         "Generate the operators of the constant classes");
TableGen::Emitter::Opt Y("gen-cmp-predicate-operators",
                         emitCmpPredicateOperators,
                         "Generate the operators on comparison predicates");

} // namespace
