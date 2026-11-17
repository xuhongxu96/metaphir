//===- Flags.td - The semantic flags of instruction matchers --*- tablegen -*-===//
//
// The flags an instruction matcher can name ('nsw', 'nnan', ...). Generated
// into Instruction.inc by metaphir-tblgen -gen-instructions.
//
//===----------------------------------------------------------------------===//

include "metaphir/IR/LanguageBase.td"

def nsw : Flag;
def nuw : Flag;
def exact : Flag;
def disjoint : Flag;
def inalloca : Flag;
def volatile : Flag;
def inbounds : Flag;
def nusw : Flag;
def nneg : Flag;
def samesign : Flag;
def fast : FastMathFlag;
def nnan : FastMathFlag;
def ninf : FastMathFlag;
def nsz : FastMathFlag;
def arcp : FastMathFlag;
def contract : FastMathFlag;
def afn : FastMathFlag;
def reassoc : FastMathFlag;
