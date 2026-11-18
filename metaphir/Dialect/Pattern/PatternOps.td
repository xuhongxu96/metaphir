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

include "mlir/IR/RegionKindInterface.td"
include "mlir/IR/SymbolInterfaces.td"
include "mlir/IR/OpAsmInterface.td"
include "mlir/Interfaces/SideEffectInterfaces.td"

include "metaphir/Dialect/Pattern/PatternBase.td"

class Mpir_Op<string mnemonic, list<Trait> traits = []>
    : Op<Pattern_Dialect, mnemonic, traits>;

//===----------------------------------------------------------------------===//
// Containers
//===----------------------------------------------------------------------===//

def Mpir_PatternOp : Mpir_Op<"pattern", [IsolatedFromAbove]
                             # GraphRegionNoTerminator.traits> {
  let summary = "A pattern: instruction matchers and the constraints on them";
  let regions = (region SizedRegion<1>:$body);
  let assemblyFormat = "prop-dict attr-dict-with-keyword $body";
}

def Mpir_MatcherOp : Mpir_Op<"matcher", [Symbol, SymbolName, SymbolVisibility, IsolatedFromAbove]
                             # GraphRegionNoTerminator.traits> {
  let summary = "A 'match' definition: a matcher that matches any branch";
  let description = [{
    The region holds the type patterns of the parameters, an mpir.signature
    listing them, and one mpir.branch per branch. `param_names` and
    `param_is_type` describe the parameters in the order of the archetype
    (see OperandSyntax); a parameter written as a concrete type has an empty
    name.
  }];
  let arguments = (ins SymbolNameAttr:$sym_name,
                       OptionalAttr<StrAttr>:$sym_visibility,
                       UnitAttr:$commutative,
                       ArrayProp<Mpir_FlagProp>:$supported_flags,
                       Mpir_SyntaxProp:$syntax,
                       I32Attr:$arity,
                       StrArrayAttr:$param_names,
                       DenseBoolArrayAttr:$param_is_type);
  let regions = (region SizedRegion<1>:$body);
  let assemblyFormat = "$sym_name prop-dict attr-dict-with-keyword $body";
}

def Mpir_SignatureOp : Mpir_Op<"signature", [HasParent<"MatcherOp">]> {
  let summary = "The type patterns of a matcher's type parameters, in order";
  let arguments = (ins Variadic<Mpir_Term>:$types);
  let assemblyFormat = "($types^ `:` type($types))? attr-dict";
}

def Mpir_BranchOp : Mpir_Op<"branch", [HasParent<"MatcherOp">, SingleBlock,
                                       NoTerminator,
                                       DeclareOpInterfaceMethods<RegionKindInterface>]> {
  let summary = "A branch of a matcher";
  let description = [{
    The block has an argument for each distinct parameter name;
    `param_args[i]` is the argument of parameter i, or -1 for a parameter
    written as a concrete type. `fixed_flags` are the semantic flags the
    branch fixes, to `fixed_flag_values`. The body yields the instruction the
    matcher stands for.
  }];
  let arguments = (ins DenseI32ArrayAttr:$param_args,
                       ArrayProp<Mpir_FlagProp>:$fixed_flags,
                       DenseBoolArrayAttr:$fixed_flag_values);
  let regions = (region SizedRegion<1>:$body);
  let assemblyFormat = "prop-dict attr-dict-with-keyword $body";
}

def Mpir_ConstraintDefOp : Mpir_Op<"constraint_def", [Symbol, SymbolName, SymbolVisibility, IsolatedFromAbove,
                                                      SingleBlock, NoTerminator]> {
  let summary = "A 'constraint' definition; its body yields the result";
  let arguments = (ins SymbolNameAttr:$sym_name,
                       OptionalAttr<StrAttr>:$sym_visibility, StrArrayAttr:$param_names);
  let regions = (region SizedRegion<1>:$body);
  let assemblyFormat = "$sym_name prop-dict attr-dict-with-keyword $body";
}

def Mpir_MetaFlagDefOp : Mpir_Op<"metaflag_def", [Symbol, SymbolName, SymbolVisibility, IsolatedFromAbove,
                                                  SingleBlock, NoTerminator]> {
  let summary = "A 'metaflag' definition; its first parameter is the subject";
  let arguments = (ins SymbolNameAttr:$sym_name,
                       OptionalAttr<StrAttr>:$sym_visibility, StrArrayAttr:$param_names,
                       Mpir_PlacementProp:$placement);
  let regions = (region SizedRegion<1>:$body);
  let assemblyFormat = "$sym_name prop-dict attr-dict-with-keyword $body";
}

def Mpir_YieldOp : Mpir_Op<"yield", []> {
  let summary = "The value a branch, an alternative or a definition stands for";
  let arguments = (ins Mpir_Term:$value);
  let assemblyFormat = "$value attr-dict `:` type($value)";
}

//===----------------------------------------------------------------------===//
// Values
//===----------------------------------------------------------------------===//

// Not Pure: two variables of one name (local copies of a matcher's) are
// distinct, and must not be merged.
def Mpir_VarOp : Mpir_Op<"var", [
    DeclareOpInterfaceMethods<OpAsmOpInterface, ["getAsmResultNames"]>]> {
  let summary = "A meta variable, '?name'";
  let arguments = (ins StrAttr:$var_name);
  let results = (outs Mpir_Term:$result);
  let assemblyFormat = "$var_name attr-dict `:` type($result)";
}

def Mpir_IntOp : Mpir_Op<"int", [Pure]> {
  let summary = "An integer literal; signed if written negative";
  let arguments = (ins APIntAttr:$value);
  let results = (outs Mpir_Term:$result);
  let assemblyFormat = "$value attr-dict `:` type($result)";
}

def Mpir_FloatOp : Mpir_Op<"float", [Pure]> {
  let summary = "A floating-point literal";
  let arguments = (ins AnyAttr:$value);
  let results = (outs Mpir_Term:$result);
  // The value carries its own type, as '1.5 : f64'.
  let assemblyFormat = "$value attr-dict `->` type($result)";
}

def Mpir_KeywordOp : Mpir_Op<"keyword", [Pure]> {
  let summary = "A keyword constant ('null', 'poison') or compare predicate";
  let arguments = (ins Mpir_KeywordProp:$keyword);
  let results = (outs Mpir_Term:$result);
  let assemblyFormat = "$keyword attr-dict `:` type($result)";
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
  let arguments = (ins Mpir_DelimiterProp:$delimiter, Variadic<Mpir_Term>:$elements);
  let results = (outs Mpir_Term:$result);
  let assemblyFormat = "$delimiter `(` $elements `)` attr-dict `:` functional-type($elements, $result)";
}

//===----------------------------------------------------------------------===//
// Type patterns
//===----------------------------------------------------------------------===//

def Mpir_IntTypeOp : Mpir_Op<"type.int", [Pure]> {
  let summary = "'iN', or 'bN' when byte";
  let arguments = (ins I32Attr:$width, UnitAttr:$byte);
  let results = (outs Mpir_Term:$result);
  let assemblyFormat = "$width (`byte` $byte^)? attr-dict `:` type($result)";
}

def Mpir_MetaIntTypeOp : Mpir_Op<"type.meta_int", [Pure]> {
  let summary = "'i?n' (or 'b?n'): an integer type of the width ?n is bound to";
  let arguments = (ins Mpir_Term:$width, UnitAttr:$byte);
  let results = (outs Mpir_Term:$result);
  let assemblyFormat = "$width (`byte` $byte^)? attr-dict `:` functional-type($width, $result)";
}

def Mpir_PrimTypeOp : Mpir_Op<"type.prim", [Pure]> {
  let summary = "A primitive type (see Types.td)";
  let arguments = (ins Mpir_PrimTypeProp:$kind);
  let results = (outs Mpir_Term:$result);
  let assemblyFormat = "$kind attr-dict `:` type($result)";
}

def Mpir_PtrTypeOp : Mpir_Op<"type.ptr", [Pure]> {
  let summary = "'ptr', 'ptr addrspace(N)', or a typed pointer 'T*'";
  let arguments = (ins Optional<Mpir_Term>:$element,
                       OptionalAttr<I32Attr>:$address_space);
  let results = (outs Mpir_Term:$result);
  let assemblyFormat = "($element^)? (`addrspace` `(` $address_space^ `)`)? attr-dict `:` functional-type($element, $result)";
}

def Mpir_SeqTypeOp : Mpir_Op<"type.seq", [Pure]> {
  let summary = "'[N x T]', '<N x T>' or '<vscale x N x T>'";
  let description = [{
    `kind` says whether it is an array, a vector or a scalable vector. The
    element count is `count`, or the meta variable `count_var`.
  }];
  let arguments = (ins EnumProp<Mpir_SeqKind>:$kind, I64Attr:$count, Mpir_Term:$element,
                       Optional<Mpir_Term>:$count_var);
  let results = (outs Mpir_Term:$result);
  let assemblyFormat = "$kind $count `x` $element (`count` $count_var^)? attr-dict `:` functional-type(operands, $result)";
}

def Mpir_StructTypeOp : Mpir_Op<"type.struct", [Pure]> {
  let summary = "'{T, ...}', or '<{T, ...}>' when packed";
  let arguments = (ins Variadic<Mpir_Term>:$elements, UnitAttr:$packed);
  let results = (outs Mpir_Term:$result);
  let assemblyFormat = "(`packed` $packed^)? `{` $elements `}` attr-dict `:` functional-type($elements, $result)";
}

def Mpir_FuncTypeOp : Mpir_Op<"type.func", [Pure]> {
  let summary = "'R (P, ...)'";
  let arguments = (ins Mpir_Term:$return_type, Variadic<Mpir_Term>:$params,
                       UnitAttr:$var_arg);
  let results = (outs Mpir_Term:$result);
  let assemblyFormat = "$return_type `(` $params `)` (`vararg` $var_arg^)? attr-dict `:` functional-type(operands, $result)";
}

//===----------------------------------------------------------------------===//
// Instruction matchers
//===----------------------------------------------------------------------===//

// What mpir.inst and mpir.use have in common, for passes that treat them
// alike: the operations take the same arguments, so each method is an
// accessor the op generates.
def Mpir_MatcherOpInterface : OpInterface<"MatcherOpInterface"> {
  let cppNamespace = "::llvm::metaphir::mpir";
  let description = [{
    An instruction matcher: a built-in one (mpir.inst) or a use of a 'match'
    matcher (mpir.use).
  }];
  let methods = [
    InterfaceMethod<"The name the result is written with, if any",
                    "std::optional<::llvm::StringRef>", "getResultName">,
    InterfaceMethod<"The attribute holding the name, or null",
                    "::mlir::StringAttr", "getResultNameAttr">,
    InterfaceMethod<"The metaflags written on the instruction",
                    "std::optional<::mlir::ArrayAttr>", "getMetaflags">,
    InterfaceMethod<"The metaflags written on each operand",
                    "std::optional<::mlir::ArrayAttr>", "getOperandMetaflags">,
    InterfaceMethod<"Sets the metaflags written on the instruction",
                    "void", "setMetaflagsAttr", (ins "::mlir::ArrayAttr":$attr)>,
    InterfaceMethod<"Removes the metaflags written on the instruction",
                    "::mlir::Attribute", "removeMetaflagsAttr">,
    InterfaceMethod<"Removes the metaflags written on the operands",
                    "::mlir::Attribute", "removeOperandMetaflagsAttr">,
    InterfaceMethod<"The semantic flags written",
                    "::llvm::ArrayRef<::llvm::metaphir::instruction_flag::FlagID>",
                    "getFlags">,
    InterfaceMethod<"How each flag is written",
                    "::llvm::ArrayRef<::llvm::metaphir::mpir::FlagMode>",
                    "getFlagModes">,
    InterfaceMethod<"What the captured flags are captured into",
                    "::mlir::OperandRange", "getFlagCaptures">,
    InterfaceMethod<"The kind of each matcher operand",
                    "::llvm::ArrayRef<::llvm::metaphir::mpir::OperandKind>",
                    "getOperandKinds">,
    InterfaceMethod<"The treatIntAsVec setting written before the instruction",
                    "std::optional<bool>", "getTreatIntAsVec">,
    InterfaceMethod<"What the instruction is captured into, if anything",
                    "::mlir::Value", "getCapture">,
    InterfaceMethod<"The block the instruction is in, if one is named",
                    "::mlir::Value", "getParentBlock">,
    InterfaceMethod<"The values of the matcher operands, as OperandKind says",
                    "::mlir::OperandRange", "getOperandValues">,
    InterfaceMethod<"The instruction as a value", "::mlir::Value", "getResult">,
    InterfaceMethod<"Whether ':c' is written on the instruction", "bool",
                    "isCommutative">,
    InterfaceMethod<"The operand index ':o' names, if ':o' is written",
                    "std::optional<unsigned>", "getOrSelfIndex">,
  ];
}

// What a built-in instruction matcher and a use of a 'match' matcher share:
// both are written, and stored, the same way.
class Mpir_MatcherUseBase {
  dag commonArguments = (ins
      OptionalAttr<StrAttr>:$result_name,
      // The semantic flags written, and for each how (see FlagMode); a
      // captured flag takes the next of flag_captures.
      ArrayProp<Mpir_FlagProp>:$flags,
      ArrayProp<EnumProp<Mpir_FlagMode>>:$flag_modes,
      // The matcher operands, by kind (see OperandKind); each takes the next
      // one or two of operand_values.
      ArrayProp<EnumProp<Mpir_OperandKind>>:$operand_kinds,
      // Surface form: the metaflags written on the instruction, and on each
      // operand (an array per operand), as written.
      OptionalAttr<ArrayAttr>:$metaflags,
      OptionalAttr<ArrayAttr>:$operand_metaflags,
      // Lowered form only: the predicate is matched against the swapped one.
      UnitAttr:$swapped_predicate,
      // The treatIntAsVec setting, if one was written before the instruction.
      OptionalAttr<BoolAttr>:$treat_int_as_vec,
      Optional<Mpir_Term>:$capture,
      Optional<Mpir_Term>:$parent_block,
      Variadic<Mpir_Term>:$flag_captures,
      Variadic<Mpir_Term>:$operand_values);
}

def Mpir_InstOp : Mpir_Op<"inst", [AttrSizedOperandSegments, Mpir_MatcherOpInterface,
    DeclareOpInterfaceMethods<OpAsmOpInterface, ["getAsmResultNames"]>]>,
    Mpir_MatcherUseBase {
  let summary = "A built-in instruction matcher";
  let arguments = !con((ins Mpir_OpcodeAttr:$opcode), commonArguments);
  let results = (outs Mpir_Term:$result);
  let hasVerifier = 1;
  let extraClassDeclaration = [{
    /// Whether ':c' is written on the instruction.
    bool isCommutative();
    /// The operand index ':o' names, if ':o' is written.
    std::optional<unsigned> getOrSelfIndex();
  }];
  let assemblyFormat = "$opcode (`capture` $capture^)? (`block` $parent_block^)? (`flags` `(` $flag_captures^ `)`)? `(` $operand_values `)` prop-dict attr-dict `:` functional-type(operands, $result)";
}

def Mpir_UseOp : Mpir_Op<"use", [AttrSizedOperandSegments, Mpir_MatcherOpInterface,
    DeclareOpInterfaceMethods<SymbolUserOpInterface>,
    DeclareOpInterfaceMethods<OpAsmOpInterface, ["getAsmResultNames"]>]>,
    Mpir_MatcherUseBase {
  let summary = "A use of a 'match' matcher; lowered to mpir.alt";
  let arguments = !con((ins FlatSymbolRefAttr:$matcher), commonArguments);
  let results = (outs Mpir_Term:$result);
  let hasVerifier = 1;
  let extraClassDeclaration = [{
    bool isCommutative();
    std::optional<unsigned> getOrSelfIndex();
  }];
  let assemblyFormat = "$matcher (`capture` $capture^)? (`block` $parent_block^)? (`flags` `(` $flag_captures^ `)`)? `(` $operand_values `)` prop-dict attr-dict `:` functional-type(operands, $result)";
}

def Mpir_AltOp : Mpir_Op<"alt", [NoTerminator,
                                 DeclareOpInterfaceMethods<RegionKindInterface>]> {
  let summary = "A value that matches any one of its alternatives";
  let description = [{
    Each region yields what the alternative matches. Regions refer to the
    values around them, so the alternatives share everything else the
    pattern matches.
  }];
  let arguments = (ins
      // The name of the instruction or use the alternatives stand for.
      OptionalAttr<StrAttr>:$result_name,
      // The alternatives are the two operand orders of ':c'.
      UnitAttr:$commuted,
      // The alternatives are the matcher with ':o', and its operand: the
      // matcher's name, and the alternative that matches the operand.
      OptionalAttr<StrAttr>:$or_self_of,
      OptionalAttr<I32Attr>:$or_self_region);
  let results = (outs Mpir_Term:$result);
  let regions = (region VariadicRegion<SizedRegion<1>>:$alternatives);
  // The attributes have a keyword: an alternative-less mpir.alt (a use no
  // branch fits) would otherwise print them where its regions go.
  let assemblyFormat = "$alternatives prop-dict attr-dict-with-keyword `:` type($result)";
}

//===----------------------------------------------------------------------===//
// Constraints (expressions are in the mpir_expr dialect)
//===----------------------------------------------------------------------===//

def Mpir_BindOp : Mpir_Op<"bind", []> {
  let summary = "Unifies a meta variable with what a value matches";
  let description = [{
    Lowered form only: what an alternative binds besides its yielded value,
    such as a matcher branch's fixed flag ('[nsw = true]') or the capture of an
    instruction that ':o' lets match its operand instead.
  }];
  let arguments = (ins Mpir_Term:$variable, Mpir_Term:$value);
  let assemblyFormat = "$variable `,` $value attr-dict `:` type($variable) `,` type($value)";
}

def Mpir_RequireOp : Mpir_Op<"require", []> {
  let summary = "A constraint a match must satisfy";
  let arguments = (ins Mpir_Term:$condition,
                       // A metaflag stands for the constraint; it is checked
                       // before the pattern's own.
                       UnitAttr:$from_metaflag);
  let assemblyFormat = "$condition prop-dict attr-dict `:` type($condition)";
}

#endif // METAPHIR_DIALECT_PATTERN_PATTERNOPS_TD
