//===- InstructionBase.td ------------------------------------------------*- tablegen -*-===//
//
// Classes for the instruction matchers and their flags.
//
//===----------------------------------------------------------------------===//

#ifndef METAPHIR_IR_INSTRUCTION_BASE_TD
#define METAPHIR_IR_INSTRUCTION_BASE_TD

/// A semantic flag an instruction matcher can name ('nsw', 'nnan', ...). The
/// record's name is its spelling.
class Flag {
  /// Whether the flag is one of LLVM's fast-math flags.
  bit FastMath = 0;
}

class FastMathFlag : Flag {
  let FastMath = 1;
}

/// A set of flags, which a matcher supports. The record's name is the name of
/// the instruction::FlagMask constant.
class FlagSet<list<Flag> flags> {
  list<Flag> Flags = flags;
}

/// A built-in instruction matcher. The record's name is the instruction's
/// spelling, which is also its keyword. Use the class of its operand syntax.
class InstructionMatcher {
  /// The llvm::Instruction opcode the matcher matches, unless TargetCheck is
  /// given.
  string Opcode = "";
  FlagSet SupportedFlags;
  /// Whether the matcher supports ':c'.
  bit Commutative = 0;
  /// How the parser spells the operands: Nary, Binary, Cast or Custom.
  string OperandSyntax;
  /// For the Nary syntax, the number of operands.
  int Arity;
  /// A C++ expression over `Target`, an llvm::Instruction, that tests for
  /// the instruction when it is not a single opcode.
  string TargetCheck = "";
}

/// select i1 ?c, i?n ?t, i?n ?f: Arity typed operands.
class NaryInstruction : InstructionMatcher {
  let OperandSyntax = "Nary";
}

/// add i?n ?a, ?b: a typed operand, a comma, a value.
class BinaryInstruction : InstructionMatcher {
  let OperandSyntax = "Binary";
  let Arity = 2;
}

/// trunc i?n ?a to i?m: a typed operand, 'to', a type.
class CastInstruction : InstructionMatcher {
  let OperandSyntax = "Cast";
  let Arity = 1;
}

/// Any other grammar (call, load, phi, ...), with bespoke parser code.
class CustomInstruction : InstructionMatcher {
  let OperandSyntax = "Custom";
  let Arity = 0;
}

#endif // METAPHIR_IR_INSTRUCTION_BASE_TD
