//===- FactEmitter.cpp - facts, measures and LLVM value classes
//------------===//
//
// -gen-facts: metaphir/Matching/Operators/Facts.inc, what the corpus index
// records about the values at a site.
// -gen-value-classes: metaphir/Matching/LLVMValueClasses.inc, the LLVM value
// classes `isa` can test.
//
//===----------------------------------------------------------------------===//

#include "Emit.h"
#include "Records.h"
#include "llvm/ADT/StringSet.h"

using namespace llvm;
using namespace metaphir_tblgen;

namespace {

void emitFacts(const RecordKeeper &Records, raw_ostream &OS) {
  // The recorded constant classes, then the other facts, then the
  // value-tracking ones, which must come last.
  struct FactInfo {
    std::string ID, Name;
  };
  SmallVector<FactInfo, 64> Facts;
  for (const Record *C : getDefinitionsInOrder(Records, "ConstantClass"))
    if (C->getValueAsBit("Recorded"))
      Facts.push_back(
          {C->getValueAsString("ID").str(), C->getValueAsString("Name").str()});
  unsigned NumPlain = Facts.size();
  auto Plain = getDefinitionsInOrder(Records, "Fact");
  for (const Record *F : Plain)
    if (!F->getValueAsBit("ValueTracking")) {
      Facts.push_back(
          {F->getValueAsString("ID").str(), F->getValueAsString("Name").str()});
      ++NumPlain;
    }
  for (const Record *F : Plain)
    if (F->getValueAsBit("ValueTracking"))
      Facts.push_back(
          {F->getValueAsString("ID").str(), F->getValueAsString("Name").str()});
  StringSet<> IDs;
  for (const FactInfo &F : Facts)
    if (!IDs.insert(F.ID).second)
      PrintFatalError("the fact '" + F.ID + "' is defined twice");
  auto Measures = getDefinitionsInOrder(Records, "Measure");
  for (const Record *M : Measures)
    if (M->getValueAsString("Order") != "Most" &&
        M->getValueAsString("Order") != "Least")
      PrintFatalError(M, "a measure's order is Most or Least");

  beginHeader(OS, Records, "What the index records at a site",
              "METAPHIR_MATCHING_OPERATORS_FACTS_INC",
              {"llvm/ADT/StringRef.h", "cstdint"});
  OS << "// The data of the facts and measures; "
        "metaphir/Matching/Operators/Facts.h reads it.\n\n"
        "namespace fact {\n/// A predicate that holds for a value at a site.\n"
        "enum Predicate : uint8_t {\n";
  for (const FactInfo &F : Facts)
    OS << "  " << F.ID << ",\n";
  OS << "  NumPredicates\n};\n\n"
        "/// The predicates before the value-tracking ones.\n"
        "inline constexpr unsigned NumPlainPredicates = "
     << NumPlain
     << ";\n\n/// The name of each predicate, in the order of "
        "Predicate.\n";
  emitArray<decltype(Facts), FactInfo>(
      OS, "StringLiteral PredicateNames[]", Facts,
      [](raw_ostream &OS, const FactInfo &F) { OS << '"' << F.Name << '"'; });
  OS << "} // namespace fact\n\n"
        "/// Numbers recorded for a site: the most, or the least, of the "
        "values "
        "there.\nenum class Measure : uint8_t {\n";
  for (const Record *M : Measures)
    OS << "  " << M->getValueAsString("ID") << ",\n";
  OS << "  NumMeasures\n};\n\n"
        "/// Which of its values' numbers a site keeps for a measure.\n"
        "enum class MeasureOrder : uint8_t {\n"
        "  /// The most: a larger number satisfies more queries.\n  Most,\n"
        "  /// The least: a smaller number satisfies more queries.\n  "
        "Least\n};\n\n"
        "/// What a measure is called, and its order.\n"
        "struct MeasureInfo {\n  StringLiteral Name;\n  MeasureOrder "
        "Order;\n};\n\n";
  emitArray<decltype(Measures), const Record *>(
      OS, "MeasureInfo MeasureInfos[]", Measures,
      [](raw_ostream &OS, const Record *const &M) {
        OS << "{\"" << M->getValueAsString("Name")
           << "\", MeasureOrder::" << M->getValueAsString("Order") << "}";
      });
  endHeader(OS, "METAPHIR_MATCHING_OPERATORS_FACTS_INC");
}

void emitValueClasses(const RecordKeeper &Records, raw_ostream &OS) {
  auto Classes = getDefinitionsInOrder(Records, "LLVMValueClass");
  beginHeader(OS, Records, "The LLVM value classes",
              "METAPHIR_MATCHING_LLVM_VALUE_CLASSES_INC",
              {"llvm/ADT/StringRef.h", "llvm/IR/Constants.h",
               "llvm/IR/Function.h", "llvm/IR/GlobalValue.h",
               "llvm/IR/InstrTypes.h", "llvm/IR/Instructions.h"});
  OS << "// The data of the classes, in the order of their persisted ordinals; "
        "\n// metaphir/Matching/LLVMValueClasses.h reads it.\n\n"
        "inline constexpr unsigned NumValueClasses = "
     << Classes.size()
     << ";\n\n/// What a class is called, whether the "
        "index records it (not those nearly\n/// every value at a site is "
        "of), and its `isa` test.\n"
        "struct ValueClassInfo {\n  StringLiteral Name;\n  bool Recorded;\n"
        "  bool (*Is)(const llvm::Value &V);\n};\n\n";
  emitArray<decltype(Classes), const Record *>(
      OS, "ValueClassInfo ValueClasses[]", Classes,
      [](raw_ostream &OS, const Record *const &C) {
        OS << "{\"" << C->getValueAsString("Name") << "\", "
           << (C->getValueAsBit("Recorded") ? "true" : "false")
           << ", [](const llvm::Value &V) { return isa<llvm::"
           << C->getValueAsString("Name") << ">(V); }}";
      });
  endHeader(OS, "METAPHIR_MATCHING_LLVM_VALUE_CLASSES_INC");
}

TableGen::Emitter::Opt X("gen-facts", emitFacts,
                         "Generate the facts and measures of the index");
TableGen::Emitter::Opt Y("gen-value-classes", emitValueClasses,
                         "Generate the LLVM value classes");

} // namespace
