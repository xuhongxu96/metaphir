//===- FactBase.td -------------------------------------------------------*- tablegen -*-===//
//
// Classes for what a corpus index records at a site.
//
//===----------------------------------------------------------------------===//

#ifndef METAPHIR_MATCHING_FACT_BASE_TD
#define METAPHIR_MATCHING_FACT_BASE_TD

/// A class of LLVM value that `isa` can test. The class's position is its
/// persisted ordinal.
class LLVMValueClass<string name> {
  string Name = name;
  /// Whether the index records the class: not those nearly every value at a
  /// site is of.
  bit Recorded = 1;
}

class UnrecordedLLVMValueClass<string name> : LLVMValueClass<name> {
  let Recorded = 0;
}

/// A predicate that holds for a value at a site, which the index records. The
/// record is named after its ID.
class Fact<string name> {
  string ID = NAME;
  string Name = name;
  /// Whether it is from value tracking, anchored at the site's instruction.
  bit ValueTracking = 0;
}

class ValueTrackingFact<string name> : Fact<name> {
  let ValueTracking = 1;
}

/// A number recorded for a site. The record is named after its ID.
class Measure<string name> {
  string ID = NAME;
  string Name = name;
  /// Which of its values' numbers the site keeps: Most or Least.
  string Order;
}

#endif // METAPHIR_MATCHING_FACT_BASE_TD
