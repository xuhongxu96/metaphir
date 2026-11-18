//===- Sorts.td - Sorts of meta variables and constraints -*- tablegen -*-===//
//
// One sort system classifies both meta variables and constraint expressions.
// A meta variable's sort is the meet of the sorts its occurrences require;
// a constraint expression's sort is checked against operator signatures.
// Generated into Sort.inc by metaphir-tblgen -gen-sorts.
//
//===----------------------------------------------------------------------===//

/// A sort of meta variables and constraint expressions. The record is named
/// Sort<ID>.
class Sort<string name> {
  /// The enumerator of the Sort enum, which is also the sort's keyword in the
  /// mpir dialect.
  string ID = !substr(NAME, 4);
  /// The name printed for the sort.
  string Name = name;
  /// The ID of the sort of the runtime value that represents this one in a
  /// constraint.
  string Representation;
  /// A phrase naming the sort for diagnostics, e.g. "an integer". A sort that
  /// is some sort's representation needs one.
  string Description = "";
}

/// A direct subsort edge; the sort order is its reflexive-transitive closure
/// with Unknown above every sort.
class Subsort<Sort sub, Sort super> {
  Sort Sub = sub;
  Sort Super = super;
}

// Not yet inferred; a top element below which every sort lies.
def SortUnknown : Sort<"Unknown"> {
  let Representation = "Unknown";
  let Description = "any value";
}
// What an operand position accepts. A meta variable that occurs only as an
// operand denotes a value (see resolveSort).
def SortOperand : Sort<"Operand"> {
  let Representation = "Value";
}
def SortValue : Sort<"Value"> {
  let Representation = "Value";
  let Description = "a value";
}
def SortInstruction : Sort<"Instruction"> {
  let Representation = "Value";
}
def SortFunction : Sort<"Function"> {
  let Representation = "Value";
}
// A block is not an operand of a first-class type, so it lies outside
// Operand; constraints still read it as a value.
def SortBasicBlock : Sort<"BasicBlock"> {
  let Representation = "Value";
}
// A bit width, count, or index; an operand of this sort matches a constant.
def SortNat : Sort<"Nat"> {
  let Representation = "Integer";
}
// Whether a flag is present, or an i1 operand.
def SortBoolean : Sort<"i1"> {
  let Representation = "Boolean";
  let Description = "a boolean";
}
def SortInteger : Sort<"Integer"> {
  let Representation = "Integer";
  let Description = "an integer";
}
def SortString : Sort<"String"> {
  let Representation = "String";
  let Description = "a string";
}
def SortCmpPredicate : Sort<"CmpPredicate"> {
  let Representation = "String";
}
def SortIntrinsicID : Sort<"Intrinsic::ID"> {
  let Representation = "String";
}
def SortType : Sort<"Type"> {
  let Representation = "Type";
  let Description = "a type";
}
def SortBitVector : Sort<"BitVector"> {
  let Representation = "BitVector";
  let Description = "a bit vector";
}
def SortTypeArray : Sort<"Type[]"> {
  let Representation = "TypeArray";
  let Description = "a type array";
}
def SortValueArray : Sort<"Value[]"> {
  let Representation = "ValueArray";
  let Description = "a value array";
}
def SortStringArray : Sort<"String[]"> {
  let Representation = "StringArray";
  let Description = "a string array";
}

def : Subsort<SortInstruction, SortValue>;
def : Subsort<SortFunction, SortValue>;
def : Subsort<SortValue, SortOperand>;
def : Subsort<SortBoolean, SortNat>;
def : Subsort<SortNat, SortOperand>;
def : Subsort<SortNat, SortInteger>;
def : Subsort<SortCmpPredicate, SortString>;
def : Subsort<SortIntrinsicID, SortString>;
