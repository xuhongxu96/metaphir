#include "metaphir/Index/FunctionPacker.h"
#include "llvm/ADT/DenseMap.h"
#include "llvm/Bitcode/BitcodeWriter.h"
#include "llvm/IR/Constants.h"
#include "llvm/IR/Function.h"
#include "llvm/IR/GlobalAlias.h"
#include "llvm/IR/GlobalIFunc.h"
#include "llvm/IR/GlobalVariable.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/Module.h"
#include "llvm/IR/Verifier.h"
#include "llvm/Support/raw_ostream.h"
#include "llvm/Transforms/Utils/Cloning.h"
#include "llvm/Transforms/Utils/ValueMapper.h"
#include <tuple>

namespace llvm {
namespace metaphir {

namespace {

/// Where the global values of a module are, as the slot tracker numbers
/// them: the unnamed ones get consecutive numbers in this order.
class GlobalOrder {
public:
  explicit GlobalOrder(const Module &M) {
    for (const GlobalVariable &GV : M.globals())
      add(GV);
    for (const GlobalAlias &GA : M.aliases())
      add(GA);
    for (const GlobalIFunc &GI : M.ifuncs())
      add(GI);
    for (const Function &F : M)
      add(F);
  }

  /// The position of GV in its list.
  unsigned getPosition(const GlobalValue &GV) const {
    return Positions.lookup(&GV);
  }
  /// The number of an unnamed global value.
  std::optional<unsigned> getSlot(const GlobalValue &GV) const {
    auto It = Slots.find(&GV);
    if (It == Slots.end())
      return std::nullopt;
    return It->second;
  }
  /// The unnamed global values, by number.
  ArrayRef<const GlobalValue *> getUnnamed() const { return Unnamed; }

  /// The position of each use of GV in its use list, which spans the
  /// module's functions: ranked once, for all of their packs.
  const DenseMap<const Use *, unsigned> &getUseRanks(const GlobalValue &GV) {
    auto [It, Inserted] = UseRanks.try_emplace(&GV);
    if (Inserted)
      for (const Use &U : GV.uses())
        It->second.try_emplace(&U, It->second.size());
    return It->second;
  }

private:
  void add(const GlobalValue &GV) {
    Positions[&GV] = Positions.size();
    if (!GV.hasName()) {
      Slots[&GV] = Unnamed.size();
      Unnamed.push_back(&GV);
    }
  }

  DenseMap<const GlobalValue *, unsigned> Positions;
  DenseMap<const GlobalValue *, unsigned> Slots;
  SmallVector<const GlobalValue *, 0> Unnamed;
  DenseMap<const GlobalValue *, DenseMap<const Use *, unsigned>> UseRanks;
};

/// Builds the module of one function, with stubs for the global values it
/// refers to, created as the function is cloned.
class PackBuilder : public ValueMaterializer {
public:
  PackBuilder(const Function &F, GlobalOrder &Order)
      : Source(*F.getParent()), Order(Order),
        Packed(std::make_unique<Module>(Source.getModuleIdentifier(),
                                        Source.getContext())) {
    Packed->setDataLayout(Source.getDataLayout());
    Packed->setTargetTriple(Source.getTargetTriple());
    // Without it, reading the pack drops the debug info.
    SmallVector<Module::ModuleFlagEntry, 8> Flags;
    Source.getModuleFlagsMetadata(Flags);
    for (const Module::ModuleFlagEntry &Flag : Flags)
      if (Flag.Key->getString() == "Debug Info Version")
        Packed->addModuleFlag(Flag.Behavior, Flag.Key->getString(), Flag.Val);
    Function *Clone =
        Function::Create(F.getFunctionType(), F.getLinkage(),
                         F.getAddressSpace(), F.getName(), Packed.get());
    VMap[&F] = Clone;
    Originals[Clone] = &F;
    for (auto [Argument, ClonedArgument] : zip(F.args(), Clone->args())) {
      ClonedArgument.setName(Argument.getName());
      VMap[&Argument] = &ClonedArgument;
    }
    SmallVector<ReturnInst *, 4> Returns;
    CloneFunctionInto(Clone, &F, VMap, CloneFunctionChangeType::DifferentModule,
                      Returns,
                      /*NameSuffix=*/"", /*CodeInfo=*/nullptr,
                      /*TypeMapper=*/nullptr, this);
    // Cloning lists the compile units the function's debug info is in, even
    // when there are none, which reading the pack would take for invalid
    // debug info.
    if (NamedMDNode *Units = Packed->getNamedMetadata("llvm.dbg.cu");
        Units && Units->getNumOperands() == 0)
      Packed->eraseNamedMetadata(Units);
    completeIndirections();
    addPlaceholders();
    sortGlobals();
    copyUseListOrder(F, *Clone);
    Target = Clone;
  }

  /// Orders the use lists of Clone's arguments, blocks and instructions, and
  /// of the stubs of the globals it uses, as the originals' are: analyses
  /// that walk a bounded number of uses, as value tracking does, then see
  /// the uses InstCombine sees in the module. Of a global's uses, those in
  /// other functions are not in the pack.
  void copyUseListOrder(const Function &F, Function &Clone) {
    // The original of each user in the clone.
    DenseMap<const llvm::User *, const llvm::User *> OriginalUser;
    for (const BasicBlock &BB : F)
      for (const llvm::Instruction &I : BB)
        if (auto *Cloned = dyn_cast_or_null<llvm::Instruction>(VMap.lookup(&I)))
          OriginalUser[Cloned] = &I;
    // Sorts Copy's uses as their originals rank in Rank.
    auto SortAs = [&](llvm::Value &Copy,
                      const DenseMap<const Use *, unsigned> &Rank) {
      if (Copy.hasOneUse() || Copy.use_empty())
        return;
      auto RankOf = [&](const Use &U) {
        const llvm::User *User = OriginalUser.lookup(U.getUser());
        if (!User)
          return ~0u;
        auto Of = Rank.find(&User->getOperandUse(U.getOperandNo()));
        return Of == Rank.end() ? ~0u : Of->second;
      };
      Copy.sortUseList(
          [&](const Use &L, const Use &R) { return RankOf(L) < RankOf(R); });
    };
    // A value of the function is used only in it: its uses are ranked here.
    auto Reorder = [&](const llvm::Value &Original, llvm::Value &Copy) {
      if (Copy.hasOneUse() || Copy.use_empty())
        return;
      DenseMap<const Use *, unsigned> Rank;
      for (const Use &U : Original.uses())
        Rank.try_emplace(&U, Rank.size());
      SortAs(Copy, Rank);
    };
    for (auto [Argument, Cloned] : zip(F.args(), Clone.args()))
      Reorder(Argument, Cloned);
    for (const BasicBlock &BB : F) {
      if (auto *Cloned = dyn_cast_or_null<BasicBlock>(VMap.lookup(&BB)))
        Reorder(BB, *Cloned);
      for (const llvm::Instruction &I : BB)
        if (llvm::Value *Cloned = VMap.lookup(&I))
          Reorder(I, *Cloned);
    }
    for (const auto &[Stub, Original] : Originals)
      SortAs(*const_cast<GlobalValue *>(Stub), Order.getUseRanks(*Original));
  }

  llvm::Value *materialize(llvm::Value *V) override {
    auto *GV = dyn_cast<GlobalValue>(V);
    if (!GV || GV->getParent() != &Source)
      return nullptr;
    GlobalValue *Stub = createStub(*GV);
    Originals[Stub] = GV;
    return Stub;
  }

  Module &getModule() const { return *Packed; }
  Function &getFunction() const { return *Target; }

private:
  GlobalValue *createStub(const GlobalValue &GV) {
    // Definitions stay definitions, as linkage asks, with no initializer or
    // body worth keeping (common globals need a zero one).
    if (const auto *Var = dyn_cast<GlobalVariable>(&GV)) {
      auto *Stub = new GlobalVariable(
          *Packed, Var->getValueType(), Var->isConstant(), Var->getLinkage(),
          Var->isDeclaration() ? nullptr
                               : Constant::getNullValue(Var->getValueType()),
          Var->getName(), /*InsertBefore=*/nullptr, Var->getThreadLocalMode(),
          Var->getAddressSpace(), Var->isExternallyInitialized());
      Stub->copyAttributesFrom(Var);
      return Stub;
    }
    if (const auto *Fn = dyn_cast<Function>(&GV)) {
      Function *Stub =
          Function::Create(Fn->getFunctionType(), Fn->getLinkage(),
                           Fn->getAddressSpace(), Fn->getName(), Packed.get());
      Stub->copyAttributesFrom(Fn);
      // These refer to the source module.
      Stub->setPersonalityFn(nullptr);
      Stub->setPrefixData(nullptr);
      Stub->setPrologueData(nullptr);
      if (!Fn->isDeclaration())
        new UnreachableInst(Packed->getContext(),
                            BasicBlock::Create(Packed->getContext(), "", Stub));
      return Stub;
    }
    // Aliases and ifuncs get their targets once the function is cloned.
    Constant *Pending = PoisonValue::get(GV.getType());
    if (const auto *Alias = dyn_cast<GlobalAlias>(&GV)) {
      GlobalAlias *Stub = GlobalAlias::create(
          Alias->getValueType(), Alias->getAddressSpace(), Alias->getLinkage(),
          Alias->getName(), Pending, Packed.get());
      Stub->copyAttributesFrom(Alias);
      Indirections.push_back(Stub);
      return Stub;
    }
    const auto *IFunc = cast<GlobalIFunc>(&GV);
    GlobalIFunc *Stub = GlobalIFunc::create(
        IFunc->getValueType(), IFunc->getAddressSpace(), IFunc->getLinkage(),
        IFunc->getName(), Pending, Packed.get());
    Stub->copyAttributesFrom(IFunc);
    Indirections.push_back(Stub);
    return Stub;
  }

  /// Points the stubs of aliases and ifuncs where theirs point, stubbing
  /// what that refers to in turn.
  void completeIndirections() {
    while (!Indirections.empty()) {
      GlobalValue *Stub = Indirections.pop_back_val();
      if (auto *Alias = dyn_cast<GlobalAlias>(Stub))
        Alias->setAliasee(
            map(cast<GlobalAlias>(Originals[Alias])->getAliasee()));
      else
        cast<GlobalIFunc>(Stub)->setResolver(
            map(cast<GlobalIFunc>(Originals[Stub])->getResolver()));
    }
  }

  Constant *map(const Constant *C) {
    return MapValue(C, VMap, RF_None, /*TypeMapper=*/nullptr, this);
  }

  /// Adds unnamed global values in place of the source module's that the
  /// function does not refer to, so that those it does are numbered as in
  /// the source module.
  void addPlaceholders() {
    std::optional<unsigned> Last;
    for (const auto &[Stub, Original] : Originals)
      if (std::optional<unsigned> Slot = Order.getSlot(*Original))
        Last = std::max(Last.value_or(0), *Slot);
    if (!Last)
      return;
    LLVMContext &Context = Packed->getContext();
    Type *Byte = Type::getInt8Ty(Context);
    for (const GlobalValue *Original : Order.getUnnamed().take_front(*Last)) {
      if (VMap.count(Original))
        continue;
      GlobalValue *Placeholder;
      if (isa<GlobalVariable>(Original)) {
        Placeholder = new GlobalVariable(*Packed, Byte, /*isConstant=*/false,
                                         GlobalValue::ExternalLinkage,
                                         /*Initializer=*/nullptr);
      } else if (isa<Function>(Original)) {
        Placeholder =
            Function::Create(FunctionType::get(Type::getVoidTy(Context), false),
                             GlobalValue::ExternalLinkage, "", Packed.get());
      } else if (isa<GlobalAlias>(Original)) {
        Placeholder =
            GlobalAlias::create(Byte, 0, GlobalValue::ExternalLinkage, "",
                                getNamedPlaceholder(), Packed.get());
      } else {
        Placeholder = GlobalIFunc::create(Byte, 0, GlobalValue::ExternalLinkage,
                                          "", getNamedResolver(), Packed.get());
      }
      Originals[Placeholder] = Original;
    }
  }

  Function *getNamedResolver() {
    if (Function *F = Packed->getFunction("metaphir.resolver"))
      return F;
    return Function::Create(
        FunctionType::get(PointerType::get(Packed->getContext(), 0), false),
        GlobalValue::ExternalLinkage, "metaphir.resolver", Packed.get());
  }

  GlobalVariable *getNamedPlaceholder() {
    if (GlobalVariable *GV = Packed->getNamedGlobal("metaphir.placeholder"))
      return GV;
    return new GlobalVariable(*Packed, Type::getInt8Ty(Packed->getContext()),
                              /*isConstant=*/false,
                              GlobalValue::ExternalLinkage,
                              /*Initializer=*/nullptr, "metaphir.placeholder");
  }

  /// Orders each list of global values as the source module does; what has
  /// no counterpart there goes last.
  void sortGlobals() {
    auto Position = [&](const GlobalValue &GV) {
      auto It = Originals.find(&GV);
      return It == Originals.end() ? ~0u : Order.getPosition(*It->second);
    };
    auto Sorted = [&](auto &&List) {
      using T = std::remove_pointer_t<std::decay_t<decltype(&*List.begin())>>;
      // Each value's position, then its index in List to keep ties stable
      // (without std::stable_sort's temporary buffer, deprecated in newer
      // libstdc++).
      SmallVector<std::tuple<unsigned, unsigned, T *>, 16> Keyed;
      for (auto &V : List)
        Keyed.emplace_back(Position(V), Keyed.size(), &V);
      llvm::sort(Keyed);
      SmallVector<T *, 16> Values;
      for (const auto &Entry : Keyed)
        Values.push_back(std::get<2>(Entry));
      return Values;
    };
    for (GlobalVariable *GV : Sorted(Packed->globals())) {
      Packed->removeGlobalVariable(GV);
      Packed->insertGlobalVariable(GV);
    }
    for (GlobalAlias *GA : Sorted(Packed->aliases())) {
      Packed->removeAlias(GA);
      Packed->insertAlias(GA);
    }
    for (GlobalIFunc *GI : Sorted(Packed->ifuncs())) {
      Packed->removeIFunc(GI);
      Packed->insertIFunc(GI);
    }
    for (Function *F : Sorted(Packed->functions())) {
      F->removeFromParent();
      Packed->getFunctionList().push_back(F);
    }
  }

  const Module &Source;
  GlobalOrder &Order;
  std::unique_ptr<Module> Packed;
  ValueToValueMapTy VMap;
  /// What each global value of the packed module stands for.
  DenseMap<const GlobalValue *, const GlobalValue *> Originals;
  SmallVector<GlobalValue *, 2> Indirections;
  Function *Target = nullptr;
};

} // namespace

Error packFunctions(Module &M,
                    function_ref<Error(const Function &, FunctionPack)> Add) {
  // How constants are used, before packs use them too.
  std::vector<std::pair<const Function *, std::vector<ModuleUses>>> Functions;
  for (const Function &F : M) {
    if (F.isDeclaration())
      continue;
    std::vector<ModuleUses> &Uses = Functions.emplace_back(&F, 0).second;
    forEachReferencedConstant(F, [&](const Constant &C) {
      Uses.push_back(ModuleUses{C.getNumUses(), C.hasOneUser()});
    });
  }

  GlobalOrder Order(M);
  // A pack of a valid module must be valid too; one of an invalid module
  // is as invalid as its function.
  bool Valid = !verifyModule(M);
  for (auto &[F, Uses] : Functions) {
    FunctionPack Pack;
    Pack.Uses = std::move(Uses);
    {
      PackBuilder Builder(*F, Order);
      Module &Packed = Builder.getModule();
      std::string Problems;
      raw_string_ostream ProblemsOS(Problems);
      if (Valid && verifyModule(Packed, &ProblemsOS))
        return createStringError("cannot pack @" + F->getName() + ": " +
                                 Problems);
      Pack.FunctionIndex =
          std::distance(Packed.begin(), Builder.getFunction().getIterator());
      // With the use lists' order (see copyUseListOrder), and without the
      // symbol table WriteBitcodeToFile adds for LTO: no reader of a pack
      // needs it, and it is about a sixth of its bitcode.
      SmallVector<char, 0> Buffer;
      BitcodeWriter Writer(Buffer);
      Writer.writeModule(Packed, /*ShouldPreserveUseListOrder=*/true);
      Writer.writeStrtab();
      Pack.Bitcode.assign(Buffer.begin(), Buffer.end());
    }
    if (Error E = Add(*F, std::move(Pack)))
      return E;
  }
  return Error::success();
}

} // namespace metaphir
} // namespace llvm
