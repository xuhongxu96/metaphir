//===- MetaFlags.td - The built-in metaflags --------------------*- tablegen -*-===//
//
// ':c', ':o', ':or' and ':not'. The others are defined by `metaflag`
// definitions in a pattern. Generated into MetaFlag.inc by metaphir-tblgen
// -gen-metaflags.
//
//===----------------------------------------------------------------------===//

include "metaphir/IR/LanguageBase.td"

// Nestable: whether the flag may appear as an argument of another metaflag.
// ':c' and ':o' are not: they change how the instruction itself is matched,
// not a condition on it that another flag could combine.
def MF_c : MetaFlag<"c", "InstructionPlacement", 0, 0, "AnyArgument", 0>;
def MF_o : MetaFlag<"o", "InstructionPlacement", 0, 1, "IntegerArgument", 0>;
def MF_or : MetaFlag<"or", "OperandPlacement", 1, -1, "FlagArgument", 1>;
def MF_not : MetaFlag<"not", "OperandPlacement", 1, 1, "FlagArgument", 1>;
