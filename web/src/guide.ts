// The pattern guide, which opens with the page until dismissed, and from
// the Help button. First a few demonstrations, each a
// small pattern beside IR it matches, with its parts marked; then patterns
// that put them together, to try; then, for reference, everything there is:
// the meta flags, constraint operators and matchers of the standard
// library, and the PatternMatch.h idioms beside patterns. Each pattern is
// checked to match its IR and bind what is marked, and the lists to be all
// there are (test/guide.test.ts).
//
// A pattern or IR marks a part as [[kind:text]]; in IR, [[kind:text|?x]]
// marks the text that ?x binds.

/** What a part of a demonstration is: a short name, shown under it, and
 * what it says, on hover. A Mark with text is of the parts with that text,
 * else of the parts of its kind. */
export interface Mark {
  kind: string;
  text?: string;
  name: string;
  says: string;
}

export interface Demo {
  id: string;
  title: string;
  intro: string;
  /** The pattern, and instructions it matches in a function with the
   * arguments ARGUMENTS, both marked. */
  pattern: string;
  matches: string;
  /** What else the module needs, such as a declaration. */
  module?: string;
  /** Patterns to match on their own, in place of pattern: each with the
   * lines of matches it matches, and what it binds in each. */
  cases?: { pattern: string; matches: number[]; binds?: string[] }[];
  marks?: Mark[];
  /** Code to compare the pattern with, such as InstCombine's. */
  aside?: { title: string; code: string };
  /** More to know, with `code` in backquotes. */
  notes?: string[];
  /** The sections of the reference about it, by id. */
  see?: string[];
}

/** The arguments of the function a demonstration's instructions are in. */
export const ARGUMENTS = "i32 %a, i32 %b, i8 %c, i64 %w, <4 x i32> %v";

/** What the part of a demonstration with text and kind is, if it says. */
export const markOf = (demo: Demo, text: string, kind: string) =>
  demo.marks?.find((m) => m.text === text) ?? demo.marks?.find((m) => m.kind === kind && !m.text);

export const DEMOS: Demo[] = [
  {
    id: "anatomy",
    see: ["ref-idioms"],
    title: "A Pattern",
    intro:
      "A pattern is LLVM IR with meta variables and constraints.\nIt matches functions that have these instructions.\nThis one is the fold of #214541. Hover a part to see what it is.",
    pattern: [
      "[[local:%d]] = udiv i[[var:?n]] [[var:?x]], [[var:?y]]",
      "[[local:%r]] = udiv i[[var:?n]] [[local:%d]][[flag::s]], [[var:?z]]",
      '[[constraint:;; noOverflow("umul", ?y, ?z)]]',
    ].join("\n"),
    matches: [
      "%d = udiv i[[var:32|?n]] [[var:%a|?x]], [[var:3|?y]]",
      "%r = udiv i[[var:32|?n]] %d, [[var:5|?z]]",
    ].join("\n"),
    marks: [
      { kind: "var", name: "meta variable", says: "It matches whatever is in its place." },
      { kind: "local", name: "local", says: "It names an instruction for the pattern to use." },
      { kind: "flag", name: "meta flag", says: "%d has a single use." },
      { kind: "constraint", name: "constraint", says: "It must hold of the bindings." },
    ],
    aside: {
      title: "The Same Fold in InstCombine",
      code: [
        "// (X udiv Y) udiv Z --> X udiv (Y * Z)",
        "match(Op0, m_OneUse(m_UDiv(m_Value(X), m_Value(Y)))) &&",
        "    willNotOverflowUnsignedMul(Y, Op1, I)",
      ].join("\n"),
    },
  },
  {
    id: "variables",
    title: "Meta Variables",
    intro:
      "One of each sort. Hover one to see what it binds.",
    pattern: [
      "[[block:?bb]]:",
      "%t = trunc nuw:[[bool:?nuw]] i[[nat:?big]] [[value:?x]] to i[[nat:?small]]",
      "%e = zext:[[inst:?ext]] i[[nat:?small]] %t to i[[nat:?big]]",
      "%k = icmp [[pred:?pred]] i[[nat:?big]] %e, [[value:?y]]",
      "%m = call [[type:?ty]] @llvm.[[intrinsic:?id]]([[type:?ty]] [[value:?p]], [[type:?ty]] [[value:?q]])",
      "%r = call [[type:?ty]] [[fn:?f]](i32 %m, ...[[array:?types]] [[array:?args]])",
    ].join("\n"),
    matches: [
      "[[block:entry|?bb]]:",
      "%t = trunc [[bool:nuw|?nuw]] i[[nat:64|?big]] [[value:%w|?x]] to i[[nat:32|?small]]",
      "[[inst:%e|?ext]] = zext i32 %t to i64",
      "%k = icmp [[pred:slt|?pred]] i64 %e, [[value:5|?y]]",
      "%m = call [[type:i32|?ty]] @[[intrinsic:llvm.smax|?id]].i32(i32 [[value:%a|?p]], i32 [[value:%b|?q]])",
      "%r = call i32 [[fn:@g|?f]](i32 %m, [[array:i8|?types]] [[array:%c|?args]], [[array:i64|?types]] [[array:%w|?args]])",
    ].join("\n"),
    module: "declare i32 @llvm.smax.i32(i32, i32)\ndeclare i32 @g(i32, i8, i64)",
    marks: [
      { kind: "value", name: "Value", says: "An argument, instruction or constant." },
      { kind: "nat", name: "Nat", says: "A number. Here, an integer width." },
      { kind: "type", name: "Type", says: "A type." },
      { kind: "bool", name: "i1", says: "Whether nuw is present. Either way matches." },
      { kind: "inst", name: "Instruction", says: "The instruction matched. Constraints can use it." },
      { kind: "pred", name: "CmpPredicate", says: "The compare's predicate." },
      { kind: "intrinsic", name: "Intrinsic::ID", says: "The intrinsic called." },
      { kind: "fn", name: "Function", says: "The function called." },
      { kind: "block", name: "BasicBlock", says: "The block of the instructions below." },
      { kind: "array", text: "?types", name: "Type[]", says: "The types of the rest of the operands." },
      { kind: "array", text: "?args", name: "Value[]", says: "The rest of the operands." },
    ],
    notes: [
      "A meta variable used twice is one value. `mul i32 ?x, ?x` squares a value.",
      "`?_` matches anything. Each `?_` is a new one.",
    ],
  },
  {
    id: "llvm-flags",
    title: "LLVM's Flags",
    intro: "Four patterns, each matched on its own.\nHover one to see which instructions it matches.",
    pattern: "",
    cases: [
      { pattern: "%r = [[flag:add]] i32 ?x, ?y", matches: [0, 1] },
      { pattern: "%r = add [[flag:nsw]] i32 ?x, ?y", matches: [0] },
      { pattern: "%r = add [[flag:!nsw]] i32 ?x, ?y", matches: [1] },
      { pattern: "%r = add [[flag:nsw:?f]] i32 ?x, ?y", matches: [0, 1], binds: ["?f = true", "?f = false"] },
    ],
    matches: "%p = add nsw i32 %a, %b\n%q = add i32 %a, %b",
    marks: [
      { kind: "flag", text: "add", name: "no flag", says: "No flag is written. So nsw may be present or not." },
      { kind: "flag", text: "nsw", name: "present", says: "The instruction must have nsw." },
      { kind: "flag", text: "!nsw", name: "absent", says: "The instruction must not have nsw." },
      { kind: "flag", text: "nsw:?f", name: "captured", says: "Either way. ?f says whether it has nsw." },
    ],
  },
  {
    id: "flags",
    see: ["ref-flags"],
    title: "Meta Flags",
    intro:
      "On an instruction, a meta flag says how to match it.\nOn an operand, it says what the operand must be.",
    pattern: [
      "%n = sub[[flag::s]] i32 0, ?x[[flag::knownPowerOfTwo]]",
      "%r = and[[flag::c]] i32 %n, ?m[[flag::or(:lowBitMask, :zero)]]",
    ].join("\n"),
    matches: "%x = shl i32 1, %b\n%n = sub i32 0, %x\n%r = and i32 255, %n",
    marks: [
      { kind: "flag", text: ":s", name: "one use", says: "%n has a single use. Like m_OneUse." },
      { kind: "flag", text: ":knownPowerOfTwo", name: "value tracking", says: "?x is known to be a power of 2. Like isKnownToBeAPowerOfTwo." },
      { kind: "flag", text: ":c", name: "any order", says: "The operands may come in either order. Like m_c_And." },
      { kind: "flag", text: ":or(:lowBitMask, :zero)", name: "logic", says: "?m is a low-bit mask or zero. :not(…) negates flags." },
    ],
    notes: [
      "Define your own with `metaflag :byte(?v) { ult(?v, 256) }`.\nThen write `?c:byte`.",
    ],
  },
  {
    id: "constraints",
    see: ["ref-operators", "ref-settings"],
    title: "Constraints",
    intro: "Each ;; line must hold of the bindings.",
    pattern: [
      "%m = and i?n ?x, ?c",
      "%r = icmp ?pred i?n %m, 0",
      "[[constraint:;; isPower2(?c) && isEquality(?pred)]]",
      "[[constraint:;; ult(?c, shl(1, ?n - 1))]]",
    ].join("\n"),
    matches: "%m = and i32 %a, 8\n%r = icmp eq i32 %m, 0",
    marks: [{ kind: "constraint", name: "constraint", says: "A condition on ?c, ?pred and ?n." }],
    notes: [
      "Orderings and division have names, such as `ult(?a, ?b)` and `udiv(?a, ?b)`.\nThere is no `<` or `/`.",
      "`+`, `-`, `*` and `==` are exact. They never wrap.\nSo `?c + 1 == 128` holds for `i8 127`.",
      "With a width, an operator computes as the instruction does.\nSo `add(?c, 1, 8) == -128` holds for `i8 127`.",
      "A constant reads as signed. `i8 -1` is -1, and `eq(?c, 255, 8)` compares it as an i8.",
      "Value tracking asks at the instruction before the constraint.",
      "Define your own with `constraint isByte(?v) { ult(?v, 256) }`.",
    ],
  },
  {
    id: "matchers",
    see: ["ref-matchers"],
    title: "Composite Matchers",
    intro:
      "A matcher is used like an instruction.\nIt matches any of its alternatives.",
    pattern: [
      "match mulOrShl [] Binary (?ty ?x, ?y) {",
      "  %ret = mul ?ty ?x, ?y",
      "} or {",
      "  %ret = shl ?ty ?x, ?y",
      "}",
      "%r = [[flag:mulOrShl]] i32 ?x, ?y",
      "%s = [[flag:addLike]] i32 %r, 1",
    ].join("\n"),
    matches: "%r = shl i32 %a, %b\n%s = or disjoint i32 %r, 1",
    marks: [
      { kind: "flag", text: "mulOrShl", name: "your own", says: "Defined above. It is a mul or a shl." },
      { kind: "flag", text: "addLike", name: "stdlib", says: "It is an add or an or disjoint. Like m_AddLike." },
    ],
  },
];

/** Patterns that put several of the demonstrations together, to try on the
 * corpus; each with instructions it matches, as a Demo has. */
export const TRY: { title: string; pattern: string; matches: string }[] = [
  {
    title: "Widen a One-Bit Test",
    pattern: [
      ";; treatIntAsVec(true)",
      "%b = and:c i?n ?x, ?p:power2",
      "%t = icmp ne i?n %b, 0",
      "%z = zext:s i1 %t to i?n",
    ].join("\n"),
    matches: "%m = and i32 %a, 8\n%t = icmp ne i32 %m, 0\n%z = zext i1 %t to i32\n%u = add i32 %z, 1",
  },
  {
    title: "Signed Min or Max of a Widened Value",
    pattern: [
      "%e = sextLike i?s ?x to i?d",
      "%m = maxOrMin:?mm i?d %e, ?c:apInt",
      ';; intrinsic(?mm) == "llvm.smax" || intrinsic(?mm) == "llvm.smin"',
      ";; sge(?c, -shl(1, ?s - 1)) && slt(?c, shl(1, ?s - 1))",
    ].join("\n"),
    matches: "%e = sext i8 %c to i32\n%m = call i32 @llvm.smax.i32(i32 %e, i32 7)",
  },
  {
    title: "Select a Value Known to Be Nonzero",
    pattern: [
      "%k = icmp:c ?pred i?n ?x, 0",
      "%r = select i1 %k, i?n ?y, i?n ?x",
      ";; isEquality(?pred) && isKnownNonZero(?y)",
    ].join("\n"),
    matches: "%y = or i32 %b, 1\n%k = icmp eq i32 %a, 0\n%r = select i1 %k, i32 %y, i32 %a",
  },
  {
    title: "Shift Left, Then Back Right",
    pattern: [
      "%s = shl nuw:?nuw nsw:?nsw i?n ?x, ?k:constantInt",
      "%r = shr:?shr i?n %s, ?k",
      ';; (opcode(?shr) == "lshr" && ?nuw) || (opcode(?shr) == "ashr" && ?nsw)',
    ].join("\n"),
    matches: "%s = shl nuw i32 %a, 4\n%r = lshr i32 %s, 4",
  },
];

/** The text of a marked pattern or IR, as written. */
export const unmarked = (text: string) =>
  text.replace(/\[\[\w+:(.*?)(?:\|[^\]]*)?\]\]/g, "$1");

export type MarkedPart = { text: string; kind?: string; of?: string };

/** The parts of a marked text: plain text, and marks. */
export function marked(text: string): MarkedPart[] {
  const parts: MarkedPart[] = [];
  let at = 0;
  for (const m of text.matchAll(/\[\[(\w+):(.*?)(?:\|([^\]]*))?\]\]/g)) {
    if (m.index > at) parts.push({ text: text.slice(at, m.index) });
    parts.push({ text: m[2], kind: m[1], of: m[3] });
    at = m.index + m[0].length;
  }
  if (at < text.length) parts.push({ text: text.slice(at) });
  return parts;
}

/** An entry of the reference: how it is written, and what it means. */
export type Entry = [written: string, means: string];

/** Entries of a kind, for reference. */
export interface Group {
  title: string;
  /** What all of them share, if anything. */
  about?: string;
  entries: Entry[];
}

export const META_FLAGS: Group[] = [
  {
    title: "How to Match",
    entries: [
      [":c", "the operands in either order"],
      [":o", "or just its operand 0"],
      [":o(N)", "or just its operand N"],
    ],
  },
  {
    title: "Uses",
    entries: [
      [":s", "a single use"],
      [":su", "a single user"],
    ],
  },
  {
    title: "Kinds of Constants",
    entries: [
      [":constantInt", "a ConstantInt"],
      [":apInt", "an integer or an integer splat"],
      [":apIntAllowPoison", ":apInt with poison lanes"],
      [":anyIntegralConstant", "any integer constant or vector"],
      [":immConstant", "no constant expression in it"],
      [":constantSplat", "a vector splat"],
      [":scalar", "not a vector"],
      [":forbidPoison", "no poison in it"],
      [":poison", "poison"],
      [":undef", "undef or poison"],
      [":zeroOrPoison", "0 or poison"],
      [":allOnesOrPoison", "-1 or poison"],
    ],
  },
  {
    title: "Integer Constants",
    entries: [
      [":zero", "0"],
      [":allOnes", "-1"],
      [":power2", "2^k"],
      [":power2OrZero", "2^k or 0"],
      [":negatedPower2", "-2^k"],
      [":negatedPower2OrZero", "-2^k or 0"],
      [":lowBitMask", "2^k - 1, k > 0"],
      [":lowBitMaskOrZero", "2^k - 1"],
      [":shiftedMask", "one run of ones"],
      [":signMask", "only the sign bit"],
      [":maxSignedValue", "the largest signed value"],
      [":negative", "< 0"],
      [":nonNegative", ">= 0"],
      [":strictlyPositive", "> 0"],
      [":nonPositive", "<= 0"],
      [":nonZeroInt", "!= 0"],
      [":odd", "odd"],
    ],
  },
  {
    title: "Floating-Point Constants",
    entries: [
      [":anyZeroFP", "0.0 or -0.0"],
      [":posZeroFP", "0.0"],
      [":negZeroFP", "-0.0"],
      [":inf", "an infinity"],
      [":nan", "a NaN"],
    ],
  },
  {
    title: "Value Tracking",
    entries: [
      [":knownNegative", "known < 0"],
      [":knownPowerOfTwo", "known 2^k"],
      [":knownPowerOfTwoOrZero", "known 2^k or 0"],
      [":notUndef", "never undef"],
      [":notPoison", "never poison"],
      [":notUndefOrPoison", "never either"],
    ],
  },
  {
    title: "Logic",
    entries: [
      [":or(…)", "one of the flags holds"],
      [":not(…)", "the flags do not hold"],
    ],
  },
];

export interface Operators extends Group {
  /** A constraint with some of them, shown; and, to check it, instructions
   * it is a constraint on and instructions they match. */
  example: string;
  on: string;
  matches: string;
}

/** The constraint of the meta flag of a constant class: isPower2 is :power2. */
const classOf = (name: string): Entry => [
  `${name}(v)`,
  `v is ${name === "isNaN" ? ":nan" : `:${name[2].toLowerCase()}${name.slice(3)}`}`,
];

export const OPERATORS: Operators[] = [
  {
    title: "Logical",
    entries: [
      ["!a", "not"],
      ["a && b", "and"],
      ["a || b", "or"],
    ],
    example: "!(?c == 0) && (ult(?c, 8) || ?c == -1)",
    on: "%r = add i32 ?x, ?c",
    matches: "%r = add i32 %a, 2",
  },
  {
    title: "Equality",
    entries: [
      ["a == b", "equal"],
      ["a != b", "not equal"],
      ["eq(a, b, w)", "equal as w-bit integers"],
      ["ne(a, b, w)", "not equal as w-bit integers"],
    ],
    example: "eq(?c, 255, 8)",
    on: "%r = and i8 ?x, ?c",
    matches: "%r = and i8 %c, -1",
  },
  {
    title: "Arithmetic",
    about: "Without `w`, `add`, `sub`, `mul` and `neg` are `+`, `-`, `*` and unary `-`.",
    entries: [
      ["a + b, a - b, a * b, -a", "exact. Never wraps."],
      ["add(a, b, w)", "a + b at w bits"],
      ["sub(a, b, w)", "a - b at w bits"],
      ["mul(a, b, w)", "a * b at w bits"],
      ["neg(a, w)", "-a at w bits"],
    ],
    example: "?c + 1 == 128 && add(?c, 1, 8) == -128",
    on: "%r = add i8 ?x, ?c",
    matches: "%r = add i8 %c, 127",
  },
  {
    title: "Comparisons",
    entries: [
      ["slt(a, b)", "a < b, signed"],
      ["sle(a, b)", "a <= b, signed"],
      ["sgt(a, b)", "a > b, signed"],
      ["sge(a, b)", "a >= b, signed"],
      ["ult(a, b)", "a < b, unsigned"],
      ["ule(a, b)", "a <= b, unsigned"],
      ["ugt(a, b)", "a > b, unsigned"],
      ["uge(a, b)", "a >= b, unsigned"],
    ],
    example: "slt(?c, 0) && ugt(?c, 7)",
    on: "%r = add i32 ?x, ?c",
    matches: "%r = add i32 %a, -5",
  },
  {
    title: "Division, Shifts and Bitwise",
    about: "Each takes an optional width `w`, as in `udiv(a, b, w)`.",
    entries: [
      ["sdiv(a, b)", "signed a / b"],
      ["udiv(a, b)", "unsigned a / b"],
      ["srem(a, b)", "signed a % b"],
      ["urem(a, b)", "unsigned a % b"],
      ["shl(a, b)", "a << b"],
      ["lshr(a, b)", "logical a >> b"],
      ["ashr(a, b)", "arithmetic a >> b"],
      ["and(a, b)", "bitwise and"],
      ["or(a, b)", "bitwise or"],
      ["xor(a, b)", "bitwise xor"],
    ],
    example: "urem(?c, 3) == 0 && lshr(?c, 1) == 3",
    on: "%r = udiv i32 ?x, ?c",
    matches: "%r = udiv i32 %a, 6",
  },
  {
    title: "Bits",
    entries: [
      ["log2(a)", "the floor of log2"],
      ["popcount(a)", "the bits set"],
      ["countl_zero(a)", "the leading zeros"],
      ["countr_zero(a)", "the trailing zeros"],
      ["countl_one(a)", "the leading ones"],
      ["countr_one(a)", "the trailing ones"],
      ["bitWidth(v)", "the width of v's element type"],
    ],
    example: "popcount(?c) == 1 && ult(log2(?c), 4) && bitWidth(?x) == 32",
    on: "%r = mul i?n ?x, ?c",
    matches: "%r = mul i32 %a, 8",
  },
  {
    title: "Inspection",
    entries: [
      ['isa(v, "Class")', "v is of that C++ class"],
      ["opcode(i)", 'the opcode of i, such as "zext"'],
      ["intrinsic(i)", 'the intrinsic i calls, such as "llvm.smax"'],
      ["predicate(i)", 'the predicate of compare i, such as "slt"'],
    ],
    example: 'opcode(?e) == "sext" && !isa(?x, "Constant")',
    on: "%r = zextOrSext:?e i8 ?x to i32",
    matches: "%r = sext i8 %c to i32",
  },
  {
    title: "Constants",
    about: "Each is the meta flag of its name.",
    entries: [
      ...[
        "isZero",
        "isAllOnes",
        "isPower2",
        "isPower2OrZero",
        "isNegatedPower2",
        "isNegatedPower2OrZero",
        "isLowBitMask",
        "isLowBitMaskOrZero",
        "isShiftedMask",
        "isSignMask",
        "isMaxSignedValue",
        "isNegative",
        "isNonNegative",
        "isStrictlyPositive",
        "isNonPositive",
        "isNonZeroInt",
        "isAnyZeroFP",
        "isPosZeroFP",
        "isNegZeroFP",
        "isInf",
        "isNaN",
        "isPoison",
        "isUndef",
        "isAnyIntegralConstant",
        "isImmConstant",
        "isForbidPoison",
        "isConstantSplat",
        "isScalar",
      ].map(classOf),
    ],
    example: "isPower2(?c) || isNegatedPower2(?c)",
    on: "%r = and i32 ?x, ?c",
    matches: "%r = and i32 %a, -16",
  },
  {
    title: "Uses",
    entries: [
      ["hasOneUse(v)", "one use"],
      ["hasOneUser(v)", "one user"],
      ["hasNUses(v, n)", "n uses"],
      ["hasNUsesOrMore(v, n)", "n uses or more"],
    ],
    example: "hasNUses(?x, 2)",
    on: "%r = add i32 ?x, ?y",
    matches: "%r = add i32 %a, %b\n%s = mul i32 %a, 3",
  },
  {
    title: "Comparison Predicates",
    entries: [
      ["isEquality(p)", "eq or ne"],
      ["isSigned(p)", "slt, sle, sgt or sge"],
      ["isUnsigned(p)", "ult, ule, ugt or uge"],
      ["isLT(p), isGT(p)", "a < or a > predicate"],
      ["isLE(p), isGE(p)", "a <= or a >= predicate"],
      ["swappedPredicate(p)", "for swapped operands. slt → sgt"],
      ["inversePredicate(p)", "the negation. slt → sge"],
      ["strictPredicate(p)", "ule → ult"],
      ["nonStrictPredicate(p)", "ult → ule"],
      ["flippedSignednessPredicate(p)", "slt → ult"],
    ],
    example: "isLT(?pred) && !isUnsigned(?pred)",
    on: "%r = icmp ?pred i32 ?x, ?y",
    matches: "%r = icmp slt i32 %a, %b",
  },
  {
    title: "Value Tracking",
    about: "Asked at the instruction before the constraint, or at a last argument.",
    entries: [
      ['noOverflow("umul", a, b)', 'a * b cannot overflow. Also "smul", "uadd" and others.'],
      ["maskedValueIsZero(v, m)", "v & m is known 0"],
      ["inSignedRange(v, lo, hi)", "v is known in [lo, hi] as signed"],
      ["inUnsignedRange(v, lo, hi)", "v is known in [lo, hi] as unsigned"],
      ["knownBits(v)", "the bits of v known"],
      ["knownZeros(k), knownOnes(k)", "the known zeros or ones"],
      ["numSignBits(v)", "the copies of the sign bit known"],
      ["maxSignificantBits(v)", "the bits v needs as signed"],
      ["isKnownNonZero(v)", "known != 0"],
      ["isKnownNegative(v)", "known < 0"],
      ["isKnownNonNegative(v)", "known >= 0"],
      ["isKnownPositive(v)", "known > 0"],
      ["isKnownPowerOfTwo(v)", "known 2^k"],
      ["isKnownPowerOfTwoOrZero(v)", "known 2^k or 0"],
      ["isGuaranteedNotToBeUndef(v)", "never undef"],
      ["isGuaranteedNotToBePoison(v)", "never poison"],
      ["isGuaranteedNotToBeUndefOrPoison(v)", "never either"],
      ["isKnownNeverNaN(v)", "never a NaN"],
      ["isKnownNeverInfinity(v)", "never an infinity"],
      ["isKnownNeverInfOrNaN(v)", "never either"],
      ["cannotBeNegativeZero(v)", "never -0.0"],
      ["cannotBeOrderedLessThanZero(v)", "never < 0.0"],
    ],
    example: "inUnsignedRange(?x, 0, 255) && isKnownNonZero(?y)",
    on: "%r = add i32 ?x, ?y",
    matches: "%x = and i32 %a, 255\n%y = or i32 %b, 1\n%r = add i32 %x, %y",
  },
];

export const MATCHERS: Group[] = [
  {
    title: "Arithmetic and Bitwise",
    entries: [
      ["addLike", "add or or disjoint"],
      ["neg", "0 - x"],
      ["bitwiseLogic", "and, or or xor"],
      ["shr", "lshr or ashr"],
      ["shift", "shl, lshr or ashr"],
      ["logicalShift", "shl or lshr"],
      ["idiv", "udiv or sdiv"],
      ["irem", "urem or srem"],
      ["signum", "the sign as -1, 0 or 1, from shifts"],
    ],
  },
  {
    title: "Logic of i1s",
    entries: [
      ["logicalAnd", "an and, or select a, b, false"],
      ["logicalOr", "an or, or select a, true, b"],
      ["logicalOp", "either"],
    ],
  },
  {
    title: "Casts",
    entries: [
      ["zextOrSext", "zext or sext"],
      ["sextLike", "sext or zext nneg"],
      ["itofp", "uitofp or sitofp"],
      ["fptoi", "fptoui or fptosi"],
      ["ptrToIntOrAddr", "ptrtoint or ptrtoaddr"],
    ],
  },
  {
    title: "Selects, Compares and Min/Max",
    entries: [
      ["maxOrMin", "a call of smax, smin, umax or umin"],
      ["selectMinMax", "a min or max, as icmp and select"],
      ["signBitCheck", "an icmp that tests the sign bit"],
      ["selectEq", "select on x == y or x != y"],
      ["selectEqZero", "select on x == 0 or x != 0"],
    ],
  },
  { title: "Floating Point", entries: [["fnegLike", "fneg or fsub from -0.0"]] },
];

export const SETTINGS: { setting: string; says: string }[] = [
  {
    setting: ";; treatIntAsVec(true)",
    says: "From here on, a scalar integer type or constant matches a vector of them too.",
  },
];

export interface Idiom {
  /** InstCombine's code, with PatternMatch.h. */
  llvm: string;
  /** The same, as a pattern. */
  pattern: string;
  /** Instructions it matches, as a Demo has, in a module that declares
   * IDIOM_DECLARATIONS. */
  matches: string;
  /** What is easy to miss. */
  note?: string;
}

/** What the idioms' instructions call. */
export const IDIOM_DECLARATIONS = [
  "declare i32 @llvm.ctpop.i32(i32)",
  "declare i32 @llvm.ctlz.i32(i32, i1)",
  "declare i32 @llvm.smax.i32(i32, i32)",
  "declare i32 @llvm.umin.i32(i32, i32)",
].join("\n");

export const IDIOMS: Idiom[] = [
  {
    llvm: "m_Add(m_Value(X), m_Value(Y))",
    pattern: "%r = add ?ty ?x, ?y",
    matches: "%r = add i32 %a, %b",
  },
  {
    llvm: "m_Add(m_Value(X), m_Deferred(X))",
    pattern: "%r = add ?ty ?x, ?x",
    matches: "%r = add i32 %a, %a",
    note: "A meta variable used again is m_Deferred.",
  },
  {
    llvm: "m_c_Add(m_Value(X), m_ConstantInt(C))",
    pattern: "%r = add:c ?ty ?x, ?c:constantInt",
    matches: "%r = add i32 1, %a",
  },
  {
    llvm: "m_NSWAdd(m_Value(X), m_Value(Y))",
    pattern: "%r = add nsw ?ty ?x, ?y",
    matches: "%r = add nsw i32 %a, %b",
  },
  {
    llvm: "m_DisjointOr(m_Value(X), m_Value(Y))",
    pattern: "%r = or disjoint ?ty ?x, ?y",
    matches: "%r = or disjoint i32 %a, %b",
  },
  {
    llvm: "m_AddLike(m_Value(X), m_Value(Y))",
    pattern: "%r = addLike ?ty ?x, ?y",
    matches: "%r = or disjoint i32 %a, %b",
    note: "An or disjoint matches too.",
  },
  {
    llvm: "m_Add(m_Value(X), m_One())",
    pattern: "%r = add i?n ?x, 1",
    matches: "%r = add i32 %a, 1",
  },
  {
    llvm: "m_And(m_Value(X), m_APInt(C))",
    pattern: "%r = and i?n ?x, ?c:apInt",
    matches: "%r = and i32 %a, 7",
  },
  {
    llvm: "m_And(m_Value(X), m_APInt(C)), on a vector",
    pattern: ";; treatIntAsVec(true)\n%r = and i?n ?x, ?c:apInt",
    matches: "%r = and <4 x i32> %v, splat (i32 7)",
    note: "treatIntAsVec lets i?n match a vector, and ?c a splat.",
  },
  {
    llvm: "m_And(m_Value(X), m_APIntAllowPoison(C))",
    pattern: ";; treatIntAsVec(true)\n%r = and i?n ?x, ?c:apIntAllowPoison",
    matches: "%r = and <4 x i32> %v, <i32 7, i32 poison, i32 7, i32 7>",
    note: ":apInt rejects the poison lane. :apIntAllowPoison does not.",
  },
  {
    llvm: "m_And(m_Value(X), m_Power2(C))",
    pattern: "%r = and i?n ?x, ?c:power2",
    matches: "%r = and i32 %a, 8",
  },
  {
    llvm: "m_LShr(m_Value(X), m_SpecificInt(BitWidth - 1))",
    pattern: "%r = lshr i?n ?x, ?c\n;; ?c == ?n - 1",
    matches: "%r = lshr i32 %a, 31",
  },
  {
    llvm: "m_Not(m_Value(X))",
    pattern: "%r = xor:c ?ty ?x, ?m:allOnes",
    matches: "%r = xor i32 -1, %a",
    note: "m_Not takes the -1 on either side.",
  },
  {
    llvm: "m_c_And(m_Value(X), m_Not(m_Value(Y)))",
    pattern: "%n = xor:c ?ty ?y, ?_m:allOnes\n%r = and:c ?ty ?x, %n",
    matches: "%n = xor i32 %b, -1\n%r = and i32 %n, %a",
    note: "?_m is left out of the results.",
  },
  {
    llvm: "m_Neg(m_Value(X))",
    pattern: "%r = neg ?ty ?x",
    matches: "%r = sub i32 0, %a",
  },
  {
    llvm: "m_NSWNeg(m_Value(X))",
    pattern: "%r = neg nsw ?ty ?x",
    matches: "%r = sub nsw i32 0, %a",
  },
  {
    llvm: "m_OneUse(m_Shl(m_Value(X), m_Value(Y)))",
    pattern: "%r = shl:s ?ty ?x, ?y",
    matches: "%r = shl i32 %a, %b\n%u = add i32 %r, 1",
  },
  {
    llvm: "Shl->hasOneUser()",
    pattern: "%r = shl:su ?ty ?x, ?y",
    matches: "%r = shl i32 %a, %b\n%u = mul i32 %r, %r",
    note: "%r has two uses but one user. So :s would not match.",
  },
  {
    llvm: "m_Exact(m_LShr(m_Value(X), m_Value(Y)))",
    pattern: "%r = lshr exact ?ty ?x, ?y",
    matches: "%r = lshr exact i32 %a, %b",
  },
  {
    llvm: "m_Shr(m_Value(X), m_Value(Y))",
    pattern: "%r = shr ?ty ?x, ?y",
    matches: "%r = ashr i32 %a, %b",
  },
  {
    llvm: "m_ZExt(m_Trunc(m_Value(X)))",
    pattern: "%t = trunc ?big ?x to ?small\n%r = zext ?small %t to ?big",
    matches: "%t = trunc i64 %w to i32\n%r = zext i32 %t to i64",
  },
  {
    llvm: "m_NUWTrunc(m_Value(X))",
    pattern: "%r = trunc nuw ?big ?x to ?small",
    matches: "%r = trunc nuw i64 %w to i32",
  },
  {
    llvm: "m_ZExtOrSelf(m_Value(X))",
    pattern: "%r = zext:o ?_small ?x to ?ty\n%u = add ?ty %r, ?y",
    matches: "%u = add i32 %a, %b",
    note: "Here there is no zext. :o matches its operand alone.",
  },
  {
    llvm: "m_NNegZExt(m_Value(X))",
    pattern: "%r = zext nneg ?small ?x to ?big",
    matches: "%r = zext nneg i8 %c to i32",
  },
  {
    llvm: "m_SExtLike(m_Value(X))",
    pattern: "%r = sextLike ?small ?x to ?big",
    matches: "%r = zext nneg i8 %c to i32",
    note: "A zext nneg is a sext too.",
  },
  {
    llvm: "m_ZExtOrSExt(m_Value(X))",
    pattern: "%r = zextOrSext ?small ?x to ?big",
    matches: "%r = sext i8 %c to i32",
  },
  {
    llvm: "m_ICmp(Pred, m_Value(X), m_Value(Y))",
    pattern: "%r = icmp ?pred ?ty ?x, ?y",
    matches: "%r = icmp slt i32 %a, %b",
  },
  {
    llvm: "m_c_ICmp(Pred, m_Value(X), m_Zero())",
    pattern: "%r = icmp:c ?pred i?n ?x, 0",
    matches: "%r = icmp sgt i32 0, %a",
    note: "Swapped, it binds ?pred to slt: the predicate in the pattern's order.",
  },
  {
    llvm: "m_SpecificICmp(ICmpInst::ICMP_EQ, m_Value(X), m_Zero())",
    pattern: "%r = icmp eq i?n ?x, 0",
    matches: "%r = icmp eq i32 %a, 0",
  },
  {
    llvm: "m_ICmp(Pred, m_Value(X), m_Value(Y)) && ICmpInst::isEquality(Pred)",
    pattern: "%r = icmp ?pred ?ty ?x, ?y\n;; isEquality(?pred)",
    matches: "%r = icmp ne i32 %a, %b",
  },
  {
    llvm: "m_Select(m_Value(C), m_Value(T), m_Value(F))",
    pattern: "%r = select i1 ?c, ?ty ?t, ?ty ?f",
    matches: "%k = icmp eq i32 %a, 0\n%r = select i1 %k, i32 %a, i32 %b",
  },
  {
    llvm: "m_LogicalAnd(m_Value(A), m_Value(B))",
    pattern: "%r = logicalAnd i1 ?a, ?b",
    matches: "%k = icmp eq i32 %a, 0\n%j = icmp eq i32 %b, 0\n%r = select i1 %k, i1 %j, i1 false",
    note: "A select of false is a logical and too.",
  },
  {
    llvm: "m_SMax(m_Value(X), m_Value(Y))",
    pattern: "%r = call ?ty @llvm.smax(?ty ?x, ?ty ?y)",
    matches: "%r = call i32 @llvm.smax.i32(i32 %a, i32 %b)",
  },
  {
    llvm: "m_MaxOrMin(m_Value(X), m_Value(Y))",
    pattern: "%r = maxOrMin ?ty ?x, ?y",
    matches: "%r = call i32 @llvm.umin.i32(i32 %a, i32 %b)",
  },
  {
    llvm: "m_Intrinsic<Intrinsic::ctpop>(m_Value(X))",
    pattern: "%r = call i?n @llvm.ctpop(i?n ?x)",
    matches: "%r = call i32 @llvm.ctpop.i32(i32 %a)",
  },
  {
    llvm: "m_Intrinsic<Intrinsic::ctlz>(m_Value(X), m_Zero())",
    pattern: "%r = call i?n @llvm.ctlz(i?n ?x, i1 false)",
    matches: "%r = call i32 @llvm.ctlz.i32(i32 %a, i1 false)",
    note: "An argument can be fixed, as m_Zero fixes it.",
  },
  {
    llvm: "m_Shuffle(m_Value(V), m_Poison(), m_ZeroMask())",
    pattern: "%r = shufflevector <4 x i32> ?v, <4 x i32> poison, <4 x i32> zeroinitializer",
    matches: "%r = shufflevector <4 x i32> %v, <4 x i32> poison, <4 x i32> zeroinitializer",
  },
  {
    llvm: "m_InsertElt(m_Poison(), m_Value(X), m_ZeroInt())",
    pattern: "%r = insertelement <4 x i32> poison, i32 ?x, i64 0",
    matches: "%r = insertelement <4 x i32> poison, i32 %a, i64 0",
  },
  {
    llvm: "X->hasNUses(2)",
    pattern: "%r = add ?ty ?x, ?y\n;; hasNUses(?x, 2)",
    matches: "%r = add i32 %a, %b\n%s = mul i32 %a, 3",
  },
  {
    llvm: "isKnownNegative(Y, SQ)",
    pattern: "%r = udiv ?ty ?x, ?y:knownNegative",
    matches: "%n = or i32 %a, -2147483648\n%r = udiv i32 %b, %n",
  },
  {
    llvm: "isKnownToBeAPowerOfTwo(Y, /*OrZero=*/true)",
    pattern: "%r = and ?ty ?x, ?y:knownPowerOfTwoOrZero",
    matches: "%p = shl i32 1, %b\n%r = and i32 %a, %p",
  },
  {
    llvm: "MaskedValueIsZero(X, APInt::getHighBitsSet(32, 24))",
    pattern: "%r = add i32 ?x, ?y\n;; maskedValueIsZero(?x, -256)",
    matches: "%x = and i32 %a, 255\n%r = add i32 %x, %b",
  },
  {
    llvm: "computeKnownBits(X, SQ).countMinTrailingZeros() >= 2",
    pattern: "%r = add ?ty ?x, ?y\n;; uge(countr_one(knownZeros(knownBits(?x))), 2)",
    matches: "%x = shl i32 %a, 2\n%r = add i32 %x, %b",
  },
  {
    llvm: "willNotOverflowUnsignedMul(Y, Z, I)",
    pattern: '%r = mul ?ty ?y, ?z\n;; noOverflow("umul", ?y, ?z)',
    matches: "%y = and i32 %a, 255\n%z = and i32 %b, 255\n%r = mul i32 %y, %z",
  },
  {
    llvm: "m_FNeg(m_Value(X))",
    pattern: "%r = fnegLike ?ty ?x",
    matches: "%f = sitofp i32 %a to float\n%r = fsub float -0.0, %f",
    note: "An fsub from -0.0 is an fneg too.",
  },
];
