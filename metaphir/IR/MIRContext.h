#ifndef METAPHIR_IR_MIR_CONTEXT_H
#define METAPHIR_IR_MIR_CONTEXT_H

#include "llvm/ADT/StringRef.h"

namespace llvm {
namespace metaphir {

class MIRContextImpl;
class CompositeMatcher;
class ConstraintDef;
class MetaFlagDef;

class MIRContext {
public:
  MIRContextImpl *const pImpl;

  MIRContext();
  MIRContext(const MIRContext &) = delete;
  MIRContext &operator=(const MIRContext &) = delete;
  ~MIRContext();

  void registerCompositeMatcher(CompositeMatcher *Matcher);
  CompositeMatcher *getCompositeMatcher(StringRef Name) const;

  void registerConstraintDef(ConstraintDef *Def);
  ConstraintDef *getConstraintDef(StringRef Name) const;

  void registerMetaFlagDef(MetaFlagDef *Def);
  MetaFlagDef *getMetaFlagDef(StringRef Name) const;

  /// Whether the library named Name has been loaded into this context.
  bool isLibraryLoaded(StringRef Name) const;

  /// Records Name as loaded, returning false if it already was. A loader marks
  /// its library before parsing it, so parsing the library cannot re-enter the
  /// loader.
  bool markLibraryLoaded(StringRef Name);
};

} // namespace metaphir
} // namespace llvm

#endif
