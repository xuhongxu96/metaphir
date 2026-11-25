//===- PlanStep.h - The steps of a compiled match plan ----------*- C++ -*-===//
//
// A plan compiled to a flat program is a sequence of steps, one per plan
// operation (see PlanProgram.cpp). Each kind of step is a struct of
// its own, naming what it reads and writes. Registers hold what a get step
// reads from the IR for later steps; slots hold the plan's bindings.
//
//===----------------------------------------------------------------------===//

#ifndef METAPHIR_EXEC_PLANSTEP_H
#define METAPHIR_EXEC_PLANSTEP_H

#include "metaphir/Dialect/Pattern/PatternDialect.h"
#include "metaphir/IR/Constants.h"
#include "metaphir/IR/Instruction.h"
#include "metaphir/IR/Sort.h"
#include "mlir/IR/Value.h"
#include "llvm/ADT/APFloat.h"
#include "llvm/ADT/APSInt.h"
#include "llvm/ADT/SmallVector.h"
#include "llvm/Support/SMLoc.h"
#include <optional>
#include <string>
#include <variant>

namespace llvm {
namespace metaphir {
namespace plan_step {

/// The index of a register.
using Register = unsigned;

//===----------------------------------------------------------------------===//
// Choices: each runs the rest of the path once per choice.
//===----------------------------------------------------------------------===//

/// Puts each instruction of the function in Result, in turn.
struct Foreach {
  Register Result;
};

/// Runs each alternative, the steps [Begin, End), in turn, and after each the
/// rest of the path, from After.
struct Either {
  SmallVector<std::pair<unsigned, unsigned>, 2> Alternatives;
  unsigned After;
};

//===----------------------------------------------------------------------===//
// Reading the IR: each puts what it reads in Result.
//===----------------------------------------------------------------------===//

/// Matcher operand Index of Instruction; fails if it has none.
struct GetOperand {
  Register Instruction;
  Register Result;
  unsigned Index;
};

/// The matcher operands of Instruction from First on, or their types.
struct GetOperandsFrom {
  Register Instruction;
  Register Result;
  unsigned First;
  bool Types;
};

/// The type of Value, or with OperandOf the type an alloca allocates or a GEP
/// indexes into.
struct GetType {
  Register Value;
  Register Result;
  bool OperandOf;
};

/// The block of Instruction.
struct GetParentBlock {
  Register Instruction;
  Register Result;
};

/// Whether Instruction has Flag.
struct GetFlag {
  Register Instruction;
  Register Result;
  instruction_flag::FlagID Flag;
};

/// The keyed operand Kind of Instruction; fails if it has none.
struct GetKeyed {
  Register Instruction;
  Register Result;
  mpir::OperandKind Kind;
};

/// Element Index of the constant Aggregate; fails if it has none.
struct GetElement {
  Register Aggregate;
  Register Result;
  unsigned Index;
};

//===----------------------------------------------------------------------===//
// Checking the IR: each fails unless what it checks holds.
//===----------------------------------------------------------------------===//

/// Value is an instruction Opcode matches.
struct CheckOpcode {
  Register Value;
  instruction::InstructionID Opcode;
};

/// Instruction has Flag if Present, and does not otherwise.
struct CheckFlag {
  Register Instruction;
  instruction_flag::FlagID Flag;
  bool Present;
};

/// Instruction has Count matcher operands, or with AtLeast at least Count.
struct CheckOperandCount {
  Register Instruction;
  unsigned Count;
  bool AtLeast;
};

/// The type IRType matches Pattern, unifying the pattern's variables.
struct CheckType {
  Register IRType;
  mpir::TypePatternAttr Pattern;
  bool TreatIntAsVec;
};

/// Value is Integer, or with TreatIntAsVec also a splat of it.
struct CheckInteger {
  Register Value;
  APSInt Integer;
  bool TreatIntAsVec;
};

/// Value is a floating-point constant equal to Float in its semantics.
struct CheckFloat {
  Register Value;
  APFloat Float;
};

/// Value is what Keyword names.
struct CheckKeyword {
  Register Value;
  keyword_constant::KeywordID Keyword;
};

/// Value is the global Name names.
struct CheckGlobal {
  Register Value;
  std::string Name;
};

/// Value is an aggregate constant of Delimiter's kind with Count elements.
struct CheckAggregate {
  Register Value;
  aggregate_constant::Delimiter Delimiter;
  unsigned Count;
};

//===----------------------------------------------------------------------===//
// Slots
//===----------------------------------------------------------------------===//

/// Slot is bound if Bound, and unbound otherwise.
struct CheckBound {
  unsigned Slot;
  bool Bound;
};

/// Fails: a path that cannot match.
struct Fail {};

/// Unifies Slot with Value, or with BySort with the binding of Value for a
/// variable of that sort; fails if there is none.
struct Bind {
  Register Value;
  unsigned Slot;
  std::optional<Sort> BySort;
};

/// Unifies Slot with Value.
struct BindConstant {
  unsigned Slot;
  bool Value;
};

//===----------------------------------------------------------------------===//
// Constraints: each is evaluated once the path reaches emit.
//===----------------------------------------------------------------------===//

/// What the constraints share: the condition to hold, and its source range,
/// which identifies the constraint.
struct Constraint {
  mlir::Value Condition;
  SMRange Range;
};

/// Condition holds. One a metaflag says is evaluated first.
struct Check : Constraint {
  bool FromMetaflag;
};

/// Binds Slot to Assigned if it is unbound; otherwise Condition holds.
struct Let : Constraint {
  unsigned Slot;
  mlir::Value Assigned;
};

/// Reports the path as a match if its constraints hold.
struct Emit {};

/// A step; std::monostate only holds an either's place while the builder lays
/// out its alternatives.
using Step =
    std::variant<std::monostate, Foreach, Either, GetOperand, GetOperandsFrom,
                 GetType, GetParentBlock, GetFlag, GetKeyed, GetElement,
                 CheckOpcode, CheckFlag, CheckOperandCount, CheckType,
                 CheckInteger, CheckFloat, CheckKeyword, CheckGlobal,
                 CheckAggregate, CheckBound, Fail, Bind, BindConstant, Check,
                 Let, Emit>;

} // namespace plan_step
} // namespace metaphir
} // namespace llvm

#endif // METAPHIR_EXEC_PLANSTEP_H
