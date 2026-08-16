#ifndef METAPHIR_PARSER_MIR_CONSTRAINT_LEXER_H
#define METAPHIR_PARSER_MIR_CONSTRAINT_LEXER_H

#include "metaphir/Parser/MIRToken.h"

namespace llvm {
namespace metaphir {

class MIRLexer;

class MIRConstraintLexer {
public:
  explicit MIRConstraintLexer(MIRLexer &Lexer) : Lexer(Lexer) {}
  tok::Kind Lex();

private:
  MIRLexer &Lexer;
};

} // namespace metaphir
} // namespace llvm

#endif
