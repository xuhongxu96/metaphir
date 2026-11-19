//===- PlanOps.td - The mpir_plan dialect ------------------*- tablegen -*-===//
//
// Match plans: what matching a lowered pattern against a function does, step
// by step, as pdl_interp is for PDL. A plan is a sequence of steps run in
// order on a path. A guard step ends the path when it fails; a choice step
// (foreach_instruction, either) runs the rest of the path once for each of
// its choices. Steps bind the pattern's slots -- its meta variables and its
// instruction matchers -- and a path that reaches emit is a match.
//
// Registers (!mpir_plan.reg) hold what a step finds in the IR: a value, a
// type, a flag, a predicate, an array of operands.
//
//===----------------------------------------------------------------------===//

#ifndef METAPHIR_DIALECT_PLAN_PLANOPS_TD
#define METAPHIR_DIALECT_PLAN_PLANOPS_TD

include "mlir/IR/AttrTypeBase.td"
include "mlir/IR/OpBase.td"
include "mlir/Interfaces/SideEffectInterfaces.td"
include "metaphir/Dialect/Pattern/PatternBase.td"
include "metaphir/Dialect/Plan/PlanEnums.td"

def Plan_Dialect : Dialect {
  let name = "mpir_plan";
  let summary = "MetaphIR match plans";
  let cppNamespace = "::llvm::metaphir::mpir_plan";
  let useDefaultTypePrinterParser = 1;
  let dependentDialects = ["::llvm::metaphir::mpir::PatternDialect"];
}

def Plan_RegType : TypeDef<Plan_Dialect, "Reg"> {
  let mnemonic = "reg";
  let summary = "What a step found in the IR";
}

class Plan_Op<string mnemonic, list<Trait> traits = []>
    : Op<Plan_Dialect, mnemonic, traits>;

//===----------------------------------------------------------------------===//
// The plan
//===----------------------------------------------------------------------===//

def Plan_MatcherOp : Plan_Op<"matcher", [IsolatedFromAbove, SingleBlock,
                                         NoTerminator]> {
  let summary = "The plan of one pattern";
  let description = [{
    Slot i is a meta variable or an instruction matcher of the pattern:
    `slot_names[i]` its name, `slot_kinds[i]` whether it is a meta
    variable or an instruction matcher, `slot_sorts[i]` the variable's sort, and
    `slot_locs[i]` where it was written (for an instruction inlined from a
    matcher, where the use is).
  }];
  let arguments = (ins StrArrayAttr:$slot_names,
                       ArrayProp<EnumProp<Plan_SlotKind>>:$slot_kinds,
                       ArrayProp<Mpir_SortProp>:$slot_sorts,
                       ArrayAttr:$slot_locs);
  let regions = (region SizedRegion<1>:$body);
  let assemblyFormat = "prop-dict attr-dict-with-keyword $body";
}

def Plan_YieldOp : Plan_Op<"yield", [Terminator]> {
  let summary = "Ends an alternative of mpir_plan.either with its results";
  let arguments = (ins Variadic<Plan_RegType>:$values);
  let assemblyFormat = "($values^ `:` type($values))? attr-dict";
}

//===----------------------------------------------------------------------===//
// Choices
//===----------------------------------------------------------------------===//

def Plan_ForeachInstructionOp : Plan_Op<"foreach_instruction"> {
  let summary = "Each instruction of the function, in turn";
  let results = (outs Plan_RegType:$instruction);
  let assemblyFormat = "attr-dict";
}

def Plan_EitherOp : Plan_Op<"either", [RecursiveMemoryEffects]> {
  let summary = "Each alternative, in turn, then the rest of the path";
  let results = (outs Variadic<Plan_RegType>:$results);
  let regions = (region VariadicRegion<SizedRegion<1>>:$alternatives);
  let assemblyFormat = "$alternatives attr-dict (`:` type($results)^)?";
}

//===----------------------------------------------------------------------===//
// Reading the IR
//===----------------------------------------------------------------------===//

def Plan_GetOperandOp : Plan_Op<"get_operand", [Pure]> {
  let summary = "A matcher operand of an instruction (see collectMatcherOperands)";
  let arguments = (ins Plan_RegType:$instruction, I32Attr:$index);
  let results = (outs Plan_RegType:$result);
  let assemblyFormat = "$instruction `[` $index `]` attr-dict";
}

def Plan_GetOperandsFromOp : Plan_Op<"get_operands_from", [Pure]> {
  let summary = "The matcher operands from index on, or their types";
  let arguments = (ins Plan_RegType:$instruction, I32Attr:$index,
                       UnitAttr:$types);
  let results = (outs Plan_RegType:$result);
  let assemblyFormat = "$instruction `[` $index `:` `]` prop-dict attr-dict";
}

def Plan_GetTypeOp : Plan_Op<"get_type", [Pure]> {
  let summary = "The type of a value, or what a type-only operand is matched against";
  let description = [{
    Without `operand_of`, the type of the value. With it, the type an
    instruction's type-only operand is matched against: an alloca's
    allocated type, a getelementptr's source element type, or else the
    result's type.
  }];
  let arguments = (ins Plan_RegType:$value, UnitAttr:$operand_of);
  let results = (outs Plan_RegType:$result);
  let assemblyFormat = "$value prop-dict attr-dict";
}

def Plan_GetParentBlockOp : Plan_Op<"get_parent_block", [Pure]> {
  let arguments = (ins Plan_RegType:$instruction);
  let results = (outs Plan_RegType:$result);
  let assemblyFormat = "$instruction attr-dict";
}

def Plan_GetFlagOp : Plan_Op<"get_flag", [Pure]> {
  let summary = "Whether an instruction carries a semantic flag";
  let arguments = (ins Plan_RegType:$instruction, Mpir_FlagProp:$flag);
  let results = (outs Plan_RegType:$result);
  let assemblyFormat = "$instruction `[` $flag `]` attr-dict";
}

def Plan_GetKeyedOp : Plan_Op<"get_keyed", [Pure]> {
  let summary = "A keyed operand: a predicate, an alignment, an address space";
  let description = [{
    `kind` is an OperandKind. An absent inrange bound is no value.
  }];
  let arguments = (ins Plan_RegType:$instruction, EnumProp<Mpir_OperandKind>:$kind);
  let results = (outs Plan_RegType:$result);
  let assemblyFormat = "$instruction `[` $kind `]` prop-dict attr-dict";
}

def Plan_GetElementOp : Plan_Op<"get_element", [Pure]> {
  let summary = "An element of an aggregate constant";
  let arguments = (ins Plan_RegType:$aggregate, I32Attr:$index);
  let results = (outs Plan_RegType:$result);
  let assemblyFormat = "$aggregate `[` $index `]` attr-dict";
}

//===----------------------------------------------------------------------===//
// Guards
//===----------------------------------------------------------------------===//

def Plan_CheckOpcodeOp : Plan_Op<"check_opcode"> {
  let summary = "The value is an instruction the instruction matcher accepts";
  let arguments = (ins Plan_RegType:$value, Mpir_OpcodeAttr:$opcode);
  let assemblyFormat = "$value `,` $opcode prop-dict attr-dict";
}

def Plan_CheckFlagOp : Plan_Op<"check_flag"> {
  let summary = "The instruction carries the flag, or does not";
  let arguments = (ins Plan_RegType:$instruction, Mpir_FlagProp:$flag,
                       BoolAttr:$present);
  let assemblyFormat = "$instruction `[` $flag `]` `is` $present attr-dict";
}

def Plan_CheckOperandCountOp : Plan_Op<"check_operand_count"> {
  let summary = "The instruction has count matcher operands (at least, if so)";
  let arguments = (ins Plan_RegType:$instruction, I32Attr:$count,
                       UnitAttr:$at_least);
  let assemblyFormat = "$instruction `,` $count prop-dict attr-dict";
}

def Plan_CheckTypeOp : Plan_Op<"check_type"> {
  let summary = "The type matches a type pattern, binding its variables";
  let description = [{
    `pattern` encodes the type pattern (see PlanDialect.h), whose variables
    are slots. With `treat_int_as_vec`, an integer type pattern also matches
    a vector of such integers.
  }];
  let arguments = (ins Plan_RegType:$ir_type, ArrayAttr:$pattern,
                       UnitAttr:$treat_int_as_vec);
  let assemblyFormat = "$ir_type `,` $pattern prop-dict attr-dict";
}

def Plan_CheckConstantOp : Plan_Op<"check_constant"> {
  let summary = "The value is the constant a pattern names";
  let description = [{
    `constant` is an integer (IntegerAttr, whose signedness is the
    literal's), a floating-point number (FloatAttr), a keyword constant
    (KeywordConstant's ID, as `keyword`), or a global's name (StringAttr;
    'llvm.*' names an intrinsic by its base name). A predicate keyword is
    compared with a register holding a predicate. With `treat_int_as_vec`,
    an integer also matches a vector splat of it.
  }];
  let arguments = (ins Plan_RegType:$value, AnyAttr:$constant,
                       UnitAttr:$keyword, UnitAttr:$treat_int_as_vec);
  let assemblyFormat = "$value `,` $constant prop-dict attr-dict";
}

def Plan_CheckAggregateOp : Plan_Op<"check_aggregate"> {
  let summary = "The value is an aggregate constant of the kind and size";
  let arguments = (ins Plan_RegType:$value, Mpir_DelimiterProp:$delimiter, I32Attr:$count);
  let assemblyFormat = "$value `,` $delimiter `,` $count attr-dict";
}

def Plan_CheckBoundOp : Plan_Op<"check_bound"> {
  let summary = "The slot is bound, or is not";
  let arguments = (ins I32Attr:$slot, BoolAttr:$bound);
  let assemblyFormat = "$slot `is` $bound attr-dict";
}

def Plan_BindOp : Plan_Op<"bind"> {
  let summary = "Unifies a slot with what a register holds";
  let description = [{
    With `sort`, a meta variable of that sort is bound: the register is read
    as the sort reads IR values (a Nat from an integer constant, an
    intrinsic's ID from a function, ...), and the path ends if it cannot be.
    Without, the register is bound as it is, as an instruction matcher is.
  }];
  let arguments = (ins Plan_RegType:$value, I32Attr:$slot,
                       OptionalAttr<I32Attr>:$sort);
  let assemblyFormat = "$value `->` $slot prop-dict attr-dict";
}

def Plan_BindConstantOp : Plan_Op<"bind_constant"> {
  let summary = "Unifies a slot with a constant flag";
  let arguments = (ins I32Attr:$slot, BoolAttr:$value);
  let assemblyFormat = "$value `->` $slot attr-dict";
}

def Plan_CheckOp : Plan_Op<"check"> {
  let summary = "A constraint the match must satisfy";
  let description = [{
    The condition is an mpir_expr expression over mpir_plan.slot values.
    `from_metaflag` marks a constraint a metaflag stands for, which is
    checked before the others when constraints are deferred to the end of a
    path.
  }];
  let arguments = (ins Mpir_Term:$condition, UnitAttr:$from_metaflag);
  let assemblyFormat = "$condition prop-dict attr-dict `:` type($condition)";
}

def Plan_LetOp : Plan_Op<"let"> {
  let summary = "Binds a slot to an expression, or checks it is the one it has";
  let description = [{
    A 'let': the match binds `slot` to the value of `value`, an mpir_expr
    expression over mpir_plan.slot values, if the slot is not bound yet.
    Otherwise it must hold that `condition`, which compares the slot with
    `value`, is true.
  }];
  let arguments = (ins I32Attr:$slot, Mpir_Term:$value, Mpir_Term:$condition);
  let assemblyFormat =
      "$slot `,` $value `,` $condition attr-dict `:` type($value) `,` type($condition)";
}

def Plan_SlotOp : Plan_Op<"slot", [Pure]> {
  let summary = "A slot's binding, as an expression reads it";
  let arguments = (ins I32Attr:$slot);
  let results = (outs Mpir_Term:$result);
  let assemblyFormat = "$slot attr-dict `:` type($result)";
}

def Plan_EmitOp : Plan_Op<"emit"> {
  let summary = "The path is a match";
  let assemblyFormat = "attr-dict";
}

#endif // METAPHIR_DIALECT_PLAN_PLANOPS_TD
