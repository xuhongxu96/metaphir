//===- ConstraintCoercions.td - Directed value coercions ------*- tablegen -*-===//
//
// The coercions of a constraint value from one representation to another.
// Each name is both a sort and a kind of ConstraintValue; the conversion
// itself is hand-written in ConstraintCoercion.cpp as coerce<Op>.
//
//===----------------------------------------------------------------------===//

include "metaphir/IR/LanguageBase.td"

def : Coercion<"Boolean", "Integer", "BooleanToInteger">;
def : Coercion<"Integer", "Boolean", "IntegerToBoolean">;
def : Coercion<"Value", "Integer", "ValueToInteger">;
def : Coercion<"Type", "String", "TypeToString">;
def : Coercion<"Value", "String", "ValueToString">;
def : Coercion<"TypeArray", "StringArray", "TypeArrayToStringArray">;
def : Coercion<"ValueArray", "StringArray", "ValueArrayToStringArray">;
