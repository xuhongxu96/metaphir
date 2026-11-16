#include "metaphir/IR/MetaFlag.h"
#include "llvm/ADT/StringSwitch.h"
#include "llvm/Support/ErrorHandling.h"

namespace llvm {
namespace metaphir {
namespace metaflag {

StringRef getMetaFlagName(MetaFlagID ID) {
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

MetaFlagID getMetaFlagID(StringRef Name) {
  return StringSwitch<MetaFlagID>(Name)
#define MIR_META_FLAG_ID(FlagName) .Case(#FlagName, MF_##FlagName)
#include "metaphir/IR/MetaFlags.def"
      .Default(UnknownMetaFlag);
}

std::optional<Schema> getSchema(MetaFlagID ID) {
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

} // namespace metaflag
} // namespace metaphir
} // namespace llvm
