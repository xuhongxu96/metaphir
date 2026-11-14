//===- ExprOps.td - The mpir_expr dialect ------------------*- tablegen -*-===//
//
// Constraint expressions ('?x == 1 && isZero(?y)'), shared by every stage
// that reads constraints: the surface and lowered patterns, the index and the
// match plan.
//
// Expressions are pure and tree-shaped; an evaluator evaluates an operand only
// when it needs it, so '&&' and '||' short-circuit although their operands
// are SSA values. Pattern values (meta variables, instruction matchers) are
// read by mpir_expr.read, which fixes the sort they are read as.
//
//===----------------------------------------------------------------------===//

#ifndef METAPHIR_DIALECT_EXPR_EXPROPS_TD
#define METAPHIR_DIALECT_EXPR_EXPROPS_TD

include "mlir/IR/SymbolInterfaces.td"
include "mlir/Interfaces/SideEffectInterfaces.td"
include "metaphir/Dialect/Pattern/PatternBase.td"

def Expr_Dialect : Dialect {
  let name = "mpir_expr";
  let summary = "MetaphIR constraint expressions";
  let cppNamespace = "::llvm::metaphir::mpir_expr";
  let dependentDialects = ["::llvm::metaphir::mpir::PatternDialect"];
}

class Expr_Op<string mnemonic, list<Trait> traits = []>
    : Op<Expr_Dialect, mnemonic, !listconcat([Pure], traits)>;

def Expr_IntOp : Expr_Op<"int"> {
  let summary = "An integer literal";
  let description = [{
    Its type's signedness is the literal's: a non-negative literal is
    unsigned, a negative one signed, each at least 64 bits wide.
  }];
  let arguments = (ins APIntAttr:$value);
  let results = (outs Mpir_Term:$result);
  let assemblyFormat = "$value attr-dict `:` type($result)";
  let builders = [OpBuilder<(ins "const ::llvm::APSInt &":$value)>];
  let extraClassDeclaration = [{ ::llvm::APSInt getAPSInt(); }];
}

def Expr_BoolOp : Expr_Op<"bool"> {
  let summary = "'true' or 'false'";
  let arguments = (ins BoolAttr:$value);
  let results = (outs Mpir_Term:$result);
  let assemblyFormat = "$value attr-dict `:` type($result)";
  let builders = [OpBuilder<(ins "bool":$value)>];
}

def Expr_StrOp : Expr_Op<"str"> {
  let summary = "A string literal";
  let arguments = (ins StrAttr:$value);
  let results = (outs Mpir_Term:$result);
  let assemblyFormat = "$value attr-dict `:` type($result)";
  let builders = [OpBuilder<(ins "::llvm::StringRef":$value)>];
}

def Expr_ArrayOp : Expr_Op<"array"> {
  let summary = "An array literal of types, values or strings, '[a, b]'";
  let arguments = (ins Variadic<Mpir_Term>:$elements);
  let results = (outs Mpir_Term:$result);
  let assemblyFormat = "$elements attr-dict `:` functional-type($elements, $result)";
}

def Expr_IndexOp : Expr_Op<"index"> {
  let summary = "An element of an array, 'a[i]'";
  let arguments = (ins Mpir_Term:$array, Mpir_Term:$index);
  let results = (outs Mpir_Term:$result);
  let assemblyFormat = "$array `[` $index `]` attr-dict `:` functional-type(operands, $result)";
}

def Expr_ReadOp : Expr_Op<"read"> {
  let summary = "A pattern value, read as its result's sort";
  let arguments = (ins Mpir_Term:$value);
  let results = (outs Mpir_Term:$result);
  let assemblyFormat = "$value attr-dict `:` functional-type($value, $result)";
}

def Expr_CallOp : Expr_Op<"call", [AttrSizedOperandSegments]> {
  let summary = "A built-in operator (see ConstraintOperators.def)";
  let description = [{
    `op` is the operator's ID and `kind` how it is written (unary, binary or
    call), as Constraint's enums number them. A value-tracking operator is
    anchored at its explicit context argument or, without one, at `anchor`:
    the pattern instruction the constraint follows.
  }];
  let arguments = (ins I32Attr:$op, I32Attr:$kind, Variadic<Mpir_Term>:$args,
                       Optional<Mpir_Term>:$anchor);
  let results = (outs Mpir_Term:$result);
  let hasVerifier = 1;
  let extraClassDeclaration = [{
    ::llvm::metaphir::Constraint::OperatorID getOperatorID() {
      return ::llvm::metaphir::Constraint::OperatorID(getOp());
    }
  }];
}

def Expr_ApplyOp : Expr_Op<"apply",
                           [DeclareOpInterfaceMethods<SymbolUserOpInterface>]> {
  let summary = "A call of a 'constraint' definition";
  let arguments = (ins FlatSymbolRefAttr:$callee, Variadic<Mpir_Term>:$args);
  let results = (outs Mpir_Term:$result);
  let assemblyFormat = "$callee `(` $args `)` attr-dict `:` functional-type($args, $result)";
}

#endif // METAPHIR_DIALECT_EXPR_EXPROPS_TD
