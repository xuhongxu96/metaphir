//===- ConstraintBase.td -------------------------------------------------*- tablegen -*-===//
//
// Classes for the operators of constraint expressions.
//
//===----------------------------------------------------------------------===//

#ifndef METAPHIR_IR_CONSTRAINT_BASE_TD
#define METAPHIR_IR_CONSTRAINT_BASE_TD

/// An operator of a constraint expression. The record is named Op<ID>, as the
/// C++ struct that evaluates it. Use the class that sets its arity.
class ConstraintOperator<string spelling> {
  /// The enumerator of constraint::OperatorID, after O_.
  string ID = !substr(NAME, 2);
  /// The operator's spelling.
  string Spelling = spelling;
  /// How it is written: Unary, Binary or Call.
  string Kind = "Call";
  /// The ID of the sort of its result.
  string Result;
  int MinArity;
  int MaxArity;
  /// The IDs of the sorts of its first arguments; the rest take RestSort.
  list<string> ArgumentSorts = [];
  string RestSort = "Unknown";
  /// Whether it is backed by value tracking, which takes an optional trailing
  /// context instruction: ConcreteEvaluator builds the SimplifyQuery, and
  /// IndexQuery looks at the context's sites.
  bit ValueTracking = 0;
}

/// An operator with Arity arguments.
class Operator<string spelling> : ConstraintOperator<spelling> {
  int Arity;
  let MinArity = Arity;
  let MaxArity = Arity;
}

/// An operator with an optional trailing bit width.
class BitWidthOperator<string spelling> : ConstraintOperator<spelling> {
  int Arity;
  let MinArity = Arity;
  let MaxArity = !add(Arity, 1);
}

/// A value-tracking operator; Arity is without the optional context.
class ValueTrackOperator<string spelling> : BitWidthOperator<spelling> {
  let ValueTracking = 1;
}

/// Another spelling of an operator.
class OperatorAlias<ConstraintOperator operator, string spelling> {
  ConstraintOperator Operator = operator;
  string Spelling = spelling;
  string Kind = "Call";
}

/// A constant class named after a PatternMatch.h matcher. On an LLVM value it
/// is PatternMatch::<Matcher>(); on a plain integer V (an APSInt) it is
/// IntegerTest, a C++ expression, or false when that is empty.
class ConstantClass<string spelling> : Operator<spelling> {
  let Result = "Boolean";
  let Arity = 1;
  string Matcher;
  string IntegerTest = "";
  /// Whether the index records the class as a fact.
  bit Recorded = 1;
}

class UnrecordedConstantClass<string spelling> : ConstantClass<spelling> {
  let Recorded = 0;
}

/// A boolean test of a comparison predicate P (a CmpInst::Predicate), a C++
/// expression.
class CmpPredicateTest<string spelling> : Operator<spelling> {
  let Result = "Boolean";
  let Arity = 1;
  let RestSort = "String";
  string Expression;
}

/// The predicate a C++ expression of the predicate P gives.
class CmpPredicateMap<string spelling> : Operator<spelling> {
  let Result = "CmpPredicate";
  let Arity = 1;
  let RestSort = "String";
  string Expression;
}

#endif // METAPHIR_IR_CONSTRAINT_BASE_TD
