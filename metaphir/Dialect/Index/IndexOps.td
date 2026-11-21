//===- IndexOps.td - The mpir_index dialect ----------------*- tablegen -*-===//
//
// Index queries: what a function's features (see Features.h) must have for a
// pattern to match it, and how the corpus index finds the functions that
// have them.
//
// A query holds one mpir_index.variant per way a match can go (per choice of
// an alternative of each mpir.alt). A variant requires features: posted ones
// (instructions, edges, siblings, globals), which the corpus index has
// posting lists of, and detail ones (shapes, facts at sites), which it reads
// from each function it checks. It types the instruction matchers it matches
// (mpir_index.typing), and assumes its constraints, which are evaluated on
// the features with the pattern's values read as the sites they occupy.
//
//===----------------------------------------------------------------------===//

#ifndef METAPHIR_DIALECT_INDEX_INDEXOPS_TD
#define METAPHIR_DIALECT_INDEX_INDEXOPS_TD

include "mlir/IR/AttrTypeBase.td"
include "mlir/IR/OpBase.td"
include "mlir/Interfaces/SideEffectInterfaces.td"
include "metaphir/Dialect/Pattern/PatternBase.td"

def Index_Dialect : Dialect {
  let name = "mpir_index";
  let summary = "MetaphIR index queries";
  let cppNamespace = "::llvm::metaphir::mpir_index";
  let dependentDialects = ["::llvm::metaphir::mpir::PatternDialect"];
  let useDefaultTypePrinterParser = 1;
}

class Index_Op<string mnemonic, list<Trait> traits = []>
    : Op<Index_Dialect, mnemonic, traits>;

def Index_QueryOp : Index_Op<"query", [IsolatedFromAbove, SingleBlock,
                                       NoTerminator]> {
  let summary = "The index query of one pattern: any of its variants";
  let regions = (region SizedRegion<1>:$body);
  let assemblyFormat = "attr-dict-with-keyword $body";
}

def Index_VariantOp : Index_Op<"variant", [HasParent<"QueryOp">, SingleBlock,
                                           NoTerminator]> {
  let summary = "What a function needs for one way of matching";
  let description = [{
    With `impossible`, a constraint of the variant is false whatever a match
    binds: the variant matches nothing.
  }];
  let arguments = (ins UnitAttr:$impossible);
  let regions = (region SizedRegion<1>:$body);
  let assemblyFormat = "prop-dict attr-dict-with-keyword $body";
}

//===----------------------------------------------------------------------===//
// Posted features: the posting keys, whose lists find the functions
//===----------------------------------------------------------------------===//

def Index_HasInstructionOp : Index_Op<"has_instruction"> {
  let summary = "Some instruction matches the instruction matcher";
  // What the constraints, not the instructions, need: a function without it
  // may still match the variant's instructions.
  let arguments = (ins Mpir_OpcodeAttr:$opcode, UnitAttr:$derived);
  let assemblyFormat = "$opcode prop-dict attr-dict";
}

def Index_HasEdgeOp : Index_Op<"has_edge"> {
  let summary = "An instruction the first matcher matches has an operand the second matches";
  let arguments = (ins Mpir_OpcodeAttr:$user, Mpir_OpcodeAttr:$operand);
  let assemblyFormat = "$user `->` $operand attr-dict";
}

def Index_HasSiblingOp : Index_Op<"has_sibling"> {
  let summary = "Instructions the two matchers match use the same value";
  let arguments = (ins Mpir_OpcodeAttr:$first, Mpir_OpcodeAttr:$second);
  let assemblyFormat = "$first `,` $second attr-dict";
}

def Index_HasGlobalOp : Index_Op<"has_global"> {
  let summary = "Some instruction has the global (an intrinsic, for 'llvm.*') as an operand";
  // What the constraints, not the instructions, need, as for has_instruction.
  let arguments = (ins StrAttr:$name, UnitAttr:$derived);
  let assemblyFormat = "$name prop-dict attr-dict";
}

//===----------------------------------------------------------------------===//
// Detail features: read from each function the lists found
//===----------------------------------------------------------------------===//

def Index_HasShapeOp : Index_Op<"has_shape"> {
  let summary = "Some instruction the matcher matches has the flags and width";
  let description = [{
    `present` and `absent` are masks of semantic flags; `width`, unless 0, the
    bit width of the result's integers.
  }];
  let arguments = (ins Mpir_OpcodeAttr:$opcode, I32Attr:$present,
                       I32Attr:$absent, I32Attr:$width);
  let assemblyFormat = "$opcode `,` $present `,` $absent `,` $width attr-dict";
}

def Index_HasFactOp : Index_Op<"has_fact"> {
  let summary = "Some slot of a site has a fact (see Facts.h)";
  let arguments = (ins I64Attr:$node, Mpir_OpcodeAttr:$opcode, I32Attr:$slots,
                       I32Attr:$atom);
  let assemblyFormat = "$node `,` $opcode `,` $slots `,` $atom attr-dict";
}

//===----------------------------------------------------------------------===//
// Types and constraints
//===----------------------------------------------------------------------===//

def Index_TypingOp : Index_Op<"typing"> {
  let summary = "An instruction matcher the variant matches, to type by its signatures";
  let description = [{
    Its flags, as for has_shape; with `commutative`, its operands may be
    swapped. `operand_types[i]` is the type pattern (as mpir_plan.check_type
    encodes it, with type variables numbered by mpir_index.type_var) of the
    i-th unkeyed operand, or an empty array; `value_operand[i]` whether that
    operand is one of the instruction's value operands.
  }];
  let arguments = (ins Mpir_OpcodeAttr:$opcode, I32Attr:$present,
                       I32Attr:$absent, UnitAttr:$commutative,
                       UnitAttr:$treat_int_as_vec, ArrayAttr:$operand_types,
                       DenseBoolArrayAttr:$value_operand);
  let assemblyFormat = "$opcode prop-dict attr-dict";
}

def Index_SitesOp : Index_Op<"sites", [Pure]> {
  let summary = "A pattern value as the sites it occupies in every match";
  let description = [{
    Each site is [node, opcode, slots]: the instruction matcher numbered node
    (of the variant's typings and facts), and the slots (operand slots, or
    ResultSlot for the instruction itself) the value is in.
  }];
  let arguments = (ins ArrayAttr:$sites);
  let results = (outs Mpir_Term:$result);
  let assemblyFormat = "$sites attr-dict `:` type($result)";
}

def Index_TypeVarOp : Index_Op<"type_var", [Pure]> {
  let summary = "A meta variable the typings bind";
  let arguments = (ins I32Attr:$slot);
  let results = (outs Mpir_Term:$result);
  let assemblyFormat = "$slot attr-dict `:` type($result)";
}

def Index_NodeOp : Index_Op<"node", [Pure]> {
  let summary = "An instruction matcher the variant matches, as a value-tracking context";
  let arguments = (ins I64Attr:$node);
  let results = (outs Mpir_Term:$result);
  let assemblyFormat = "$node attr-dict `:` type($result)";
}

def Index_UnknownOp : Index_Op<"unknown", [Pure]> {
  let summary = "A pattern value about which the features say nothing";
  let results = (outs Mpir_Term:$result);
  let assemblyFormat = "attr-dict `:` type($result)";
}

def Index_AssumeOp : Index_Op<"assume"> {
  let summary = "A constraint that must not be false on the features";
  // A closed constraint evaluates alike in every match, so it can be checked
  // on the query alone.
  let arguments = (ins Mpir_Term:$condition, UnitAttr:$closed);
  let assemblyFormat = "$condition prop-dict attr-dict `:` type($condition)";
}

//===----------------------------------------------------------------------===//
// Retrieval: which functions to check, from the posting lists
//===----------------------------------------------------------------------===//

def Index_SetType : TypeDef<Index_Dialect, "Set"> {
  let mnemonic = "set";
  let summary = "A set of functions of the corpus";
}

def Index_RetrieveOp : Index_Op<"retrieve", [HasParent<"QueryOp">,
                                             SingleBlock, NoTerminator]> {
  let summary = "The functions that may match, from the posting lists";
  let description = [{
    The region computes a superset of the functions some variant may match,
    which mpir_index.result names. Where an intersection reads lists, the
    executor may read only the shortest few: a superset still.
  }];
  let regions = (region SizedRegion<1>:$body);
  let assemblyFormat = "attr-dict-with-keyword $body";
}

def Index_PostingsOp : Index_Op<"postings", [Pure]> {
  let summary = "The functions with a posted feature";
  let description = [{
    `kind` is a PostingKey's kind (0 instruction, 1 edge, 2 sibling, 3
    global) and `key` its value: the instruction matcher, the edge or sibling
    key, or (for a global) its name.
  }];
  let arguments = (ins I32Attr:$kind, AnyAttr:$key);
  let results = (outs Index_SetType:$result);
  let assemblyFormat = "$kind `,` $key attr-dict";
}

def Index_IntersectOp : Index_Op<"intersect", [Pure]> {
  let arguments = (ins Variadic<Index_SetType>:$sets);
  let results = (outs Index_SetType:$result);
  let assemblyFormat = "$sets attr-dict";
}

def Index_UnionOp : Index_Op<"union", [Pure]> {
  let arguments = (ins Variadic<Index_SetType>:$sets);
  let results = (outs Index_SetType:$result);
  let assemblyFormat = "$sets attr-dict";
}

def Index_UniverseOp : Index_Op<"universe", [Pure]> {
  let summary = "Every function: no posting list narrows them down";
  let results = (outs Index_SetType:$result);
  let assemblyFormat = "attr-dict";
}

def Index_ResultOp : Index_Op<"result", [HasParent<"RetrieveOp">]> {
  let arguments = (ins Index_SetType:$set);
  let assemblyFormat = "$set attr-dict";
}

#endif // METAPHIR_DIALECT_INDEX_INDEXOPS_TD
