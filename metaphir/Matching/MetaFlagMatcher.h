#ifndef METAPHIR_MATCHING_META_FLAG_MATCHER_H
#define METAPHIR_MATCHING_META_FLAG_MATCHER_H

#include "metaphir/IR/MetaFlag.h"
#include "metaphir/Matching/Instantiation.h"
#include "llvm/ADT/ArrayRef.h"

namespace llvm {
namespace metaphir {

class MetaFlagMatcher {
public:
  explicit MetaFlagMatcher(ArrayRef<MetaFlag *> Flags) : Flags(Flags) {}

  MetaFlagMatcher(const MetaFlagMatcher &) = delete;
  MetaFlagMatcher(MetaFlagMatcher &&) = delete;

  bool hasMetaFlag(MetaFlag::MetaFlagID ID) {
    return any_of(Flags, [ID](const MetaFlag *Flag) {
      return Flag->getMetaFlagID() == ID;
    });
  }

  bool matchOperandFlags(const llvm::Value &Target);
  bool matchUseFlags(const llvm::Value &Target);

private:
  const MetaFlag &getNestedMetaFlag(const MetaFlag::Argument &Argument);
  bool matchOperandFlag(const MetaFlag &Flag, const llvm::Value &Target);

  ArrayRef<MetaFlag *> Flags;
};

} // namespace metaphir
} // namespace llvm

#endif
