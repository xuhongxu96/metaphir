// The tokens of MetaphIR patterns that share links (patternCompress.ts)
// write as one byte each: 0x80 plus their index. As in
// instcombine-instrumentor's links, with MetaphIR's own tokens: variables,
// meta-flags, matchers and the functions of constraints, next to LLVM's.
//
// wordBoundary tokens are written as a byte only between characters that
// are not of words ("add", not in "%add_result"); the others are wherever
// they are. Either way the text comes back as it was.
//
// Links carry the version of this list (patternCompress.ts): reordering or
// removing tokens needs a new version, adding tokens at the end does not.

export interface DictEntry {
  readonly token: string;
  readonly wordBoundary: boolean;
}

/** Bytes 0x80 to 0xFE; 0xFF is kept to extend the list, one day. */
export const DICT_MAX_ENTRIES = 127;

const fragments = (...tokens: string[]) => tokens.map((token) => ({ token, wordBoundary: false }));
const words = (...tokens: string[]) => tokens.map((token) => ({ token, wordBoundary: true }));

export const DICTIONARY: ReadonlyArray<DictEntry> = [
  // Syntax.
  ...fragments(";; ", " = ", ", ", "\n%", " == ", " != ", " && ", " || ", " to "),
  // Types and variables, as the examples name them.
  ...fragments("i?bits", " i?", "?bits", "?anch", "?small", "?big", "?_", "?pred", "?shift"),
  ...fragments("?x", "?y", "?a", "?b", "?c"),
  // Meta-flags and matchers.
  ...fragments(":?anch", ":?_", ":c", ":s", ":o", ":or(", ":not(", ":constantInt"),
  ...fragments(":constantSplat", ":lowBitMask", ":knownPowerOfTwo"),
  // Settings and the functions of constraints.
  ...fragments("treatIntAsVec(true)", "hasOneUse(", "noOverflow(", "opcode(", "isPowerOfTwo("),
  ...fragments("isZero(", "isAllOnes(", "isLowBitMask(", "isGuaranteedNotToBeUndef("),
  ...fragments("inSignedRange(", "knownBits(", "isKnownNonZero(", "isKnownNegative("),
  ...fragments("isKnownNonNegative(", "isKnownPositive(", "isKnownPowerOfTwo("),
  ...fragments("maskedValueIsZero(", "popcount(", "@llvm."),
  // Opcodes.
  ...words("add", "sub", "mul", "udiv", "sdiv", "urem", "srem", "shl", "lshr", "ashr"),
  ...words("and", "or", "xor", "neg", "not", "icmp", "select", "trunc", "zext", "sext"),
  ...words("call", "phi", "freeze", "load", "store", "getelementptr", "ret", "br"),
  ...words("bitcast", "ptrtoint", "inttoptr", "fadd", "fsub", "fmul", "fdiv", "fneg", "fcmp"),
  // Flags, predicates, types and constants.
  ...words("nsw", "nuw", "exact", "disjoint", "nneg", "samesign", "inbounds"),
  ...words("eq", "ne", "ult", "ule", "ugt", "uge", "slt", "sle", "sgt", "sge"),
  ...words("i1", "i8", "i16", "i32", "i64", "ptr", "true", "false", "poison", "undef"),
  ...words("null", "zeroinitializer"),
  // Intrinsics.
  ...words("ctlz", "cttz", "ctpop", "umin", "umax", "smin", "smax", "abs"),
];

if (DICTIONARY.length > DICT_MAX_ENTRIES)
  throw new Error(`the dictionary has ${DICTIONARY.length} tokens, more than ${DICT_MAX_ENTRIES}`);
