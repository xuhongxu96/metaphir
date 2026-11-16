#ifndef METAPHIR_IR_META_FLAG_H
#define METAPHIR_IR_META_FLAG_H

#include "llvm/ADT/StringRef.h"
#include <optional>

namespace llvm {
namespace metaphir {

/// The built-in metaflags (':c', ':o', ':or', ':not'), from MetaFlags.def,
/// and what they accept. The others are defined by 'metaflag' definitions.
namespace metaflag {
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
  /// Whether the flag may be an argument of another metaflag.
  bool Nestable;
};

constexpr unsigned UnlimitedArgs = ~0u;

std::optional<Schema> getSchema(MetaFlagID ID);
MetaFlagID getMetaFlagID(StringRef Name);
StringRef getMetaFlagName(MetaFlagID ID);
} // namespace metaflag

} // namespace metaphir
} // namespace llvm

#endif
