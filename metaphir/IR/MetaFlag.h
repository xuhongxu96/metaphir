#ifndef METAPHIR_IR_META_FLAG_H
#define METAPHIR_IR_META_FLAG_H

#include "metaphir/IR/MetaFlag.inc"
#include <cassert>
#include <optional>

namespace llvm {
namespace metaphir {

/// The built-in metaflags (':c', ':o', ':or', ':not'), and what they accept.
/// The others are defined by 'metaflag' definitions. Their data is generated
/// from MetaFlags.td (MetaFlag.inc); this reads it.
namespace metaflag {

inline StringRef getMetaFlagName(MetaFlagID ID) {
  assert(ID > UnknownMetaFlag && "invalid meta flag ID");
  return BuiltIns[ID - 1].Name;
}

inline MetaFlagID getMetaFlagID(StringRef Name) {
  for (const BuiltIn &Flag : BuiltIns)
    if (Flag.Name == Name)
      return MetaFlagID(&Flag - BuiltIns + 1);
  return UnknownMetaFlag;
}

inline std::optional<Schema> getSchema(MetaFlagID ID) {
  if (ID == UnknownMetaFlag)
    return std::nullopt;
  return BuiltIns[ID - 1].Accepts;
}

} // namespace metaflag
} // namespace metaphir
} // namespace llvm

#endif
