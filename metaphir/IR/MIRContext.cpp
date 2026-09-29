#include "metaphir/IR/MIRContext.h"
#include "metaphir/IR/LibraryDefs.h"
#include "metaphir/IR/MIRContextImpl.h"

namespace llvm {
namespace metaphir {

// Libraries are loaded lazily by the parser (see MIRParser::loadLibrary): the
// IR library cannot call into the parser, which links against it.
MIRContext::MIRContext() : pImpl(new MIRContextImpl(*this)) {}
MIRContext::~MIRContext() { delete pImpl; }

void MIRContext::registerCompositeMatcher(CompositeMatcher *Matcher) {
  pImpl->CompositeMatchers[Matcher->getName()] = Matcher;
}

CompositeMatcher *MIRContext::getCompositeMatcher(StringRef Name) const {
  auto It = pImpl->CompositeMatchers.find(Name);
  return It == pImpl->CompositeMatchers.end() ? nullptr : It->second;
}

void MIRContext::registerConstraintDef(ConstraintDef *Def) {
  pImpl->ConstraintDefs[Def->getName()] = Def;
}

ConstraintDef *MIRContext::getConstraintDef(StringRef Name) const {
  auto It = pImpl->ConstraintDefs.find(Name);
  return It == pImpl->ConstraintDefs.end() ? nullptr : It->second;
}

void MIRContext::registerMetaFlagDef(MetaFlagDef *Def) {
  pImpl->MetaFlagDefs[Def->getName()] = Def;
}

MetaFlagDef *MIRContext::getMetaFlagDef(StringRef Name) const {
  auto It = pImpl->MetaFlagDefs.find(Name);
  return It == pImpl->MetaFlagDefs.end() ? nullptr : It->second;
}

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
