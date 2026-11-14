//===- PatternOps.td - The mpir dialect --------------------*- tablegen -*-===//
//
// Patterns as MLIR: what the parser emits (the surface form), and what the
// lowering passes make of it (the lowered form).
//
// Everything a pattern names is an SSA value whose type is its sort: meta
// variables (mpir.var), instruction matchers (mpir.inst), constants and type
// patterns. A meta variable is a logic variable: passing it to an operation
// unifies it with what the operation matches there.
//
//===----------------------------------------------------------------------===//

#ifndef METAPHIR_DIALECT_PATTERN_PATTERNOPS_TD
#define METAPHIR_DIALECT_PATTERN_PATTERNOPS_TD

include "mlir/IR/AttrTypeBase.td"
include "mlir/IR/OpBase.td"
include "mlir/IR/RegionKindInterface.td"
include "mlir/IR/SymbolInterfaces.td"
include "mlir/IR/OpAsmInterface.td"
include "mlir/Interfaces/SideEffectInterfaces.td"

def Pattern_Dialect : Dialect {
  let name = "mpir";
  let summary = "MetaphIR patterns";
  let cppNamespace = "::llvm::metaphir::mpir";
  let useDefaultTypePrinterParser = 1;
  let useDefaultAttributePrinterParser = 1;
}

//===----------------------------------------------------------------------===//
// Types and attributes
//===----------------------------------------------------------------------===//

def Mpir_SortType : TypeDef<Pattern_Dialect, "Sort"> {
  let mnemonic = "sort";
  let summary = "The sort of a pattern value (see Sorts.def)";
  let parameters = (ins "::llvm::metaphir::Sort":$sort);
  let hasCustomAssemblyFormat = 1;
}

def Mpir_Term : Type<CPred<"::llvm::isa<::llvm::metaphir::mpir::SortType>($_self)">,
                     "pattern value", "::llvm::metaphir::mpir::SortType">;

def Mpir_OpcodeAttr : AttrDef<Pattern_Dialect, "Opcode"> {
  let mnemonic = "opcode";
  let summary = "A built-in instruction matcher (see InstructionMatchers.def)";
  let parameters =
      (ins "::llvm::metaphir::Instruction::InstructionID":$value);
  let hasCustomAssemblyFormat = 1;
}

class Mpir_Op<string mnemonic, list<Trait> traits = []>
    : Op<Pattern_Dialect, mnemonic, traits>;

//===----------------------------------------------------------------------===//
// Containers
//===----------------------------------------------------------------------===//

def Mpir_PatternOp : Mpir_Op<"pattern", [IsolatedFromAbove]
                             # GraphRegionNoTerminator.traits> {
  let summary = "A pattern: instruction matchers and the constraints on them";
  let regions = (region SizedRegion<1>:$body);
  let assemblyFormat = "attr-dict-with-keyword $body";
}

def Mpir_MatcherOp : Mpir_Op<"matcher", [Symbol, SymbolName, SymbolVisibility, IsolatedFromAbove]
                             # GraphRegionNoTerminator.traits> {
  let summary = "A 'match' definition: a matcher that matches any branch";
  let description = [{
    The region holds the type patterns that parameters written as concrete
    types fix, and one mpir.branch per branch. `param_names` and
    `param_is_type` describe the parameters in the order of the archetype
    (see OperandSyntax); a fixed-type parameter has an empty name.
  }];
  let arguments = (ins SymbolNameAttr:$sym_name,
                       OptionalAttr<StrAttr>:$sym_visibility,
                       UnitAttr:$commutative,
                       DenseI32ArrayAttr:$supported_flags,
                       I32Attr:$syntax,
                       I32Attr:$arity,
                       StrArrayAttr:$param_names,
                       DenseBoolArrayAttr:$param_is_type);
  let regions = (region SizedRegion<1>:$body);
}

def Mpir_BranchOp : Mpir_Op<"branch", [HasParent<"MatcherOp">, SingleBlock,
                                       NoTerminator,
                                       DeclareOpInterfaceMethods<RegionKindInterface>]> {
  let summary = "A branch of a matcher";
  let description = [{
    The block has an argument for each distinct parameter name;
    `param_args[i]` is the argument of parameter i, or -1 for a parameter that
    fixes a type, whose type pattern is `fixed_types[k]` for the k-th such
    parameter. `fixed_flags` are the semantic flags the branch fixes, to
    `fixed_flag_values`. The body yields the instruction the matcher stands
    for.
  }];
  let arguments = (ins Variadic<Mpir_Term>:$fixed_types,
                       DenseI32ArrayAttr:$param_args,
                       DenseI32ArrayAttr:$fixed_flags,
                       DenseBoolArrayAttr:$fixed_flag_values);
  let regions = (region SizedRegion<1>:$body);
}

def Mpir_ConstraintDefOp : Mpir_Op<"constraint_def", [Symbol, SymbolName, SymbolVisibility, IsolatedFromAbove,
                                                      SingleBlock, NoTerminator]> {
  let summary = "A 'constraint' definition; its body yields the result";
  let arguments = (ins SymbolNameAttr:$sym_name,
                       OptionalAttr<StrAttr>:$sym_visibility, StrArrayAttr:$param_names);
  let regions = (region SizedRegion<1>:$body);
}

def Mpir_MetaFlagDefOp : Mpir_Op<"metaflag_def", [Symbol, SymbolName, SymbolVisibility, IsolatedFromAbove,
                                                  SingleBlock, NoTerminator]> {
  let summary = "A 'metaflag' definition; its first parameter is the subject";
  let arguments = (ins SymbolNameAttr:$sym_name,
                       OptionalAttr<StrAttr>:$sym_visibility, StrArrayAttr:$param_names,
                       I32Attr:$placement);
  let regions = (region SizedRegion<1>:$body);
}

def Mpir_YieldOp : Mpir_Op<"yield", []> {
  let summary = "The value a branch, an alternative or a definition stands for";
  let arguments = (ins Mpir_Term:$value);
  let assemblyFormat = "$value attr-dict `:` type($value)";
}

//===----------------------------------------------------------------------===//
// Values
//===----------------------------------------------------------------------===//

def Mpir_VarOp : Mpir_Op<"var", [Pure,
    DeclareOpInterfaceMethods<OpAsmOpInterface, ["getAsmResultNames"]>]> {
  let summary = "A meta variable, '?name'";
  let arguments = (ins StrAttr:$name);
  let results = (outs Mpir_Term:$result);
  let assemblyFormat = "$name attr-dict `:` type($result)";
}

def Mpir_IntOp : Mpir_Op<"int", [Pure]> {
  let summary = "An integer literal; signed if written negative";
  let arguments = (ins APIntAttr:$value);
  let results = (outs Mpir_Term:$result);
}

def Mpir_FloatOp : Mpir_Op<"float", [Pure]> {
  let summary = "A floating-point literal";
  let arguments = (ins AnyAttr:$value);
  let results = (outs Mpir_Term:$result);
}

def Mpir_KeywordOp : Mpir_Op<"keyword", [Pure]> {
  let summary = "A keyword constant ('null', 'poison') or compare predicate";
  let arguments = (ins I32Attr:$keyword);
  let results = (outs Mpir_Term:$result);
}

def Mpir_GlobalOp : Mpir_Op<"global", [Pure]> {
  let summary = "A global named '@name'; 'llvm.*' names an intrinsic";
  let arguments = (ins StrAttr:$name);
  let results = (outs Mpir_Term:$result);
  let assemblyFormat = "$name attr-dict `:` type($result)";
}

def Mpir_AggregateOp : Mpir_Op<"aggregate", [Pure]> {
  let summary = "An array, struct or vector constant of typed elements";
  let description = [{ Operands alternate: a type, then its element. }];
  let arguments = (ins I32Attr:$delimiter, Variadic<Mpir_Term>:$elements);
  let results = (outs Mpir_Term:$result);
}

//===----------------------------------------------------------------------===//
// Type patterns
//===----------------------------------------------------------------------===//

def Mpir_IntTypeOp : Mpir_Op<"type.int", [Pure]> {
  let summary = "'iN', or 'bN' when byte";
  let arguments = (ins I32Attr:$width, UnitAttr:$byte);
  let results = (outs Mpir_Term:$result);
}

def Mpir_MetaIntTypeOp : Mpir_Op<"type.meta_int", [Pure]> {
  let summary = "'i?n' (or 'b?n'): an integer type of the width ?n is bound to";
  let arguments = (ins Mpir_Term:$width, UnitAttr:$byte);
  let results = (outs Mpir_Term:$result);
}

def Mpir_PrimTypeOp : Mpir_Op<"type.prim", [Pure]> {
  let summary = "A primitive type (see Types.def)";
  let arguments = (ins I32Attr:$kind);
  let results = (outs Mpir_Term:$result);
}

def Mpir_PtrTypeOp : Mpir_Op<"type.ptr", [Pure]> {
  let summary = "'ptr', 'ptr addrspace(N)', or a typed pointer 'T*'";
  let arguments = (ins Optional<Mpir_Term>:$element,
                       OptionalAttr<I32Attr>:$address_space);
  let results = (outs Mpir_Term:$result);
}

def Mpir_SeqTypeOp : Mpir_Op<"type.seq", [Pure]> {
  let summary = "'[N x T]', '<N x T>' or '<vscale x N x T>'";
  let description = [{
    `kind` is 0 for an array, 1 for a vector and 2 for a scalable vector. The
    element count is `count`, or the meta variable `count_var`.
  }];
  let arguments = (ins I32Attr:$kind, I64Attr:$count, Mpir_Term:$element,
                       Optional<Mpir_Term>:$count_var);
  let results = (outs Mpir_Term:$result);
}

def Mpir_StructTypeOp : Mpir_Op<"type.struct", [Pure]> {
  let summary = "'{T, ...}', or '<{T, ...}>' when packed";
  let arguments = (ins Variadic<Mpir_Term>:$elements, UnitAttr:$packed);
  let results = (outs Mpir_Term:$result);
}

def Mpir_FuncTypeOp : Mpir_Op<"type.func", [Pure]> {
  let summary = "'R (P, ...)'";
  let arguments = (ins Mpir_Term:$return_type, Variadic<Mpir_Term>:$params,
                       UnitAttr:$var_arg);
  let results = (outs Mpir_Term:$result);
}

//===----------------------------------------------------------------------===//
// Instruction matchers
//===----------------------------------------------------------------------===//

// What a built-in instruction matcher and a use of a 'match' matcher share:
// both are written, and stored, the same way.
class Mpir_MatcherUseBase {
  dag commonArguments = (ins
      OptionalAttr<StrAttr>:$name,
      // The semantic flags written, and for each how (see FlagMode); a
      // captured flag takes the next of flag_captures.
      DenseI32ArrayAttr:$flags,
      DenseI32ArrayAttr:$flag_modes,
      // The matcher operands, by kind (see OperandKind); each takes the next
      // one or two of operand_values.
      DenseI32ArrayAttr:$operand_kinds,
      // ':c': the two commutable operands may match in either order.
      UnitAttr:$commutative,
      // ':o(N)': the N-th value operand may match in place of the instruction.
      OptionalAttr<I64Attr>:$or_self,
      // Lowered form only: the predicate is matched against the swapped one.
      UnitAttr:$swapped_predicate,
      // The treatIntAsVec setting, if one was written before the instruction.
      OptionalAttr<BoolAttr>:$treat_int_as_vec,
      Optional<Mpir_Term>:$capture,
      Optional<Mpir_Term>:$block,
      Variadic<Mpir_Term>:$flag_captures,
      Variadic<Mpir_Term>:$operand_values);
}

def Mpir_InstOp : Mpir_Op<"inst", [AttrSizedOperandSegments,
    DeclareOpInterfaceMethods<OpAsmOpInterface, ["getAsmResultNames"]>]>,
    Mpir_MatcherUseBase {
  let summary = "A built-in instruction matcher";
  let arguments = !con((ins Mpir_OpcodeAttr:$opcode), commonArguments);
  let results = (outs Mpir_Term:$result);
  let hasVerifier = 1;
}

def Mpir_UseOp : Mpir_Op<"use", [AttrSizedOperandSegments,
    DeclareOpInterfaceMethods<SymbolUserOpInterface>,
    DeclareOpInterfaceMethods<OpAsmOpInterface, ["getAsmResultNames"]>]>,
    Mpir_MatcherUseBase {
  let summary = "A use of a 'match' matcher; lowered to mpir.alt";
  let arguments = !con((ins FlatSymbolRefAttr:$matcher), commonArguments);
  let results = (outs Mpir_Term:$result);
  let hasVerifier = 1;
}

def Mpir_AltOp : Mpir_Op<"alt", [NoTerminator,
                                 DeclareOpInterfaceMethods<RegionKindInterface>]> {
  let summary = "A value that matches any one of its alternatives";
  let description = [{
    Each region yields what the alternative matches. Regions refer to the
    values around them, so the alternatives share everything else the
    pattern matches.
  }];
  let results = (outs Mpir_Term:$result);
  let regions = (region VariadicRegion<SizedRegion<1>>:$alternatives);
}

//===----------------------------------------------------------------------===//
// Metaflags and constraints
//===----------------------------------------------------------------------===//

def Mpir_FlagOp : Mpir_Op<"flag", [Pure,
    DeclareOpInterfaceMethods<SymbolUserOpInterface>]> {
  let summary = "A defined metaflag applied to a subject: whether it holds";
  let arguments = (ins FlatSymbolRefAttr:$flag, Mpir_Term:$subject,
                       DenseI64ArrayAttr:$args);
  let results = (outs Mpir_Term:$result);
}

def Mpir_AttachOp : Mpir_Op<"attach", []> {
  let summary = "Requires a metaflag expression written on an instruction";
  let description = [{
    `condition` is what the metaflags written at one place say: mpir.flag
    operations, combined by ':or' and ':not'. `operand` is the matcher operand
    they were written on, or -1 for the instruction itself. Value tracking in
    the flags' bodies is anchored at `instruction`.
  }];
  let arguments = (ins Mpir_Term:$condition, Mpir_Term:$instruction,
                       I32Attr:$operand);
}

def Mpir_RequireOp : Mpir_Op<"require", []> {
  let summary = "A constraint a match must satisfy";
  let arguments = (ins Mpir_Term:$condition);
  let assemblyFormat = "$condition attr-dict `:` type($condition)";
}

#endif // METAPHIR_DIALECT_PATTERN_PATTERNOPS_TD
