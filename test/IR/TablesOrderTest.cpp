//===- TablesOrderTest.cpp - The order of the language's tables ----------===//
//
// The order of the vocabulary tables is part of persisted formats (the corpus
// index schema, the ordinals stored in mpir attributes). This dumps the
// tables in order and compares them with test/IR/Golden/tables.txt, so a
// change to how the tables are defined cannot reorder them unnoticed.
//
//===----------------------------------------------------------------------===//

#include "metaphir/IR/Constants.h"
#include "metaphir/IR/Constraint.h"
#include "metaphir/IR/Instruction.h"
#include "metaphir/IR/MetaFlag.h"
#include "metaphir/IR/Sort.h"
#include "metaphir/IR/Type.h"
#include "test/GoldenFile.h"
#include "llvm/Support/Format.h"
#include "gtest/gtest.h"
#include <utility>

using namespace llvm;
using namespace llvm::metaphir;

namespace {

TEST(TablesOrderTest, MatchesTheGoldenDump) {
  std::string Dump;
  raw_string_ostream OS(Dump);

  OS << "[instructions]\n";
  for (unsigned I = 0; I != instruction::NumInstructionIDs; ++I) {
    auto ID = instruction::InstructionID(I);
    OS << I << ' ' << instruction::getOpcodeName(ID)
       << " flags=" << format_hex(instruction::getSupportedFlags(ID), 0)
       << " commutative=" << instruction::isCommutative(ID)
       << " syntax=" << unsigned(instruction::getOperandSyntax(ID))
       << " arity=" << instruction::getOperandArity(ID) << '\n';
  }

  OS << "[flags]\n";
  for (unsigned F = 0; F != instruction_flag::NumFlagIDs; ++F)
    OS << F << ' ' << instruction_flag::getName(instruction_flag::FlagID(F))
       << '\n';

  OS << "[metaflags]\n";
  for (unsigned M = metaflag::UnknownMetaFlag + 1; M <= metaflag::MF_not; ++M) {
    auto ID = metaflag::MetaFlagID(M);
    auto Schema = metaflag::getSchema(ID);
    OS << M << ' ' << metaflag::getMetaFlagName(ID)
       << " placement=" << unsigned(Schema->AllowedPlacement)
       << " args=" << Schema->MinArguments << ".." << Schema->MaxArguments
       << " kind=" << unsigned(Schema->Arguments) << '\n';
  }

  OS << "[sorts]\n";
  for (unsigned S = 0; S <= unsigned(Sort::StringArray); ++S)
    OS << S << ' ' << getSortName(Sort(S))
       << " representation=" << getSortName(getRepresentation(Sort(S))) << '\n';

  OS << "[primitive types]\n";
  for (unsigned T = 0; T <= primitive_type::LabelTyID; ++T)
    OS << T << ' ' << primitive_type::getName(primitive_type::TypeID(T))
       << '\n';

  OS << "[keyword constants]\n";
  for (unsigned K = 0; K <= keyword_constant::K_SLE; ++K)
    OS << K << ' '
       << keyword_constant::getKeywordName(keyword_constant::KeywordID(K))
       << '\n';

  OS << "[constraint operators]\n";
  for (unsigned O = constraint::UnknownOperator + 1;
       O <= constraint::O_KnownOnes; ++O) {
    auto ID = constraint::OperatorID(O);
    auto Schema = constraint::getOperatorSchema(ID);
    StringRef Name = constraint::getOperatorName(ID);
    OS << O << ' ' << Name << " result=" << getSortName(Schema->Result)
       << " arity=" << Schema->MinArity << ".." << Schema->MaxArity;
    // How the operator is written: a name may be a unary and a binary one.
    for (auto [Kind, KindName] : {std::pair(constraint::Unary, "unary"),
                                  std::pair(constraint::Binary, "binary"),
                                  std::pair(constraint::Call, "call")})
      if (constraint::getOperatorID(Name, Kind) == ID)
        OS << ' ' << KindName;
    // The sorts of the first arguments, and of the rest.
    OS << " args=";
    for (unsigned I = 0; I != 4; ++I)
      OS << (I ? "," : "") << getSortName(constraint::getArgumentType(ID, I));
    OS << '\n';
  }
  OS << "[constraint operator aliases]\n";
  for (StringRef Alias : {"add", "sub", "mul", "neg", "eq", "ne"})
    OS << Alias << " -> "
       << constraint::getOperatorName(
              constraint::getOperatorID(Alias, constraint::Call))
       << '\n';
  OS << "[coercions]\n";
  for (unsigned From = 0; From <= unsigned(Sort::StringArray); ++From)
    for (unsigned To = 0; To <= unsigned(Sort::StringArray); ++To)
      if (From != To && constraint::canCoerce(Sort(From), Sort(To)) &&
          !isSubsort(Sort(From), Sort(To)))
        OS << getSortName(Sort(From)) << " -> " << getSortName(Sort(To))
           << '\n';

  test::expectMatchesGolden("test/IR/Golden/tables.txt", OS.str());
}

} // namespace
