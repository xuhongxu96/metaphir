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

TypePatternAttr mpir::encodeTypePattern(Value T, const SlotAssignment &Slots,
                                        SmallVectorImpl<Value> *Variables) {
  MLIRContext *Context = T.getContext();
  auto Slot = [&](Value V) {
    assert(Slots.Of.count(V) && "a type variable without a slot");
    if (Variables)
      Variables->push_back(V);
    return Slots.Of.lookup(V);
  };
  auto Nested = [&](Value Of) {
    return encodeTypePattern(Of, Slots, Variables);
  };
  auto AllNested = [&](mlir::ValueRange Of) {
    return llvm::map_to_vector(Of, Nested);
  };
  Operation *Def = T.getDefiningOp();
  if (isa<VarOp>(Def))
    return VarTypePatternAttr::get(Context, Slot(T));
  if (auto Prim = dyn_cast<PrimTypeOp>(Def))
    return PrimTypePatternAttr::get(Context, Prim.getKind());
  if (auto IntTy = dyn_cast<IntTypeOp>(Def))
    return IntTy.getByte() ? TypePatternAttr(ByteTypePatternAttr::get(
                                 Context, IntTy.getWidth()))
                           : IntTypePatternAttr::get(Context, IntTy.getWidth());
  if (auto Meta = dyn_cast<MetaIntTypeOp>(Def)) {
    unsigned Width = Slot(Meta.getWidth());
    return Meta.getByte()
               ? TypePatternAttr(ByteWidthTypePatternAttr::get(Context, Width))
               : IntWidthTypePatternAttr::get(Context, Width);
  }
  if (auto Ptr = dyn_cast<PtrTypeOp>(Def)) {
    return PtrTypePatternAttr::get(Context, Ptr.getAddressSpace(),
                                   Ptr.getElement() ? Nested(Ptr.getElement())
                                                    : TypePatternAttr());
  }
  if (auto Seq = dyn_cast<SeqTypeOp>(Def)) {
    std::optional<uint64_t> Count;
    std::optional<unsigned> CountSlot;
    if (Seq.getCountVar())
      CountSlot = Slot(Seq.getCountVar());
    else
      Count = Seq.getCount();
    return SeqTypePatternAttr::get(Context, Seq.getKind(), Count, CountSlot,
                                   Nested(Seq.getElement()));
  }
  if (auto Struct = dyn_cast<StructTypeOp>(Def))
    return StructTypePatternAttr::get(Context, Struct.getPacked(),
                                      AllNested(Struct.getElements()));
  if (auto Func = dyn_cast<FuncTypeOp>(Def)) {
    TypePatternAttr Return = Nested(Func.getReturnType());
    return FuncTypePatternAttr::get(
        Context, Return, AllNested(Func.getParams()), Func.getVarArg());
  }
  llvm_unreachable("not a type pattern");
}
