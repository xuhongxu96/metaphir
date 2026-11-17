//===- LLVMValueClasses.td - The LLVM value classes `isa` can test -*- tablegen -*-===//
//
// The ordinal of a class is persisted: the corpus index records it, and its
// feature schema lists the classes in this order. A class is recorded unless
// nearly every value at a site is of it. Generated into LLVMValueClasses.inc
// by metaphir-tblgen -gen-value-classes.
//
//===----------------------------------------------------------------------===//

include "metaphir/IR/LanguageBase.td"

def : LLVMValueClass<"Value", 0>;
def : LLVMValueClass<"User", 0>;
def : LLVMValueClass<"Constant">;
def : LLVMValueClass<"ConstantInt">;
def : LLVMValueClass<"ConstantFP">;
def : LLVMValueClass<"PoisonValue">;
def : LLVMValueClass<"UndefValue">;
def : LLVMValueClass<"GlobalValue">;
def : LLVMValueClass<"Function">;
def : LLVMValueClass<"BasicBlock">;
def : LLVMValueClass<"Instruction", 0>;
def : LLVMValueClass<"CastInst">;
def : LLVMValueClass<"TruncInst">;
def : LLVMValueClass<"ZExtInst">;
def : LLVMValueClass<"SExtInst">;
def : LLVMValueClass<"BinaryOperator">;
def : LLVMValueClass<"CallInst">;
def : LLVMValueClass<"PHINode">;
def : LLVMValueClass<"CmpInst">;
def : LLVMValueClass<"ICmpInst">;
def : LLVMValueClass<"FCmpInst">;
def : LLVMValueClass<"SelectInst">;
def : LLVMValueClass<"LoadInst">;
def : LLVMValueClass<"StoreInst">;
def : LLVMValueClass<"GetElementPtrInst">;
