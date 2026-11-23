//===- WebKeywordEmitter.cpp - the highlighter's keywords
//------------------===//
//
// -gen-web-keywords: web/src/generated/keywords.json, the instruction,
// keyword and constraint operator names the website lists.
//
//===----------------------------------------------------------------------===//

#include "Records.h"
#include "llvm/ADT/STLExtras.h"
#include "llvm/ADT/SetVector.h"
#include "llvm/Support/raw_ostream.h"
#include "llvm/TableGen/TableGenBackend.h"

using namespace llvm;
using namespace metaphir_tblgen;

namespace {

void emitList(raw_ostream &OS, StringRef Name, ArrayRef<StringRef> Items,
              bool Last) {
  OS << "  \"" << Name << "\": [\n";
  for (auto [Index, Item] : enumerate(Items))
    OS << "    \"" << Item << "\"" << (Index + 1 == Items.size() ? "" : ",")
       << "\n";
  OS << "  ]" << (Last ? "" : ",") << "\n";
}

void emitWebKeywords(const RecordKeeper &Records, raw_ostream &OS) {
  SmallVector<StringRef, 64> Instructions, Keywords;
  for (const Record *R : getDefinitionsInOrder(Records, "InstructionMatcher"))
    Instructions.push_back(R->getName());
  for (const Record *R : getDefinitionsInOrder(Records, "Keyword"))
    Keywords.push_back(R->getValueAsString("Spelling"));
  for (const Record *R : getDefinitionsInOrder(Records, "KeywordConstant"))
    Keywords.push_back(R->getValueAsString("Spelling"));
  // Every spelling of a built-in constraint operator, once.
  SetVector<StringRef> Operators;
  for (const Record *R : getDefinitionsInOrder(Records, "ConstraintOperator"))
    Operators.insert(R->getValueAsString("Spelling"));
  for (const Record *R : getDefinitionsInOrder(Records, "OperatorAlias"))
    Operators.insert(R->getValueAsString("Spelling"));
  OS << "{\n";
  emitList(OS, "instructions", Instructions, false);
  emitList(OS, "keywords", Keywords, false);
  emitList(OS, "operators", Operators.getArrayRef(), true);
  OS << "}\n";
}

TableGen::Emitter::Opt X("gen-web-keywords", emitWebKeywords,
                         "Generate the website highlighter's keywords");

} // namespace
