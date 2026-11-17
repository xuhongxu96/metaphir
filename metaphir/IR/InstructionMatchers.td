//===- InstructionMatchers.td - The built-in instruction matchers ---------===//
//
// Each matcher's target instruction, supported flags and operand syntax.
// Generated into Instruction.inc and OpcodeMatchers.inc by metaphir-tblgen
// -gen-instructions and -gen-opcode-matchers.
//
// Operand syntax is how the parser spells the operands. Shared grammars:
//   Nary    select i1 ?c, i?n ?t, i?n ?f       (Arity typed operands)
//   Binary  add i?n ?a, ?b                     (typed, comma, value)
//   Cast    trunc i?n ?a to i?m                (typed, 'to', type)
//   Custom  all other grammars (call, load, phi, ...) get bespoke parser code
//
//===----------------------------------------------------------------------===//

include "metaphir/IR/Flags.td"

// The sets of flags the matchers support.
def NoFlags : FlagSet<[]>;
def FastMathFlags : FlagSet<[fast, nnan, ninf, nsz, arcp, contract, afn, reassoc]>;
def NSWNUWFlags : FlagSet<[nsw, nuw]>;
def ExactFlag : FlagSet<[exact]>;
def DisjointFlag : FlagSet<[disjoint]>;
def InAllocaFlag : FlagSet<[inalloca]>;
def VolatileFlag : FlagSet<[volatile]>;
def GEPFlags : FlagSet<[inbounds, nusw, nuw]>;
def NNegFlag : FlagSet<[nneg]>;
def SameSignFlag : FlagSet<[samesign]>;
def FastMathNNegFlags : FlagSet<[fast, nnan, ninf, nsz, arcp, contract, afn, reassoc, nneg]>;

def fneg : InstructionMatcher<"FNeg", FastMathFlags, 0, "Nary", 1>;
def add : InstructionMatcher<"Add", NSWNUWFlags, 1, "Binary", 2>;
def fadd : InstructionMatcher<"FAdd", FastMathFlags, 1, "Binary", 2>;
def sub : InstructionMatcher<"Sub", NSWNUWFlags, 0, "Binary", 2>;
def fsub : InstructionMatcher<"FSub", FastMathFlags, 0, "Binary", 2>;
def mul : InstructionMatcher<"Mul", NSWNUWFlags, 1, "Binary", 2>;
def fmul : InstructionMatcher<"FMul", FastMathFlags, 1, "Binary", 2>;
def udiv : InstructionMatcher<"UDiv", ExactFlag, 0, "Binary", 2>;
def sdiv : InstructionMatcher<"SDiv", ExactFlag, 0, "Binary", 2>;
def fdiv : InstructionMatcher<"FDiv", FastMathFlags, 0, "Binary", 2>;
def urem : InstructionMatcher<"URem", NoFlags, 0, "Binary", 2>;
def srem : InstructionMatcher<"SRem", NoFlags, 0, "Binary", 2>;
def frem : InstructionMatcher<"FRem", FastMathFlags, 0, "Binary", 2>;
def shl : InstructionMatcher<"Shl", NSWNUWFlags, 0, "Binary", 2>;
def lshr : InstructionMatcher<"LShr", ExactFlag, 0, "Binary", 2>;
def ashr : InstructionMatcher<"AShr", ExactFlag, 0, "Binary", 2>;
def and : InstructionMatcher<"And", NoFlags, 1, "Binary", 2>;
def or : InstructionMatcher<"Or", DisjointFlag, 1, "Binary", 2>;
def xor : InstructionMatcher<"Xor", NoFlags, 1, "Binary", 2>;
def extractelement : InstructionMatcher<"ExtractElement", NoFlags, 0, "Custom", 0>;
def insertelement : InstructionMatcher<"InsertElement", NoFlags, 0, "Nary", 3>;
def shufflevector : InstructionMatcher<"ShuffleVector", NoFlags, 0, "Nary", 3>;
def extractvalue : InstructionMatcher<"ExtractValue", NoFlags, 0, "Custom", 0>;
def insertvalue : InstructionMatcher<"InsertValue", NoFlags, 0, "Custom", 0>;
def alloca : InstructionMatcher<"Alloca", InAllocaFlag, 0, "Custom", 0>;
def load : InstructionMatcher<"Load", VolatileFlag, 0, "Custom", 0>;
def store : InstructionMatcher<"Store", VolatileFlag, 0, "Custom", 0>;
def getelementptr : InstructionMatcher<"GetElementPtr", GEPFlags, 0, "Custom", 0>;
def trunc : InstructionMatcher<"Trunc", NSWNUWFlags, 0, "Cast", 1>;
def zext : InstructionMatcher<"ZExt", NNegFlag, 0, "Cast", 1>;
def sext : InstructionMatcher<"SExt", NoFlags, 0, "Cast", 1>;
def fptrunc : InstructionMatcher<"FPTrunc", FastMathFlags, 0, "Cast", 1>;
def fpext : InstructionMatcher<"FPExt", FastMathFlags, 0, "Cast", 1>;
def fptoui : InstructionMatcher<"FPToUI", NoFlags, 0, "Cast", 1>;
def fptosi : InstructionMatcher<"FPToSI", NoFlags, 0, "Cast", 1>;
def uitofp : InstructionMatcher<"UIToFP", FastMathNNegFlags, 0, "Cast", 1>;
def sitofp : InstructionMatcher<"SIToFP", FastMathFlags, 0, "Cast", 1>;
def ptrtoint : InstructionMatcher<"PtrToInt", NoFlags, 0, "Cast", 1>;
def ptrtoaddr : InstructionMatcher<"PtrToAddr", NoFlags, 0, "Cast", 1>;
def inttoptr : InstructionMatcher<"IntToPtr", NoFlags, 0, "Cast", 1>;
def bitcast : InstructionMatcher<"BitCast", NoFlags, 0, "Cast", 1>;
def ret : InstructionMatcher<"Ret", NoFlags, 0, "Custom", 0>;
def br : InstructionMatcher<"", NoFlags, 0, "Custom", 0,
    "isa<CondBrInst, UncondBrInst>(Target)">;
def icmp : InstructionMatcher<"ICmp", SameSignFlag, 1, "Custom", 0>;
def fcmp : InstructionMatcher<"FCmp", FastMathFlags, 1, "Custom", 0>;
def phi : InstructionMatcher<"PHI", FastMathFlags, 0, "Custom", 0>;
def select : InstructionMatcher<"Select", FastMathFlags, 0, "Nary", 3>;
def freeze : InstructionMatcher<"Freeze", NoFlags, 0, "Nary", 1>;
def call : InstructionMatcher<"Call", NoFlags, 1, "Custom", 0>;
