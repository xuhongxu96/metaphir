//===- PrimitiveTypeEmitter.cpp - the primitive types
//----------------------===//
//
// -gen-primitive-types: metaphir/IR/Types.inc, the data of the primitive
// types; metaphir/IR/Type.h reads it.
// -gen-primitive-type-matcher: metaphir/Exec/PrimitiveTypeMatch.inc, the
// llvm::Type test of each; metaphir/Exec/PrimitiveTypeMatch.h reads it.
//
//===----------------------------------------------------------------------===//

#include "Emit.h"
#include "Records.h"

using namespace llvm;
using namespace metaphir_tblgen;

namespace {

void emitPrimitiveTypes(const RecordKeeper &Records, raw_ostream &OS) {
  auto Types = getDefinitionsInOrder(Records, "PrimitiveType");
  beginHeader(OS, Records, "The primitive types", "METAPHIR_IR_TYPES_INC",
              {"llvm/ADT/StringRef.h"}, {"primitive_type"});
  OS << "enum TypeID {\n";
  for (const Record *T : Types)
    OS << "  " << T->getName() << ",  ///< " << T->getValueAsString("Summary")
       << "\n";
  OS << "};\n\n/// How a pattern spells each type, in the order of TypeID.\n";
  emitArray<decltype(Types), const Record *>(
      OS, "StringRef Spellings[]", Types,
      [](raw_ostream &OS, const Record *const &T) {
        OS << '"' << T->getValueAsString("Spelling") << '"';
      });
  endHeader(OS, "METAPHIR_IR_TYPES_INC", {"primitive_type"});
}

void emitPrimitiveTypeMatcher(const RecordKeeper &Records, raw_ostream &OS) {
  auto Types = getDefinitionsInOrder(Records, "PrimitiveType");
  beginHeader(OS, Records, "Matching the primitive types",
              "METAPHIR_EXEC_PRIMITIVE_TYPE_MATCH_INC",
              {"metaphir/IR/Types.inc", "llvm/IR/Type.h"}, {"primitive_type"});
  OS << "/// The llvm::Type member that tests for each type, in the order of "
        "TypeID.\n";
  emitArray<decltype(Types), const Record *>(
      OS, "bool (llvm::Type::*TypeChecks[])() const", Types,
      [](raw_ostream &OS, const Record *const &T) {
        OS << "&llvm::Type::" << T->getValueAsString("TypeCheck");
      });
  endHeader(OS, "METAPHIR_EXEC_PRIMITIVE_TYPE_MATCH_INC", {"primitive_type"});
}

TableGen::Emitter::Opt X("gen-primitive-types", emitPrimitiveTypes,
                         "Generate the primitive types");
TableGen::Emitter::Opt Y("gen-primitive-type-matcher", emitPrimitiveTypeMatcher,
                         "Generate the matcher of primitive types");

} // namespace
