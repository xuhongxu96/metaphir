#ifndef METAPHIR_IR_COMPOSITEMATCHER_H
#define METAPHIR_IR_COMPOSITEMATCHER_H

#include "metaphir/IR/Constraints.h"
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

class ConstraintDef {
public:
  ConstraintDef(StringRef Name, ArrayRef<StringRef> Parameters,
                ArrayRef<MetaVariable *> ParameterVars, Constraint *Body)
      : Name(Name), Parameters(Parameters), ParameterVars(ParameterVars),
        Body(Body) {}

  StringRef getName() const { return Name; }
  ArrayRef<StringRef> getParameters() const { return Parameters; }
  ArrayRef<MetaVariable *> getParameterVars() const { return ParameterVars; }
  Constraint *getBody() const { return Body; }

private:
  StringRef Name;
  ArrayRef<StringRef> Parameters;
  ArrayRef<MetaVariable *> ParameterVars;
  Constraint *Body;
};

class MetaFlagDef {
public:
  MetaFlagDef(StringRef Name, MetaFlag::Placement Placement,
              ArrayRef<StringRef> Parameters,
              ArrayRef<MetaVariable *> ParameterVars, Constraint *Body)
      : Name(Name), Placement(Placement), Parameters(Parameters),
        ParameterVars(ParameterVars), Body(Body) {}

  StringRef getName() const { return Name; }

  /// Where the flag may be written: on an operand, on an instruction, or both.
  MetaFlag::Placement getPlacement() const { return Placement; }

  /// The declared parameters. The first is the subject the flag is written on
  /// (the operand or the instruction); the rest are its arguments, so
  /// ':f(1, 2)' needs three parameters.
  ArrayRef<StringRef> getParameters() const { return Parameters; }
  ArrayRef<MetaVariable *> getParameterVars() const { return ParameterVars; }

  /// Number of arguments a use must supply, i.e. every parameter but the
  /// subject.
  unsigned getNumArguments() const { return Parameters.size() - 1; }

  StringRef getSubjectParameter() const { return Parameters.front(); }

  Constraint *getBody() const { return Body; }

private:
  StringRef Name;
  MetaFlag::Placement Placement;
  ArrayRef<StringRef> Parameters;
  ArrayRef<MetaVariable *> ParameterVars;
  Constraint *Body;
};

class CompositeMatcher {
public:
  struct Branch {
    ArrayRef<Instruction *> Instructions;
    ArrayRef<Constraint *> Constraints;
    ArrayRef<std::pair<InstructionFlag::FlagID, bool>> FixedFlags;
  };

  CompositeMatcher(StringRef Name, bool IsCommutative,
                   ArrayRef<InstructionFlag::FlagID> SupportedFlags,
                   Instruction::OperandSyntax Syntax, unsigned Arity,
                   ArrayRef<ParameterDef> Parameters, ArrayRef<Branch> Branches)
      : Name(Name), IsCommutative(IsCommutative),
        SupportedFlags(SupportedFlags), Syntax(Syntax), Arity(Arity),
        Parameters(Parameters), Branches(Branches) {}

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
