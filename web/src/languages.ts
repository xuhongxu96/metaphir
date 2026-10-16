// Syntax highlighting for MetaphIR patterns and LLVM IR in Monaco.

import type * as Monaco from "monaco-editor/editor/editor.api";
import instructionMatchers from "../../metaphir/IR/InstructionMatchers.def?raw";
import keywordDefs from "../../metaphir/Parser/MIRKeywords.def?raw";
import constantDefs from "../../metaphir/IR/KeywordConstants.def?raw";

/** The names a .def file lists with macro, as its first argument. */
function namesOf(def: string, macro: string): string[] {
  const pattern = new RegExp(`^${macro}\\(\\s*([A-Za-z_.0-9]+)`, "gm");
  return [...def.matchAll(pattern)].map((m) => m[1]);
}

const instructions = namesOf(instructionMatchers, "MIR_INSTRUCTION_MATCHER");
const keywords = [
  ...namesOf(keywordDefs, "MIR_KEYWORD"),
  // Constant keywords are listed by ID, then spelling.
  ...[...constantDefs.matchAll(/^MIR_\w*_KEYWORD\(\s*\w+\s*,\s*([\w.]+)/gm)].map(
    (m) => m[1],
  ),
];

const metaphir: Monaco.languages.IMonarchLanguage = {
  instructions,
  keywords,
  tokenizer: {
    root: [
      // Constraints and settings follow ';;'; other ';' lines are comments.
      [/;;/, { token: "keyword.constraint", next: "@constraint" }],
      [/;.*$/, "comment"],
      // A negated flag, as in 'add !nsw'.
      [/!(?=[A-Za-z])/, "operator"],
      { include: "@common" },
    ],
    constraint: [
      [/$/, { token: "", next: "@pop" }],
      [/(&&|\|\||==|!=|[<>]=?|[-+*!])/, "operator"],
      { include: "@common" },
    ],
    common: [
      [/\?[A-Za-z_][\w.]*/, "variable.meta"],
      [/%[-\w.$]+/, "variable.local"],
      [/@[-\w.$]+/, "variable.global"],
      [/:[A-Za-z_?][\w?]*/, "annotation"],
      [/\bi(\?[A-Za-z_]\w*|\d+)\b/, "type"],
      [/\b(ptr|void|half|bfloat|float|double|fp128|x86_fp80|label)\b/, "type"],
      [
        /[A-Za-z_][\w.]*/,
        {
          cases: {
            "@instructions": "keyword.instruction",
            "@keywords": "keyword",
            "@default": "identifier",
          },
        },
      ],
      [/-?\d+(\.\d+)?/, "number"],
      [/"([^"\\]|\\.)*"/, "string"],
      [/[{}()[\]<>]/, "delimiter.bracket"],
    ],
  },
};

const llvm: Monaco.languages.IMonarchLanguage = {
  keywords: [
    "define", "declare", "global", "constant", "private", "internal", "external",
    "linkonce_odr", "weak_odr", "dso_local", "unnamed_addr", "local_unnamed_addr",
    "align", "nuw", "nsw", "exact", "disjoint", "nneg", "inbounds", "fast", "nnan",
    "ninf", "nsz", "arcp", "contract", "afn", "reassoc", "to", "tail", "musttail",
    "notail", "volatile", "atomic", "true", "false", "null", "undef", "poison",
    "zeroinitializer", "label", "eq", "ne", "ugt", "uge", "ult", "ule", "sgt", "sge",
    "slt", "sle", "oeq", "one", "olt", "ole", "ogt", "oge", "ord", "uno", "ueq", "une",
  ],
  tokenizer: {
    root: [
      [/;.*$/, "comment"],
      [/%[-\w.$]+|%"[^"]*"/, "variable.local"],
      [/@[-\w.$]+|@"[^"]*"/, "variable.global"],
      [/![\w.]+/, "annotation"],
      [/#\d+/, "annotation"],
      [/\bi\d+\b/, "type"],
      [/\b(ptr|void|half|bfloat|float|double|fp128|x86_fp80|label|metadata)\b/, "type"],
      [/^\s*[\w.]+:/, "tag"],
      [
        /[A-Za-z_][\w.]*/,
        { cases: { "@keywords": "keyword", "@default": "keyword.instruction" } },
      ],
      [/-?\d+(\.\d+)?(e[-+]?\d+)?/, "number"],
      [/c?"([^"\\]|\\.)*"/, "string"],
    ],
  },
};

// InstCombine's C++, as the pattern guide shows it: PatternMatch.h's matchers
// colored as the instructions they match, and what they bind as meta
// variables.
const cpp: Monaco.languages.IMonarchLanguage = {
  tokenizer: {
    root: [
      [/\/\/.*$/, "comment"],
      [/"([^"\\]|\\.)*"/, "string"],
      [/\bm_\w+/, "keyword.instruction"],
      [/\b(if|return|auto|const|true|false)\b/, "keyword"],
      [/\b[A-Z]\w*(?=::)/, "type"],
      [/\b(X|Y|Z|A|B|C|T|F|Pred|Op\d|I)\b/, "variable.meta"],
      [/-?\d+/, "number"],
      [/(&&|\|\||==|!=|->|[-+*!<>])/, "operator"],
    ],
  },
};

const rules = (dark: boolean): Monaco.editor.ITokenThemeRule[] => [
  { token: "keyword.instruction", foreground: dark ? "7ea6f0" : "2f5fb3", fontStyle: "bold" },
  { token: "keyword.constraint", foreground: dark ? "d7a35f" : "9a5b00" },
  { token: "variable.meta", foreground: dark ? "e08fd0" : "a0308f" },
  { token: "variable.local", foreground: dark ? "9fd39b" : "2e7d32" },
  { token: "variable.global", foreground: dark ? "e6b673" : "8a5a00" },
  { token: "annotation", foreground: dark ? "a0a0a0" : "6b6b66" },
  { token: "type", foreground: dark ? "63c5d6" : "00798a" },
];

export function registerLanguages(monaco: typeof Monaco): void {
  for (const [id, language] of [["metaphir", metaphir], ["llvm", llvm], ["cpp", cpp]] as const) {
    monaco.languages.register({ id });
    monaco.languages.setMonarchTokensProvider(id, language);
  }
  // A name is one word with its sigil, so that the editors highlight its
  // occurrences, and change them all (Ctrl/⌘+F2), as a whole: ?x, %x, @x,
  // %"a b". A pattern's names never contain '-' (?bits-1 is a subtraction);
  // LLVM's may, and it has metadata (!x) and attribute groups (#0) too.
  monaco.languages.setLanguageConfiguration("metaphir", {
    comments: { lineComment: ";" },
    brackets: [["{", "}"], ["(", ")"], ["[", "]"], ["<", ">"]],
    wordPattern: /[?%@](?:"[^"]*"|[\w.$]+)|[\w.$]+/g,
  });
  monaco.languages.setLanguageConfiguration("llvm", {
    comments: { lineComment: ";" },
    brackets: [["{", "}"], ["(", ")"], ["[", "]"], ["<", ">"]],
    wordPattern: /[%@!](?:"[^"]*"|[-\w.$]+)|#\d+|[\w.$]+/g,
  });
  monaco.editor.defineTheme("metaphir-light", {
    base: "vs",
    inherit: true,
    rules: rules(false),
    colors: { "editor.background": "#ffffff" },
  });
  monaco.editor.defineTheme("metaphir-dark", {
    base: "vs-dark",
    inherit: true,
    rules: rules(true),
    colors: { "editor.background": "#0d1117", "editorGutter.background": "#0d1117" },
  });
}
