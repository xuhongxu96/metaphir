//===- MetaFlags.td - The built-in metaflags --------------------*- tablegen -*-===//
//
// ':c', ':o', ':or' and ':not'. The others are defined by `metaflag`
// definitions in a pattern. Generated into MetaFlag.inc by metaphir-tblgen
// -gen-metaflags.
//
//===----------------------------------------------------------------------===//

include "metaphir/IR/LanguageBase.td"

// A structural flag (':c', ':o') changes how the instruction itself is matched
// rather than adding a condition on it, so desugaring keeps it as it is, and
// another metaflag cannot nest it.
def MF_c : StructuralMetaFlag<"c", "InstructionPlacement", 0, 0, "AnyArgument">;
def MF_o
    : StructuralMetaFlag<"o", "InstructionPlacement", 0, 1, "IntegerArgument">;
def MF_or : MetaFlag<"or", "OperandPlacement", 1, -1, "FlagArgument">;
def MF_not : MetaFlag<"not", "OperandPlacement", 1, 1, "FlagArgument">;
