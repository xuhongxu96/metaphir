//===- PatternBase.td - The mpir dialect's types and attributes -*- tablegen -*-===//
//
// What the mpir and mpir_expr dialects share: the dialect, the sorts of
// pattern values, and the attributes for instruction matchers and metaflags.
//
//===----------------------------------------------------------------------===//

#ifndef METAPHIR_DIALECT_PATTERN_PATTERNBASE_TD
#define METAPHIR_DIALECT_PATTERN_PATTERNBASE_TD

include "mlir/IR/AttrTypeBase.td"
include "mlir/IR/OpBase.td"
include "mlir/IR/EnumAttr.td"

def Pattern_Dialect : Dialect {
  let name = "mpir";
  let summary = "MetaphIR patterns";
  let cppNamespace = "::llvm::metaphir::mpir";
  let useDefaultTypePrinterParser = 1;
  let useDefaultAttributePrinterParser = 1;
}

//===----------------------------------------------------------------------===//
// Enumerations
//===----------------------------------------------------------------------===//

// How a semantic flag is written on an instruction matcher.
def Mpir_FlagMode : I32Enum<"FlagMode", "how a flag is written", [
  I32EnumAttrCase<"Required", 0, "required">,
  I32EnumAttrCase<"Negated", 1, "negated">,
  I32EnumAttrCase<"Captured", 2, "captured">,
]> {
  let cppNamespace = "::llvm::metaphir::mpir";
}

// The kinds of matcher operand, and how many of an instruction's
// operand_values each takes. The keyed kinds come last (see isKeyedOperand).
def Mpir_OperandKind : I32Enum<"OperandKind", "a kind of matcher operand", [
  // 'i32 ?x': a type pattern and a value.
  I32EnumAttrCase<"TypedValue", 0, "typed_value">,
  // A value whose type is not written: a phi's block, a callee, an index.
  I32EnumAttrCase<"Value", 1, "value">,
  // A bare type that is not an operand: a cast's destination, a load's
  // result type, 'ret void'.
  I32EnumAttrCase<"TypeOnly", 2, "type_only">,
  // '...?values': the remaining operands.
  I32EnumAttrCase<"ValueArray", 3, "value_array">,
  // '...?types ?values': the remaining operands and their types.
  I32EnumAttrCase<"TypedValueArray", 4, "typed_value_array">,
  // Keyed operands, each one value.
  I32EnumAttrCase<"Predicate", 5, "predicate">,
  I32EnumAttrCase<"Alignment", 6, "alignment">,
  I32EnumAttrCase<"AddressSpace", 7, "address_space">,
  I32EnumAttrCase<"InRangeLower", 8, "inrange_lower">,
  I32EnumAttrCase<"InRangeUpper", 9, "inrange_upper">,
]> {
  let cppNamespace = "::llvm::metaphir::mpir";
}

// A property that is an enumerator the tables define (see NamedEnum.h): it is
// written as its name, and stored as the enumerator.
class Mpir_NamedProp<string type, string summary> : Property<type, summary> {
  let predicate = CPred<"::llvm::metaphir::mpir::isEnumerator($_self)">;
  let parser = [{
    auto parsed = ::llvm::metaphir::mpir::parseEnumerator<}] # type # [{>($_parser);
    if (::mlir::failed(parsed))
      return ::mlir::failure();
    $_storage = *parsed;
  }];
  let printer = [{
    ::llvm::metaphir::mpir::printEnumerator($_printer, $_storage);
  }];
  let convertFromAttribute = [{
    auto intAttr = ::mlir::dyn_cast_if_present<::mlir::IntegerAttr>($_attr);
    if (!intAttr)
      return $_diag() << "expected IntegerAttr storage for }] # type # [{";
    $_storage = static_cast<}] # type # [{>(intAttr.getValue().getZExtValue());
    return ::mlir::success();
  }];
  let convertToAttribute = [{
    return ::mlir::IntegerAttr::get(::mlir::IntegerType::get($_ctxt, 32),
                                    static_cast<uint32_t>($_storage));
  }];
  let writeToMlirBytecode = [{
    $_writer.writeVarInt(static_cast<uint64_t>($_storage));
  }];
  let readFromMlirBytecode = [{
    uint64_t rawValue;
    if (::mlir::failed($_reader.readVarInt(rawValue)))
      return ::mlir::failure();
    $_storage = static_cast<}] # type # [{>(rawValue);
  }];
}

def Mpir_FlagProp : Mpir_NamedProp<"::llvm::metaphir::instruction_flag::FlagID", "a semantic flag">;
def Mpir_SortProp : Mpir_NamedProp<"::llvm::metaphir::Sort", "a sort">;
def Mpir_SyntaxProp : Mpir_NamedProp<"::llvm::metaphir::instruction::OperandSyntax", "an operand syntax">;
def Mpir_KeywordProp : Mpir_NamedProp<"::llvm::metaphir::keyword_constant::KeywordID", "a keyword constant">;
def Mpir_PrimTypeProp : Mpir_NamedProp<"::llvm::metaphir::primitive_type::TypeID", "a primitive type">;
def Mpir_DelimiterProp : Mpir_NamedProp<"::llvm::metaphir::aggregate_constant::Delimiter", "an aggregate kind">;
def Mpir_PlacementProp : Mpir_NamedProp<"::llvm::metaphir::metaflag::Placement", "where a metaflag may be written">;

// The kinds of sequence type pattern.
def Mpir_SeqKind : I32Enum<"SeqKind", "a kind of sequence type", [
  // '[N x T]'
  I32EnumAttrCase<"Array", 0, "array">,
  // '<N x T>'
  I32EnumAttrCase<"Vector", 1, "vector">,
  // '<vscale x N x T>'
  I32EnumAttrCase<"ScalableVector", 2, "scalable">,
]> {
  let cppNamespace = "::llvm::metaphir::mpir";
}

//===----------------------------------------------------------------------===//
// Types and attributes
//===----------------------------------------------------------------------===//

def Mpir_SortType : TypeDef<Pattern_Dialect, "Sort"> {
  let mnemonic = "sort";
  let summary = "The sort of a pattern value (see Sorts.td)";
  let parameters = (ins "::llvm::metaphir::Sort":$sort);
  let hasCustomAssemblyFormat = 1;
}

def Mpir_Term : Type<CPred<"::llvm::isa<::llvm::metaphir::mpir::SortType>($_self)">,
                     "pattern value", "::llvm::metaphir::mpir::SortType">;

def Mpir_OpcodeAttr : AttrDef<Pattern_Dialect, "Opcode"> {
  let mnemonic = "opcode";
  let summary = "A built-in instruction matcher (see InstructionMatchers.td)";
  let parameters =
      (ins "::llvm::metaphir::instruction::InstructionID":$value);
  let hasCustomAssemblyFormat = 1;
}

def Mpir_MetaFlagAttr : AttrDef<Pattern_Dialect, "MetaFlag"> {
  let mnemonic = "metaflag";
  let summary = "A metaflag as written: ':name', ':name(1, :other)'";
  let description = [{
    Arguments are integers (IntegerAttr) and nested metaflags. The surface
    form keeps metaflags as written; lowering turns them into constraints
    (or, for ':c' and ':o', into mpir.alt).
  }];
  let parameters = (ins "::mlir::StringAttr":$name, "::mlir::ArrayAttr":$args,
                        "::mlir::LocationAttr":$loc);
  let assemblyFormat = "`<` $name `,` $args `,` $loc `>`";
}

//===----------------------------------------------------------------------===//
// Type patterns
//===----------------------------------------------------------------------===//

def Mpir_TypePatternAttr : AttrInterface<"TypePatternAttr"> {
  let cppNamespace = "::llvm::metaphir::mpir";
  let description = [{
    A type pattern of a lowered pattern, as mpir_plan.check_type and
    mpir_index.typing match it against an LLVM type: each kind of pattern
    type is an attribute, and its meta variables are numbered by their slots
    (see Bindings.h).
  }];
}

class Mpir_TypePattern<string name, string mnemonicName>
    : AttrDef<Pattern_Dialect, name # "TypePattern", [Mpir_TypePatternAttr]> {
  let mnemonic = mnemonicName;
}

def Mpir_TypePatternParam
    : AttrParameter<"::llvm::metaphir::mpir::TypePatternAttr", "a type pattern">;
def Mpir_PrimTypeParam
    : AttrParameter<"::llvm::metaphir::primitive_type::TypeID",
                    "a primitive type"> {
  let parser = [{
    ::llvm::metaphir::mpir::parseEnumerator<
        ::llvm::metaphir::primitive_type::TypeID>($_parser)
  }];
  let printer = "::llvm::metaphir::mpir::printEnumerator($_printer, $_self)";
}

def Mpir_VarTypePattern : Mpir_TypePattern<"Var", "tp_var"> {
  let summary = "A type variable: '?t'";
  let parameters = (ins "unsigned":$slot);
  let assemblyFormat = "`<` $slot `>`";
}

def Mpir_PrimTypePattern : Mpir_TypePattern<"Prim", "tp_prim"> {
  let summary = "A primitive type (see Types.td)";
  let parameters = (ins Mpir_PrimTypeParam:$kind);
  let assemblyFormat = "`<` $kind `>`";
  let genVerifyDecl = 1;
}

def Mpir_IntTypePattern : Mpir_TypePattern<"Int", "tp_int"> {
  let summary = "An integer type: 'i32'";
  let parameters = (ins "unsigned":$width);
  let assemblyFormat = "`<` $width `>`";
}

def Mpir_ByteTypePattern : Mpir_TypePattern<"Byte", "tp_byte"> {
  let summary = "A byte type: 'b8'";
  let parameters = (ins "unsigned":$width);
  let assemblyFormat = "`<` $width `>`";
}

def Mpir_IntWidthTypePattern : Mpir_TypePattern<"IntWidth", "tp_int_width"> {
  let summary = "An integer type of a width variable: 'i?n'";
  let parameters = (ins "unsigned":$width_slot);
  let assemblyFormat = "`<` $width_slot `>`";
}

def Mpir_ByteWidthTypePattern
    : Mpir_TypePattern<"ByteWidth", "tp_byte_width"> {
  let summary = "A byte type of a width variable: 'b?n'";
  let parameters = (ins "unsigned":$width_slot);
  let assemblyFormat = "`<` $width_slot `>`";
}

def Mpir_PtrTypePattern : Mpir_TypePattern<"Ptr", "tp_ptr"> {
  let summary = "'ptr', 'ptr addrspace(N)', or a typed pointer 'T*'";
  let description = [{
    Without an address space, a pointer of any. A typed pointer, which has
    an element, matches no LLVM type.
  }];
  let parameters = (ins OptionalParameter<"std::optional<unsigned>">:$address_space,
                        OptionalParameter<"::llvm::metaphir::mpir::TypePatternAttr">:$element);
  let hasCustomAssemblyFormat = 1;
}

def Mpir_SeqTypePattern : Mpir_TypePattern<"Seq", "tp_seq"> {
  let summary = "An array or vector type: '[4 x T]', '<?n x T>'";
  let description = [{
    Its element count is either `count` or the count variable `count_slot`.
  }];
  let parameters = (ins EnumParameter<Mpir_SeqKind>:$kind,
                        OptionalParameter<"std::optional<uint64_t>">:$count,
                        OptionalParameter<"std::optional<unsigned>">:$count_slot,
                        Mpir_TypePatternParam:$element);
  let hasCustomAssemblyFormat = 1;
  let genVerifyDecl = 1;
}

def Mpir_StructTypePattern : Mpir_TypePattern<"Struct", "tp_struct"> {
  let summary = "A literal struct type: '{T, U}', '<{T, U}>'";
  let parameters = (ins "bool":$packed,
                        OptionalArrayRefParameter<"::llvm::metaphir::mpir::TypePatternAttr">:$elements);
  let hasCustomAssemblyFormat = 1;
}

def Mpir_FuncTypePattern : Mpir_TypePattern<"Func", "tp_func"> {
  let summary = "A function type: 'T (U, ...)'";
  let parameters = (ins Mpir_TypePatternParam:$return_type,
                        OptionalArrayRefParameter<"::llvm::metaphir::mpir::TypePatternAttr">:$params,
                        "bool":$var_arg);
  let hasCustomAssemblyFormat = 1;
}

#endif // METAPHIR_DIALECT_PATTERN_PATTERNBASE_TD
