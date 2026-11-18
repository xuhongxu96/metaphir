//===- Types.td - The primitive types --------------------------*- tablegen -*-===//
//
// The primitive types a pattern can name. Generated into Types.inc by
// metaphir-tblgen -gen-primitive-types.
//
//===----------------------------------------------------------------------===//

/// A primitive type a pattern can name ('half', 'float', 'void', 'label', ...).
/// The others (integers, pointers, aggregates, vectors, functions and meta
/// types) are ops of the mpir dialect. The record's name is the enumerator of
/// primitive_type::TypeID.
class PrimitiveType<string spelling> {
  /// How a pattern spells the type, which is also its keyword.
  string Spelling = spelling;
  /// The llvm::Type member that tests whether a type is this one.
  string TypeCheck;
  string Summary;
}

def HalfTyID : PrimitiveType<"half"> {
  let TypeCheck = "isHalfTy";
  let Summary = "16-bit floating point type";
}
def BFloatTyID : PrimitiveType<"bfloat"> {
  let TypeCheck = "isBFloatTy";
  let Summary = "16-bit floating point type (7-bit significand)";
}
def FloatTyID : PrimitiveType<"float"> {
  let TypeCheck = "isFloatTy";
  let Summary = "32-bit floating point type";
}
def DoubleTyID : PrimitiveType<"double"> {
  let TypeCheck = "isDoubleTy";
  let Summary = "64-bit floating point type";
}
def FP128TyID : PrimitiveType<"fp128"> {
  let TypeCheck = "isFP128Ty";
  let Summary = "128-bit floating point type (112-bit significand)";
}
def VoidTyID : PrimitiveType<"void"> {
  let TypeCheck = "isVoidTy";
  let Summary = "type with no size";
}
def LabelTyID : PrimitiveType<"label"> {
  let TypeCheck = "isLabelTy";
  let Summary = "Labels";
}
