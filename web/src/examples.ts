// The examples: the patterns of the evaluation (eval/patterns), each of a
// fold an LLVM pull request added, named by what it folds.

/** What each pattern, by its file's name, folds. */
const TITLES: Record<string, string> = {
  pr204089: "zext/sext(trunc nuw/nsw X) → X",
  pr204927: "zext(logic(trunc nuw X, Y)) → logic(X, zext Y)",
  pr204928: "sext(logic(trunc nsw X, Y)) → logic(X, sext Y)",
  pr205383_sub: "(bw − 1) − ctlz(X & −X) → cttz(X)",
  pr205383_xor: "(bw − 1) ^ ctlz(X & −X) → cttz(X)",
  pr207462: "(X & 1) + (X >> 1) → X − (X >> 1)",
  pr207462_mul: "(X urem C) + ((X udiv C) << K) → X + (X udiv C) * (2^K − C)",
  pr207564: "zext(−trunc X) → (−X) & mask",
  pr209322: "X udiv Y, Y known negative → zext(X u>= Y)",
  pr210499: "trunc(shr exact X, Y) to i1 → X != 0",
  pr212132_case1: "(A & S) == 0 || (B & S) == 0 → (A & B & S) == 0, S a power of 2",
  pr212132_case2: "(A & S) != 0 && (B & S) != 0 → (A & B & S) != 0, S a power of 2",
  pr213313: "zext(X) & sext(X) → zext(X); zext(X) | sext(X) → sext(X)",
  pr213709: "(X & −X) == C → X == 0 or trunc X, C 0 or 1",
  pr214376: "cttz(X * C) → cttz(X), C odd",
  pr214381: "(X − X urem D) u> C → X u> D − 1, C u< D",
  pr214517: "1 << cttz(X) → −X & X",
  pr214541: "(X udiv Y) udiv Z → X udiv (Y * Z)",
  pr215122: "X + (−X & (C − 1)) → (X + C − 1) & −C, C a power of 2",
  pr215130: "uadd.sat(X, C) − C → umin(X, ~C)",
  pr216046: "scmp(X, 0) → sext or trunc X, X in [−1, 1]",
  pr216436: "((X − 1) | (C − 1)) + 1 → (X + C − 1) & −C, C a power of 2",
  pr216470: "(X >> K) + zext((X & M) != 0) → (X + M) >> K, in a wider type",
};

/** The pull request of the pattern named name, such as 204089. */
export function pullRequest(name: string): number | undefined {
  const number = /^pr(\d+)/.exec(name)?.[1];
  return number === undefined ? undefined : Number(number);
}

/** The pull request's page. */
export const pullRequestUrl = (number: number) =>
  `https://github.com/llvm/llvm-project/pull/${number}`;

/** What the example named name is called in the page: what it folds, and
 * its pull request. */
export function exampleLabel(name: string): string {
  const pr = pullRequest(name);
  const title = TITLES[name] ?? name;
  return pr === undefined ? title : `${title} (#${pr})`;
}

/** Whether the pattern named name has a title. */
export const hasTitle = (name: string) => name in TITLES;
