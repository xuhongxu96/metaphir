//===- Bindings.cpp - How plans and index queries name bindings ---------===//

#include "metaphir/Dialect/Pattern/Bindings.h"

using namespace mlir;
using namespace llvm::metaphir;
using namespace llvm::metaphir::mpir;

/// The outermost alternative that yields Result as its match, climbing one
/// yielding alternative at a time; Result itself if none does.
static Value outermostYielding(Value Result) {
  Value Outer = Result;
  while (true) {
    AltOp Yielding;
    // Only a matcher defined in the alternative's own region counts. A value
    // from outside that the alternative yields (an operand matched in the
    // instruction's place) has a slot of its own.
    for (Operation *User : Outer.getUsers())
      if (auto Yield = dyn_cast<YieldOp>(User))
        if (auto Alt = dyn_cast<AltOp>(Yield->getParentOp()))
          if (Outer.getDefiningOp() &&
              Outer.getDefiningOp()->getBlock() == Yield->getBlock())
            Yielding = Alt;
    if (!Yielding)
      return Outer;
    Outer = Yielding.getResult();
  }
}

SlotAssignment mpir::assignSlots(PatternOp Pattern) {
  SlotAssignment Slots;
  auto Add = [&](Value V) {
    Slots.Of[V] = Slots.Values.size();
    Slots.Values.push_back(V);
  };
  Pattern.walk<WalkOrder::PreOrder>([&](Operation *Op) {
    if (auto Var = dyn_cast<VarOp>(Op))
      return Add(Var);
    if (!isa<InstOp, AltOp>(Op))
      return;
    Value Result = Op->getResult(0);
    // A yielded matcher shares the slot the walk gave the alternative.
    Value Outer = outermostYielding(Result);
    if (Outer != Result)
      Slots.Of[Result] = Slots.Of.lookup(Outer);
    else
      Add(Result);
  });
  return Slots;
}

ArrayAttr mpir::encodeTypePattern(Builder &Builder, Value T,
                                  const SlotAssignment &Slots,
                                  SmallVectorImpl<Value> *Variables) {
  auto VariableNumber = [&](Value V) {
    assert(Slots.Of.count(V) && "a type variable without a slot");
    if (Variables)
      Variables->push_back(V);
    return int64_t(Slots.Of.lookup(V));
  };
  SmallVector<Attribute, 8> Parts;
  auto Int = [&](int64_t V) { Parts.push_back(Builder.getI64IntegerAttr(V)); };
  auto Kind = [&](TypePatternKind K) { Int(int64_t(K)); };
  auto Nested = [&](Value Of) {
    Parts.push_back(encodeTypePattern(Builder, Of, Slots, Variables));
  };
  Operation *Def = T.getDefiningOp();
  if (isa<VarOp>(Def)) {
    Kind(TypePatternKind::Variable);
    Int(VariableNumber(T));
  } else if (auto Prim = dyn_cast<PrimTypeOp>(Def)) {
    Kind(TypePatternKind::Primitive);
    Int(Prim.getKind());
  } else if (auto IntTy = dyn_cast<IntTypeOp>(Def)) {
    Kind(TypePatternKind::Integer);
    Int(IntTy.getWidth());
    Int(IntTy.getByte());
  } else if (auto Meta = dyn_cast<MetaIntTypeOp>(Def)) {
    Kind(TypePatternKind::MetaInteger);
    Int(VariableNumber(Meta.getWidth()));
    Int(Meta.getByte());
  } else if (auto Ptr = dyn_cast<PtrTypeOp>(Def)) {
    Kind(TypePatternKind::Pointer);
    std::optional<uint32_t> Space = Ptr.getAddressSpace();
    Int(Space ? int64_t(*Space) : -1);
    Int(!Ptr.getElement());
  } else if (auto Seq = dyn_cast<SeqTypeOp>(Def)) {
    Kind(TypePatternKind::Sequence);
    Int(int64_t(Seq.getKind()));
    Int(Seq.getCount());
    Int(Seq.getCountVar() ? VariableNumber(Seq.getCountVar()) : -1);
    Nested(Seq.getElement());
  } else if (auto Struct = dyn_cast<StructTypeOp>(Def)) {
    Kind(TypePatternKind::Struct);
    Int(Struct.getPacked());
    for (Value E : Struct.getElements())
      Nested(E);
  } else if (auto Func = dyn_cast<FuncTypeOp>(Def)) {
    Kind(TypePatternKind::Function);
    Int(Func.getVarArg());
    Nested(Func.getReturnType());
    for (Value P : Func.getParams())
      Nested(P);
  } else {
    llvm_unreachable("not a type pattern");
  }
  return Builder.getArrayAttr(Parts);
}
