//===- LanguageBase.td - The language's vocabulary -------------*- tablegen -*-===//
//
// Classes for the tables that define the pattern language: what each record
// carries, and which backends of metaphir-tblgen turn them into C++. Each
// table lives in a .td of its own that includes this file; the order records
// are defined in is the order of the generated enums, and so of everything
// persisted from them.
//
//===----------------------------------------------------------------------===//

#ifndef METAPHIR_IR_LANGUAGE_BASE_TD
#define METAPHIR_IR_LANGUAGE_BASE_TD

/// A primitive type a pattern can name ('half', 'float', 'void', 'label', ...).
/// The others (integers, pointers, aggregates, vectors, functions and meta
/// types) are ops of the mpir dialect. The record's name is the enumerator of
/// primitive_type::TypeID.
class PrimitiveType<string spelling, string typeCheck, string summary> {
  /// How a pattern spells the type, which is also its keyword.
  string Spelling = spelling;
  /// The llvm::Type member that tests whether a type is this one.
  string TypeCheck = typeCheck;
  string Summary = summary;
}

/// A semantic flag an instruction matcher can name ('nsw', 'nnan', ...). The
/// record's name is its spelling.
class Flag {
  /// Whether the flag is one of LLVM's fast-math flags.
  bit FastMath = 0;
}

class FastMathFlag : Flag {
  let FastMath = 1;
}

/// A set of flags, which a matcher supports. The record's name is the name of
/// the instruction::FlagMask constant.
class FlagSet<list<Flag> flags> {
  list<Flag> Flags = flags;
}

/// A built-in instruction matcher. The record's name is the instruction's
/// spelling, which is also its keyword.
class InstructionMatcher<string opcode, FlagSet flags, bit commutative,
                         string syntax, int arity, string targetCheck = ""> {
  /// The llvm::Instruction opcode the matcher matches, unless TargetCheck is
  /// given.
  string Opcode = opcode;
  FlagSet SupportedFlags = flags;
  /// Whether the matcher supports ':c'.
  bit Commutative = commutative;
  /// How the parser spells the operands: Nary, Binary, Cast or Custom.
  string OperandSyntax = syntax;
  /// For the Nary syntax, the number of operands.
  int Arity = arity;
  /// A C++ expression over `Target`, an llvm::Instruction, that tests for
  /// the instruction when it is not a single opcode.
  string TargetCheck = targetCheck;
}

/// A constant or comparison predicate a pattern spells as a keyword. The
/// record's name is the enumerator of keyword_constant::KeywordID, after K_.
class KeywordConstant<string spelling> {
  string Spelling = spelling;
  /// The llvm class of the values a matchable constant matches, or empty.
  string LLVMClass = "";
}

class MatchableConstant<string spelling, string llvmClass>
    : KeywordConstant<spelling> {
  let LLVMClass = llvmClass;
}

class PredicateKeyword<string spelling> : KeywordConstant<spelling>;

/// A global pattern setting, written `;; <name>(true|false)`. The record's
/// name is its keyword.
class PatternSetting<int position, string comment, bit defaultValue = 0> {
  /// The setting is the mask 1 << Bit.
  int Bit = position;
  string Comment = comment;
  /// Whether the setting is on until a pattern writes it.
  bit Default = defaultValue;
}

/// A sort of meta variables and constraint expressions. The record is named
/// after the sort: Sort<ID>.
class Sort<string id, string name, string representation,
           string description = ""> {
  /// The enumerator of the Sort enum, which is also the sort's keyword in the
  /// mpir dialect.
  string ID = id;
  /// The name printed for the sort.
  string Name = name;
  /// The ID of the sort of the runtime value that represents this one in a
  /// constraint.
  string Representation = representation;
  /// A phrase naming the sort for diagnostics, e.g. "an integer". A sort that
  /// is some sort's representation needs one.
  string Description = description;
}

/// A direct subsort edge; the sort order is its reflexive-transitive closure
/// with Unknown above every sort.
class Subsort<Sort sub, Sort super> {
  Sort Sub = sub;
  Sort Super = super;
}

/// A built-in metaflag. Nestable, unless StructuralMetaFlag.
class MetaFlag<string name, string placement, int minArgs, int maxArgs,
               string argumentKind> {
  /// The flag's name, as in ':c'.
  string Name = name;
  /// Where the flag may be written: InstructionPlacement, OperandPlacement or
  /// AnyPlacement.
  string Placement = placement;
  int MinArguments = minArgs;
  /// The most arguments the flag takes, or -1 for any number.
  int MaxArguments = maxArgs;
  /// What the arguments are: AnyArgument, IntegerArgument or FlagArgument.
  string Arguments = argumentKind;
  /// Whether the flag changes how the instruction itself is matched, rather
  /// than adding a condition on it. Structural flags are not lowered to
  /// constraints.
  bit Structural = 0;
  /// Whether the flag may be an argument of another metaflag.
  bit Nestable = 1;
}

/// A flag that changes how the instruction itself is matched. It is not
/// nestable, as it is not a condition that another metaflag could combine.
class StructuralMetaFlag<string name, string placement, int minArgs,
                         int maxArgs, string argumentKind>
    : MetaFlag<name, placement, minArgs, maxArgs, argumentKind> {
  let Structural = 1;
  let Nestable = 0;
}

/// An operator of a constraint expression. The record is named Op<ID>, as the
/// C++ struct that evaluates it.
class ConstraintOperator<string id, string name, string kind, string result,
                         int minArity, int maxArity> {
  /// The enumerator of constraint::OperatorID, after O_.
  string ID = id;
  /// The operator's spelling.
  string Name = name;
  /// How it is written: Unary, Binary or Call.
  string Kind = kind;
  /// The ID of the sort of its result.
  string Result = result;
  int MinArity = minArity;
  int MaxArity = maxArity;
  /// The IDs of the sorts of its first arguments; the rest take RestSort.
  list<string> ArgumentSorts = [];
  string RestSort = "Unknown";
  /// Whether it is backed by value tracking, which takes an optional trailing
  /// context instruction: ExprEvaluator builds the SimplifyQuery, and
  /// IndexQuery looks at the context's sites.
  bit ValueTracking = 0;
}

class Operator<string id, string name, string kind, string result, int arity>
    : ConstraintOperator<id, name, kind, result, arity, arity>;

/// An operator with an optional trailing bit width.
class BitWidthOperator<string id, string name, string kind, string result,
                       int arity>
    : ConstraintOperator<id, name, kind, result, arity, !add(arity, 1)>;

/// A value-tracking operator; arity is without the optional context.
class ValueTrackOperator<string id, string name, string kind, string result,
                         int arity>
    : ConstraintOperator<id, name, kind, result, arity, !add(arity, 1)> {
  let ValueTracking = 1;
}

/// Another spelling of an operator.
class OperatorAlias<ConstraintOperator operator, string name, string kind> {
  ConstraintOperator Operator = operator;
  string Name = name;
  string Kind = kind;
}

/// A constant class named after a PatternMatch.h matcher. On an LLVM value it
/// is PatternMatch::<Matcher>(); on a plain integer V (an APSInt) it is
/// IntegerTest, a C++ expression, or false when that is empty.
class ConstantClass<string id, string name, string matcher, string integerTest,
                    bit recorded = 1>
    : Operator<id, name, "Call", "Boolean", 1> {
  string Matcher = matcher;
  string IntegerTest = integerTest;
  /// Whether the index records the class as a fact.
  bit Recorded = recorded;
}

class UnrecordedConstantClass<string id, string name, string matcher,
                              string integerTest>
    : ConstantClass<id, name, matcher, integerTest, 0>;

/// A boolean test of a comparison predicate P (a CmpInst::Predicate), a C++
/// expression.
class CmpPredicateTest<string id, string name, string expression>
    : Operator<id, name, "Call", "Boolean", 1> {
  string Expression = expression;
  let RestSort = "String";
}

/// The predicate a C++ expression of the predicate P gives.
class CmpPredicateMap<string id, string name, string expression>
    : Operator<id, name, "Call", "String", 1> {
  string Expression = expression;
  let RestSort = "String";
}

/// A directed coercion of a constraint value. Src and Dst are both sort IDs
/// and kinds of ConstraintValue; Op names the hand-written coerce<Op>.
class Coercion<string src, string dst, string op> {
  string Src = src;
  string Dst = dst;
  string Op = op;
}

/// A class of LLVM value that `isa` can test. The class's position is its
/// persisted ordinal.
class LLVMValueClass<string name, bit recorded = 1> {
  string Name = name;
  /// Whether the index records the class: not those nearly every value at a
  /// site is of.
  bit Recorded = recorded;
}

/// A predicate that holds for a value at a site, which the index records.
class Fact<string id, string name> {
  string ID = id;
  string Name = name;
  /// Whether it is from value tracking, anchored at the site's instruction.
  bit ValueTracking = 0;
}

class ValueTrackingFact<string id, string name> : Fact<id, name> {
  let ValueTracking = 1;
}

/// A number recorded for a site.
class Measure<string id, string name, string order> {
  string ID = id;
  string Name = name;
  /// Which of its values' numbers the site keeps: Most or Least.
  string Order = order;
}

/// How an aggregate constant is delimited: an array ('[...]'), a struct
/// ('{...}') or a vector ('<...>'). The delimiters' order is persisted: the
/// mpir dialect's SeqTypeOp numbers its kinds the same way.
class AggregateConstant<string id, string name> {
  /// The enumerator of aggregate_constant::Delimiter.
  string ID = id;
  /// How the mpir dialect spells the kind.
  string Name = name;
}

#endif // METAPHIR_IR_LANGUAGE_BASE_TD
