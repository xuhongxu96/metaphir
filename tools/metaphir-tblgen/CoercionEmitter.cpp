//===- CoercionEmitter.cpp - the constraint value coercions
//----------------===//
//
// -gen-coercions: metaphir/Matching/ConstraintCoercions.inc, which
// conversion turns one kind of constraint value into another.
//
//===----------------------------------------------------------------------===//

#include "Emit.h"
#include "Records.h"
#include "llvm/ADT/StringSet.h"
#include "llvm/TableGen/Error.h"

using namespace llvm;
using namespace metaphir_tblgen;

namespace {

void emitCoercions(const RecordKeeper &Records, raw_ostream &OS) {
  auto Coercions = getDefinitionsInOrder(Records, "Coercion");
  StringSet<> Seen, Ops;
  for (const Record *C : Coercions) {
    if (!Seen.insert((C->getValueAsString("Src") + "->" +
                      C->getValueAsString("Dst"))
                         .str())
             .second)
      PrintFatalError(C, "the coercion is defined twice");
    if (!Ops.insert(C->getValueAsString("Op")).second)
      PrintFatalError(C, "the coercion operator is defined twice");
  }

  beginHeader(OS, Records, "The constraint value coercions",
              "METAPHIR_MATCHING_CONSTRAINT_COERCIONS_INC",
              {"metaphir/Matching/ConstraintValue.h", "llvm/Support/Error.h",
               "mlir/IR/Value.h"},
              {"detail"});
  OS << "// The conversions between the kinds of constraint value, each "
        "hand-written in\n// ConstraintCoercion.cpp, and which kinds each "
        "converts; ConstraintCoercion.h reads\n// them.\n\n"
        "using CoercionFn = Expected<ConstraintValue> (*)(const "
        "ConstraintValue &,\n                                                "
        "mlir::Value);\n\n";
  for (const Record *C : Coercions)
    OS << "Expected<ConstraintValue> coerce" << C->getValueAsString("Op")
       << "(const ConstraintValue &V, mlir::Value Expression);\n";
  OS << "\n/// A conversion of a Src kind into a Dst kind.\n"
        "struct Coercion {\n  ConstraintValue::ValueKind Src;\n"
        "  ConstraintValue::ValueKind Dst;\n  CoercionFn Convert;\n};\n\n";
  emitArray<decltype(Coercions), const Record *>(
      OS, "Coercion Coercions[]", Coercions,
      [](raw_ostream &OS, const Record *const &C) {
        OS << "{ConstraintValue::" << C->getValueAsString("Src")
           << ", ConstraintValue::" << C->getValueAsString("Dst") << ", coerce"
           << C->getValueAsString("Op") << "}";
      });
  endHeader(OS, "METAPHIR_MATCHING_CONSTRAINT_COERCIONS_INC", {"detail"});
}

TableGen::Emitter::Opt X("gen-coercions", emitCoercions,
                         "Generate the constraint value coercions");

} // namespace
