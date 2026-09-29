#ifndef METAPHIR_IR_COMPOSITEMATCHER_H
#define METAPHIR_IR_COMPOSITEMATCHER_H

#include "metaphir/IR/Constraint.h"
#include "metaphir/IR/Instruction.h"
#include "metaphir/IR/MetaFlag.h"
#include "metaphir/IR/MetaVariable.h"
#include "llvm/ADT/ArrayRef.h"
#include "llvm/ADT/STLExtras.h"
#include "llvm/ADT/StringRef.h"

namespace llvm {
namespace metaphir {

class MIRContext;
class MetaVariable;

/// A parameter of a 'match' declaration: a type position or an operand.
struct ParameterDef {
  /// Name this parameter binds. Empty when a type parameter is written as a
  /// concrete type, which fixes the type instead of binding a name for it.
  StringRef Name;
  /// Type written for a type parameter; null for operand parameters.
  Type *Ty = nullptr;
  /// Where the parameter was written, carried so the meta variables bound for
  /// it in each branch can point back at the declaration.
  SourceRange Range;
  bool IsType = false;
};

/// A 'match' definition: a named matcher, used like a built-in instruction
/// matcher, that matches any of its branches. Owned by the MIRContext;
/// PatternLowering expands every use into one pattern per branch.
class CompositeMatcher {
public:
  struct Branch {
    ArrayRef<Instruction *> Instructions;
    ArrayRef<Constraint *> Constraints;
    ArrayRef<std::pair<InstructionFlag::FlagID, bool>> FixedFlags;
    /// The branch's own meta variable for each matcher parameter, parallel to
    /// CompositeMatcher::getParameters(); null for a type parameter written as
    /// a concrete type. Parameters repeated by name share one variable.
    ArrayRef<MetaVariable *> ParameterVars;
    /// Meta variables the branch body introduces besides its parameters. Each
    /// use of the matcher gets fresh copies of them.
    ArrayRef<MetaVariable *> LocalVariables;
    /// The instruction standing for the matcher's result: the one named
    /// '%ret', or else the last one.
    Instruction *Root = nullptr;
  };

  /// Creates a matcher owned by Context, which keeps copies of the name and
  /// of every array, including those of the branches.
  static CompositeMatcher *
  create(MIRContext &Context, StringRef Name, bool IsCommutative,
         ArrayRef<InstructionFlag::FlagID> SupportedFlags,
         Instruction::OperandSyntax Syntax, unsigned Arity,
         ArrayRef<ParameterDef> Parameters, ArrayRef<Branch> Branches);

private:
  CompositeMatcher(StringRef Name, bool IsCommutative,
                   ArrayRef<InstructionFlag::FlagID> SupportedFlags,
                   Instruction::OperandSyntax Syntax, unsigned Arity,
                   ArrayRef<ParameterDef> Parameters, ArrayRef<Branch> Branches)
      : Name(Name), IsCommutative(IsCommutative),
        SupportedFlags(SupportedFlags), Syntax(Syntax), Arity(Arity),
        Parameters(Parameters), Branches(Branches) {}

public:
  StringRef getName() const { return Name; }
  bool isCommutative() const { return IsCommutative; }
  ArrayRef<InstructionFlag::FlagID> getSupportedFlags() const {
    return SupportedFlags;
  }
  bool hasSupportedFlag(InstructionFlag::FlagID ID) const {
    return llvm::is_contained(SupportedFlags, ID);
  }
  Instruction::OperandSyntax getSyntax() const { return Syntax; }
  // Number of value operands at a use site.
  unsigned getArity() const { return Arity; }
  ArrayRef<ParameterDef> getParameters() const { return Parameters; }
  ArrayRef<Branch> getBranches() const { return Branches; }

private:
  StringRef Name;
  bool IsCommutative;
  ArrayRef<InstructionFlag::FlagID> SupportedFlags;
  Instruction::OperandSyntax Syntax;
  unsigned Arity;
  ArrayRef<ParameterDef> Parameters;
  ArrayRef<Branch> Branches;
};

} // namespace metaphir
} // namespace llvm

#endif
