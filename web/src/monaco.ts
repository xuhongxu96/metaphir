// Monaco, bundled with the site: the editor with the contributions it uses
// (and none of its languages), for @monaco-editor/react.

import { loader } from "@monaco-editor/react";
import * as monaco from "monaco-editor/editor/editor.api";
import "monaco-codicon.css";
import "monaco-editor/editor/contrib/bracketMatching/browser/bracketMatching";
import "monaco-editor/editor/contrib/clipboard/browser/clipboard";
import "monaco-editor/editor/contrib/comment/browser/comment";
import "monaco-editor/editor/contrib/contextmenu/browser/contextmenu";
import "monaco-editor/editor/contrib/cursorUndo/browser/cursorUndo";
import "monaco-editor/editor/contrib/find/browser/findController";
import "monaco-editor/editor/contrib/folding/browser/folding";
import "monaco-editor/editor/contrib/linesOperations/browser/linesOperations";
import "monaco-editor/editor/contrib/multicursor/browser/multicursor";
import "monaco-editor/editor/contrib/wordHighlighter/browser/wordHighlighter";
import "monaco-editor/editor/contrib/wordOperations/browser/wordOperations";
import EditorWorker from "monaco-editor/editor/editor.worker?worker";
import { registerLanguages } from "./languages.ts";

self.MonacoEnvironment = { getWorker: () => new EditorWorker() };
registerLanguages(monaco);
loader.config({ monaco });

export const themeName = (dark: boolean) => (dark ? "metaphir-dark" : "metaphir-light");
export { monaco };
