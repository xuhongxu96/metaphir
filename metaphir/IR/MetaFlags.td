//===- MetaFlags.td - The built-in metaflags --------------------*- tablegen -*-===//
//
// ':c', ':o', ':or' and ':not'. The others are defined by `metaflag`
// definitions in a pattern. Generated into MetaFlag.inc by metaphir-tblgen
// -gen-metaflags.
//
//===----------------------------------------------------------------------===//

/// A built-in metaflag. The record is named MF_<Spelling>. Nestable, unless
/// StructuralMetaFlag.
class MetaFlag<string spelling> {
  /// The flag's spelling, as in ':c'.
  string Spelling = spelling;
  /// Where the flag may be written: InstructionPlacement, OperandPlacement or
  /// AnyPlacement.
  string Placement;
  int MinArguments;
  /// The most arguments the flag takes, or -1 for any number.
  int MaxArguments;
  /// What the arguments are: AnyArgument, IntegerArgument or FlagArgument.
  string Arguments;
  /// Whether the flag changes how the instruction itself is matched, rather
  /// than adding a condition on it. Structural flags are not lowered to
  /// constraints.
  bit Structural = 0;
  /// Whether the flag may be an argument of another metaflag.
  bit Nestable = 1;
}

/// A flag that changes how the instruction itself is matched. It is not
/// nestable, as it is not a condition that another metaflag could combine.
class StructuralMetaFlag<string spelling> : MetaFlag<spelling> {
  let Structural = 1;
  let Nestable = 0;
}

// A structural flag (':c', ':o') changes how the instruction itself is matched
// rather than adding a condition on it, so desugaring keeps it as it is, and
// another metaflag cannot nest it.
def MF_c : StructuralMetaFlag<"c"> {
  let Placement = "InstructionPlacement";
  let MinArguments = 0;
  let MaxArguments = 0;
  let Arguments = "AnyArgument";
}
def MF_o : StructuralMetaFlag<"o"> {
  let Placement = "InstructionPlacement";
  let MinArguments = 0;
  let MaxArguments = 1;
  let Arguments = "IntegerArgument";
}
def MF_or : MetaFlag<"or"> {
  let Placement = "OperandPlacement";
  let MinArguments = 1;
  let MaxArguments = -1;
  let Arguments = "FlagArgument";
}
def MF_not : MetaFlag<"not"> {
  let Placement = "OperandPlacement";
  let MinArguments = 1;
  let MaxArguments = 1;
  let Arguments = "FlagArgument";
}
