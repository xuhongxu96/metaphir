//===- Sorts.td - Sorts of meta variables and constraints -*- tablegen -*-===//
//
// One sort system classifies both meta variables and constraint expressions.
// A meta variable's sort is the meet of the sorts its occurrences require;
// a constraint expression's sort is checked against operator signatures.
// Generated into Sort.inc by metaphir-tblgen -gen-sorts.
//
//===----------------------------------------------------------------------===//

include "metaphir/IR/LanguageBase.td"

// Not yet inferred; a top element below which every sort lies.
def SortUnknown : Sort<"Unknown", "Unknown", "Unknown", "any value">;
// What an operand position accepts. A meta variable that occurs only as an
// operand denotes a value (see resolveSort).
def SortOperand : Sort<"Operand", "Operand", "Value">;
def SortValue : Sort<"Value", "Value", "Value", "a value">;
def SortInstruction : Sort<"Instruction", "Instruction", "Value">;
def SortFunction : Sort<"Function", "Function", "Value">;
// A block is not an operand of a first-class type, so it lies outside
// Operand; constraints still read it as a value.
def SortBasicBlock : Sort<"BasicBlock", "BasicBlock", "Value">;
// A bit width, count, or index; an operand of this sort matches a constant.
def SortNat : Sort<"Nat", "Nat", "Integer">;
// Whether a flag is present, or an i1 operand.
def SortBoolean : Sort<"Boolean", "i1", "Boolean", "a boolean">;
def SortInteger : Sort<"Integer", "Integer", "Integer", "an integer">;
def SortString : Sort<"String", "String", "String", "a string">;
def SortCmpPredicate : Sort<"CmpPredicate", "CmpPredicate", "String">;
def SortIntrinsicID : Sort<"IntrinsicID", "Intrinsic::ID", "String">;
def SortType : Sort<"Type", "Type", "Type", "a type">;
def SortBitVector : Sort<"BitVector", "BitVector", "BitVector", "a bit vector">;
def SortTypeArray : Sort<"TypeArray", "Type[]", "TypeArray", "a type array">;
def SortValueArray : Sort<"ValueArray", "Value[]", "ValueArray", "a value array">;
def SortStringArray : Sort<"StringArray", "String[]", "StringArray", "a string array">;

def : Subsort<SortInstruction, SortValue>;
def : Subsort<SortFunction, SortValue>;
def : Subsort<SortValue, SortOperand>;
def : Subsort<SortBoolean, SortNat>;
def : Subsort<SortNat, SortOperand>;
def : Subsort<SortNat, SortInteger>;
def : Subsort<SortCmpPredicate, SortString>;
def : Subsort<SortIntrinsicID, SortString>;
