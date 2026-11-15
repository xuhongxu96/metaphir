#include "metaphir/IR/MetaFlag.h"
#include "llvm/ADT/StringSwitch.h"
#include "llvm/Support/ErrorHandling.h"

namespace llvm {
namespace metaphir {

StringRef metaflag::getMetaFlagName(MetaFlagID ID) {
  switch (ID) {
#define MIR_META_FLAG_ID(FlagName)                                             \
  case MF_##FlagName:                                                          \
    return #FlagName;
#include "metaphir/IR/MetaFlags.def"
  case UnknownMetaFlag:
    break;
  }
  llvm_unreachable("invalid meta flag ID");
}

metaflag::MetaFlagID metaflag::getMetaFlagID(StringRef Name) {
  return StringSwitch<MetaFlagID>(Name)
#define MIR_META_FLAG_ID(FlagName) .Case(#FlagName, MF_##FlagName)
#include "metaphir/IR/MetaFlags.def"
      .Default(UnknownMetaFlag);
}

std::optional<metaflag::Schema> metaflag::getSchema(MetaFlagID ID) {
  switch (ID) {
#define MIR_META_FLAG_SCHEMA(FlagName, Placement, MinArgs, MaxArgs,            \
                             ArgumentKind)                                     \
  case MF_##FlagName:                                                          \
    return Schema{Placement, MinArgs, MaxArgs, ArgumentKind};
#include "metaphir/IR/MetaFlags.def"
  case UnknownMetaFlag:
    break;
  }
  return std::nullopt;
}

} // namespace metaphir
} // namespace llvm
