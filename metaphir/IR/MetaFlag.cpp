#include "metaphir/IR/MetaFlag.h"
#include "metaphir/IR/MIRContext.h"
#include "metaphir/IR/MIRContextImpl.h"
#include "llvm/Support/raw_ostream.h"

namespace llvm {
namespace metaphir {

MetaFlag *MetaFlag::get(MIRContext &Context, StringRef Name,
                        ArrayRef<Argument> Arguments, SourceRange Range) {
  return new (Context.pImpl->Alloc)
      MetaFlag(getMetaFlagID(Name), Context.pImpl->Saver.save(Name),
               Context.pImpl->copyArray<Argument>(Arguments), Range);
}

MetaFlag::MetaFlagID MetaFlag::getMetaFlagID(StringRef Name) {
#define MIR_META_FLAG_ID(FlagName)                                             \
  if (Name == #FlagName)                                                       \
    return MF_##FlagName;
#include "metaphir/IR/MetaFlags.def"
  return UnknownMetaFlag;
}

std::optional<MetaFlag::Schema> MetaFlag::getSchema(MetaFlagID ID) {
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

raw_ostream &operator<<(raw_ostream &OS, const MetaFlag::Argument &A) {
  if (A.K == MetaFlag::Argument::Integer)
    return OS << A.IntegerValue;
  return OS << *A.FlagValue;
}

raw_ostream &operator<<(raw_ostream &OS, const MetaFlag &F) {
  OS << ':' << F.getName();
  if (!F.getArguments().empty()) {
    OS << '(';
    for (unsigned I = 0; I != F.getArguments().size(); ++I) {
      if (I)
        OS << ',';
      OS << F.getArguments()[I];
    }
    OS << ')';
  }
  return OS;
}

} // namespace metaphir
} // namespace llvm
