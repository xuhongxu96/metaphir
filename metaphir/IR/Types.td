//===- Types.td - The primitive types --------------------------*- tablegen -*-===//
//
// The primitive types a pattern can name. Generated into Types.inc by
// metaphir-tblgen -gen-primitive-types.
//
//===----------------------------------------------------------------------===//

include "metaphir/IR/LanguageBase.td"

def HalfTyID : PrimitiveType<"half", "isHalfTy", "16-bit floating point type">;
def BFloatTyID
    : PrimitiveType<"bfloat", "isBFloatTy",
                    "16-bit floating point type (7-bit significand)">;
def FloatTyID : PrimitiveType<"float", "isFloatTy", "32-bit floating point type">;
def DoubleTyID
    : PrimitiveType<"double", "isDoubleTy", "64-bit floating point type">;
def FP128TyID
    : PrimitiveType<"fp128", "isFP128Ty",
                    "128-bit floating point type (112-bit significand)">;
def VoidTyID : PrimitiveType<"void", "isVoidTy", "type with no size">;
def LabelTyID : PrimitiveType<"label", "isLabelTy", "Labels">;
