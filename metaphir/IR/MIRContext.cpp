#include "metaphir/IR/MIRContext.h"
#include "metaphir/IR/LibraryDefs.h"
#include "metaphir/IR/MIRContextImpl.h"

namespace llvm {
namespace metaphir {

// Libraries are loaded lazily by the parser (see MIRParser::loadLibrary): the
// IR library cannot call into the parser, which links against it.
MIRContext::MIRContext() : pImpl(new MIRContextImpl()) {}
MIRContext::~MIRContext() { delete pImpl; }

bool MIRContext::registerCompositeMatcher(CompositeMatcher *Matcher) {
  return pImpl->CompositeMatchers.try_emplace(Matcher->getName(), Matcher)
      .second;
}

CompositeMatcher *MIRContext::getCompositeMatcher(StringRef Name) const {
  auto It = pImpl->CompositeMatchers.find(Name);
  return It == pImpl->CompositeMatchers.end() ? nullptr : It->second;
}

bool MIRContext::registerConstraintDef(ConstraintDef *Def) {
  return pImpl->ConstraintDefs.try_emplace(Def->getName(), Def).second;
}

ConstraintDef *MIRContext::getConstraintDef(StringRef Name) const {
  auto It = pImpl->ConstraintDefs.find(Name);
  return It == pImpl->ConstraintDefs.end() ? nullptr : It->second;
}

bool MIRContext::registerMetaFlagDef(MetaFlagDef *Def) {
  return pImpl->MetaFlagDefs.try_emplace(Def->getName(), Def).second;
}

MetaFlagDef *MIRContext::getMetaFlagDef(StringRef Name) const {
  auto It = pImpl->MetaFlagDefs.find(Name);
  return It == pImpl->MetaFlagDefs.end() ? nullptr : It->second;
}

StringRef MIRContext::saveString(StringRef S) { return pImpl->Saver.save(S); }

bool MIRContext::isLibraryLoaded(StringRef Name) const {
  return pImpl->LoadedLibraries.contains(Name);
}

bool MIRContext::markLibraryLoaded(StringRef Name) {
  return pImpl->LoadedLibraries.insert(Name).second;
}

SourceMgr &MIRContext::getLibrarySourceMgr() { return pImpl->LibrarySources; }

const SourceMgr &MIRContext::getLibrarySourceMgr() const {
  return pImpl->LibrarySources;
}

} // namespace metaphir
} // namespace llvm
