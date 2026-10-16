#ifndef METAPHIR_IR_LIBRARYDEFS_H
#define METAPHIR_IR_LIBRARYDEFS_H

#include "metaphir/IR/Constraint.h"
#include "metaphir/IR/MetaFlag.h"
#include "llvm/ADT/ArrayRef.h"
#include "llvm/ADT/StringRef.h"
#include <cassert>

namespace llvm {
namespace metaphir {

/// A 'constraint name(?params) { body }' definition: a named, parameterized
/// constraint expression that calls in other constraints expand to.
class ConstraintDef {
public:
  /// Creates a definition owned by Context, which keeps copies of the name
  /// and arrays.
  static ConstraintDef *create(MIRContext &Context, StringRef Name,
                               ArrayRef<StringRef> Parameters,
                               ArrayRef<MetaVariable *> ParameterVars,
                               Constraint *Body);

private:
  ConstraintDef(StringRef Name, ArrayRef<StringRef> Parameters,
                ArrayRef<MetaVariable *> ParameterVars, Constraint *Body)
      : Name(Name), Parameters(Parameters), ParameterVars(ParameterVars),
        Body(Body) {}

public:
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

/// A 'metaflag :name(?subject, ?args...) { body }' definition: a flag that
/// lowers to its body, with the flagged operand or instruction as ?subject.
class MetaFlagDef {
public:
  /// Creates a definition owned by Context, which keeps copies of the name
  /// and arrays.
  static MetaFlagDef *create(MIRContext &Context, StringRef Name,
                             MetaFlag::Placement Placement,
                             ArrayRef<StringRef> Parameters,
                             ArrayRef<MetaVariable *> ParameterVars,
                             Constraint *Body);

private:
  MetaFlagDef(StringRef Name, MetaFlag::Placement Placement,
              ArrayRef<StringRef> Parameters,
              ArrayRef<MetaVariable *> ParameterVars, Constraint *Body)
      : Name(Name), Placement(Placement), Parameters(Parameters),
        ParameterVars(ParameterVars), Body(Body) {
    assert(!Parameters.empty() && "a metaflag has at least its subject");
    assert(Parameters.size() == ParameterVars.size() &&
           "one variable per parameter");
  }

public:
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

  Constraint *getBody() const { return Body; }

private:
  StringRef Name;
  MetaFlag::Placement Placement;
  ArrayRef<StringRef> Parameters;
  ArrayRef<MetaVariable *> ParameterVars;
  Constraint *Body;
};

} // namespace metaphir
} // namespace llvm

#endif // METAPHIR_IR_LIBRARYDEFS_H
