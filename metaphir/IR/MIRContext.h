#ifndef METAPHIR_IR_MIR_CONTEXT_H
#define METAPHIR_IR_MIR_CONTEXT_H

#include "llvm/ADT/StringRef.h"

namespace llvm {
class SourceMgr;

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

  /// Registers a definition under its name. Returns false, leaving the
  /// existing definition in place, if the name is already taken.
  bool registerCompositeMatcher(CompositeMatcher *Matcher);
  CompositeMatcher *getCompositeMatcher(StringRef Name) const;

  bool registerConstraintDef(ConstraintDef *Def);
  ConstraintDef *getConstraintDef(StringRef Name) const;

  bool registerMetaFlagDef(MetaFlagDef *Def);
  MetaFlagDef *getMetaFlagDef(StringRef Name) const;

  /// Returns a copy of S owned by this context.
  StringRef saveString(StringRef S);

  /// Whether the library named Name has been loaded into this context.
  bool isLibraryLoaded(StringRef Name) const;

  /// Records Name as loaded, returning false if it already was. A loader marks
  /// its library once it has parsed successfully.
  bool markLibraryLoaded(StringRef Name);

  /// The source manager holding the text of every library loaded into this
  /// context. Library definitions keep source ranges into these buffers, so
  /// they live as long as the context.
  SourceMgr &getLibrarySourceMgr();
  const SourceMgr &getLibrarySourceMgr() const;
};

} // namespace metaphir
} // namespace llvm

#endif
