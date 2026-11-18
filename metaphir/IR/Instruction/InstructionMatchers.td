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

include "metaphir/IR/Instruction/Flags.td"

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

def fneg : NaryInstruction {
  let Opcode = "FNeg";
  let SupportedFlags = FastMathFlags;
  let Arity = 1;
}
def add : BinaryInstruction {
  let Opcode = "Add";
  let SupportedFlags = NSWNUWFlags;
  let Commutative = 1;
}
def fadd : BinaryInstruction {
  let Opcode = "FAdd";
  let SupportedFlags = FastMathFlags;
  let Commutative = 1;
}
def sub : BinaryInstruction {
  let Opcode = "Sub";
  let SupportedFlags = NSWNUWFlags;
}
def fsub : BinaryInstruction {
  let Opcode = "FSub";
  let SupportedFlags = FastMathFlags;
}
def mul : BinaryInstruction {
  let Opcode = "Mul";
  let SupportedFlags = NSWNUWFlags;
  let Commutative = 1;
}
def fmul : BinaryInstruction {
  let Opcode = "FMul";
  let SupportedFlags = FastMathFlags;
  let Commutative = 1;
}
def udiv : BinaryInstruction {
  let Opcode = "UDiv";
  let SupportedFlags = ExactFlag;
}
def sdiv : BinaryInstruction {
  let Opcode = "SDiv";
  let SupportedFlags = ExactFlag;
}
def fdiv : BinaryInstruction {
  let Opcode = "FDiv";
  let SupportedFlags = FastMathFlags;
}
def urem : BinaryInstruction {
  let Opcode = "URem";
  let SupportedFlags = NoFlags;
}
def srem : BinaryInstruction {
  let Opcode = "SRem";
  let SupportedFlags = NoFlags;
}
def frem : BinaryInstruction {
  let Opcode = "FRem";
  let SupportedFlags = FastMathFlags;
}
def shl : BinaryInstruction {
  let Opcode = "Shl";
  let SupportedFlags = NSWNUWFlags;
}
def lshr : BinaryInstruction {
  let Opcode = "LShr";
  let SupportedFlags = ExactFlag;
}
def ashr : BinaryInstruction {
  let Opcode = "AShr";
  let SupportedFlags = ExactFlag;
}
def and : BinaryInstruction {
  let Opcode = "And";
  let SupportedFlags = NoFlags;
  let Commutative = 1;
}
def or : BinaryInstruction {
  let Opcode = "Or";
  let SupportedFlags = DisjointFlag;
  let Commutative = 1;
}
def xor : BinaryInstruction {
  let Opcode = "Xor";
  let SupportedFlags = NoFlags;
  let Commutative = 1;
}
def extractelement : CustomInstruction {
  let Opcode = "ExtractElement";
  let SupportedFlags = NoFlags;
}
def insertelement : NaryInstruction {
  let Opcode = "InsertElement";
  let SupportedFlags = NoFlags;
  let Arity = 3;
}
def shufflevector : NaryInstruction {
  let Opcode = "ShuffleVector";
  let SupportedFlags = NoFlags;
  let Arity = 3;
}
def extractvalue : CustomInstruction {
  let Opcode = "ExtractValue";
  let SupportedFlags = NoFlags;
}
def insertvalue : CustomInstruction {
  let Opcode = "InsertValue";
  let SupportedFlags = NoFlags;
}
def alloca : CustomInstruction {
  let Opcode = "Alloca";
  let SupportedFlags = InAllocaFlag;
}
def load : CustomInstruction {
  let Opcode = "Load";
  let SupportedFlags = VolatileFlag;
}
def store : CustomInstruction {
  let Opcode = "Store";
  let SupportedFlags = VolatileFlag;
}
def getelementptr : CustomInstruction {
  let Opcode = "GetElementPtr";
  let SupportedFlags = GEPFlags;
}
def trunc : CastInstruction {
  let Opcode = "Trunc";
  let SupportedFlags = NSWNUWFlags;
}
def zext : CastInstruction {
  let Opcode = "ZExt";
  let SupportedFlags = NNegFlag;
}
def sext : CastInstruction {
  let Opcode = "SExt";
  let SupportedFlags = NoFlags;
}
def fptrunc : CastInstruction {
  let Opcode = "FPTrunc";
  let SupportedFlags = FastMathFlags;
}
def fpext : CastInstruction {
  let Opcode = "FPExt";
  let SupportedFlags = FastMathFlags;
}
def fptoui : CastInstruction {
  let Opcode = "FPToUI";
  let SupportedFlags = NoFlags;
}
def fptosi : CastInstruction {
  let Opcode = "FPToSI";
  let SupportedFlags = NoFlags;
}
def uitofp : CastInstruction {
  let Opcode = "UIToFP";
  let SupportedFlags = FastMathNNegFlags;
}
def sitofp : CastInstruction {
  let Opcode = "SIToFP";
  let SupportedFlags = FastMathFlags;
}
def ptrtoint : CastInstruction {
  let Opcode = "PtrToInt";
  let SupportedFlags = NoFlags;
}
def ptrtoaddr : CastInstruction {
  let Opcode = "PtrToAddr";
  let SupportedFlags = NoFlags;
}
def inttoptr : CastInstruction {
  let Opcode = "IntToPtr";
  let SupportedFlags = NoFlags;
}
def bitcast : CastInstruction {
  let Opcode = "BitCast";
  let SupportedFlags = NoFlags;
}
def ret : CustomInstruction {
  let Opcode = "Ret";
  let SupportedFlags = NoFlags;
}
def br : CustomInstruction {
  let SupportedFlags = NoFlags;
  let TargetCheck = "isa<CondBrInst, UncondBrInst>(Target)";
}
def icmp : CustomInstruction {
  let Opcode = "ICmp";
  let SupportedFlags = SameSignFlag;
  let Commutative = 1;
}
def fcmp : CustomInstruction {
  let Opcode = "FCmp";
  let SupportedFlags = FastMathFlags;
  let Commutative = 1;
}
def phi : CustomInstruction {
  let Opcode = "PHI";
  let SupportedFlags = FastMathFlags;
}
def select : NaryInstruction {
  let Opcode = "Select";
  let SupportedFlags = FastMathFlags;
  let Arity = 3;
}
def freeze : NaryInstruction {
  let Opcode = "Freeze";
  let SupportedFlags = NoFlags;
  let Arity = 1;
}
def call : CustomInstruction {
  let Opcode = "Call";
  let SupportedFlags = NoFlags;
  let Commutative = 1;
}
