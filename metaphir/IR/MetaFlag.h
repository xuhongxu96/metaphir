#ifndef METAPHIR_IR_META_FLAG_H
#define METAPHIR_IR_META_FLAG_H

#include "metaphir/IR/MetaVariable.h"
#include "llvm/ADT/ArrayRef.h"
#include <optional>

namespace llvm {
namespace metaphir {

class MetaFlag {
public:
  enum MetaFlagID {
    UnknownMetaFlag,
#define MIR_META_FLAG_ID(Name) MF_##Name,
#include "metaphir/IR/MetaFlags.def"
  };

  enum Placement {
    InstructionPlacement = 1,
    OperandPlacement = 2,
    AnyPlacement = InstructionPlacement | OperandPlacement
  };

  enum ArgumentKind { AnyArgument, IntegerArgument, FlagArgument };

  struct Schema {
    Placement AllowedPlacement;
    unsigned MinArguments;
    unsigned MaxArguments;
    ArgumentKind Arguments;
  };

  struct Argument {
    enum Kind { Integer, Flag };

    Kind K;
    int64_t IntegerValue = 0;
    MetaFlag *FlagValue = nullptr;
  };

  static constexpr unsigned UnlimitedArgs = ~0u;

  StringRef getName() const { return Name; }
  MetaFlagID getMetaFlagID() const { return ID; }
  ArrayRef<Argument> getArguments() const { return Arguments; }
  SourceRange getSourceRange() const { return Range; }

  static std::optional<Schema> getSchema(MetaFlagID ID);
  static MetaFlagID getMetaFlagID(StringRef Name);
  static MetaFlag *get(MIRContext &Context, StringRef Name,
                       ArrayRef<Argument> Arguments, SourceRange Range);

private:
  MetaFlagID ID;
  StringRef Name;
  ArrayRef<Argument> Arguments;
  SourceRange Range;

  MetaFlag(MetaFlagID ID, StringRef Name, ArrayRef<Argument> Arguments,
           SourceRange Range)
      : ID(ID), Name(Name), Arguments(Arguments), Range(Range) {}
};

raw_ostream &operator<<(raw_ostream &OS, const MetaFlag::Argument &A);
raw_ostream &operator<<(raw_ostream &OS, const MetaFlag &F);

} // namespace metaphir
} // namespace llvm

#endif
