#ifndef METAPHIR_IR_META_FLAG_H
#define METAPHIR_IR_META_FLAG_H

#include "llvm/ADT/StringRef.h"
#include <optional>

namespace llvm {
namespace metaphir {

/// The built-in metaflags (':c', ':o', ':or', ':not'), from MetaFlags.def,
/// and what they accept. The others are defined by 'metaflag' definitions.
struct MetaFlag {
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

  static constexpr unsigned UnlimitedArgs = ~0u;

  static std::optional<Schema> getSchema(MetaFlagID ID);
  static MetaFlagID getMetaFlagID(StringRef Name);
  static StringRef getMetaFlagName(MetaFlagID ID);

  MetaFlag() = delete;
};

} // namespace metaphir
} // namespace llvm

#endif
