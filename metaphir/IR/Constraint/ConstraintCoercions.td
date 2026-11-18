//===- ConstraintCoercions.td - Directed value coercions ------*- tablegen -*-===//
//
// The coercions of a constraint value from one representation to another.
// Each name is both a sort and a kind of ConstraintValue; the conversion
// itself is hand-written in ConstraintCoercion.cpp as coerce<Op>.
//
//===----------------------------------------------------------------------===//

/// A directed coercion of a constraint value. Src and Dst are both sort IDs
/// and kinds of ConstraintValue; the hand-written coerce<Op> does it.
class Coercion<string src, string dst> {
  string Src = src;
  string Dst = dst;
  string Op = !strconcat(Src, "To", Dst);
}

def : Coercion<"Boolean", "Integer">;
def : Coercion<"Integer", "Boolean">;
def : Coercion<"Value", "Integer">;
def : Coercion<"Type", "String">;
def : Coercion<"Value", "String">;
def : Coercion<"TypeArray", "StringArray">;
def : Coercion<"ValueArray", "StringArray">;
