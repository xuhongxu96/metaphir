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

#endif // METAPHIR_DIALECT_PATTERN_PATTERNBASE_TD
