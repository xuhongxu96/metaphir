// What the page's Monaco editors share: their options, and hooks to
// highlight lines and follow the mouse.

import type { OnMount } from "@monaco-editor/react";
import { useEffect, useMemo, useRef } from "react";
import { PAGE_SCHEME, type Diagnostic } from "./diagnostics.ts";
import type { Definition } from "./irDefinition.ts";
import { monaco } from "./monaco.ts";
import { irLink, linkLines, type Link, type NavLink } from "./navigation.ts";

export type CodeEditor = Parameters<OnMount>[0];

export const EDITOR_OPTIONS = {
  minimap: { enabled: false },
  fontSize: 13,
  scrollBeyondLastLine: false,
  automaticLayout: true,
  renderLineHighlight: "none" as const,
  wordWrap: "on" as const,
  // Hovers are fixed in the page, so that a pane does not clip them.
  fixedOverflowWidgets: true,
  // Monaco's default but for the sigils and '.' that names have (?x, %a.b,
  // @llvm.abs), so that double-clicking, Ctrl/⌘+arrows and changing all
  // occurrences (Ctrl/⌘+F2) take a whole name; see also languages.ts.
  wordSeparators: "`~!#^&*()-=+[{]}\\|;:'\",<>/",
};

/**
 * Keeps whole-line decorations on editor: className on lines, and
 * "hovered-line" as well on those of them hovered. With reveal, the first
 * line is brought into view when the lines change.
 */
export function useLineDecorations(
  editor: CodeEditor | undefined,
  lines: number[],
  hovered: number[],
  className: string,
  reveal: boolean,
) {
  // Each editor has its own collection: a new run can mount a new one.
  const collection = useMemo(() => editor?.createDecorationsCollection(), [editor]);
  useEffect(() => {
    if (!collection) return;
    const hover = new Set(hovered);
    collection.set(
      [...new Set(lines)].map((line) => ({
        range: new monaco.Range(line, 1, line, 1),
        options: {
          isWholeLine: true,
          className: hover.has(line) ? `${className} hovered-line` : className,
          overviewRuler: {
            color: "#2f81f7",
            position: monaco.editor.OverviewRulerLane.Full,
          },
        },
      })),
    );
  }, [collection, lines, hovered, className]);
  useEffect(() => {
    if (editor && reveal && lines.length) editor.revealLineInCenterIfOutsideViewport(Math.min(...lines));
  }, [editor, lines, reveal]);
}

/** Whether event holds the key of links: Ctrl, or ⌘ on a Mac. */
const linkKey = (event: { ctrlKey: boolean; metaKey: boolean }) =>
  event.ctrlKey || event.metaKey;

/**
 * Makes links of editor, as resolve finds them where the mouse is: while
 * Ctrl (⌘ on a Mac) is held, what a link goes from is underlined, and
 * clicking it calls go with where it goes to.
 */
export function useModifierLinks<L extends NavLink>(
  editor: CodeEditor | undefined,
  resolve: (line: number, column: number, text: string) => L | undefined,
  go: (to: Definition, link: L) => void,
) {
  const callbacks = useRef({ resolve, go });
  callbacks.current = { resolve, go };
  const collection = useMemo(() => editor?.createDecorationsCollection(), [editor]);
  useEffect(() => {
    if (!editor || !collection) return;
    let mouse: { lineNumber: number; column: number } | undefined;
    const linkAt = () => {
      const model = editor.getModel();
      if (!mouse || !model) return undefined;
      const text = model.getLineContent(mouse.lineNumber);
      const link = callbacks.current.resolve(mouse.lineNumber, mouse.column, text);
      return link && { line: mouse.lineNumber, link };
    };
    const underline = (held: boolean) => {
      const found = held ? linkAt() : undefined;
      collection.set(
        found
          ? [
              {
                range: new monaco.Range(
                  found.line,
                  found.link.from.column,
                  found.line,
                  found.link.from.column + found.link.from.length,
                ),
                options: { inlineClassName: "modifier-link" },
              },
            ]
          : [],
      );
    };
    const moves = editor.onMouseMove((event) => {
      mouse = event.target.position ?? undefined;
      underline(linkKey(event.event));
    });
    const leaves = editor.onMouseLeave(() => {
      mouse = undefined;
      underline(false);
    });
    const downs = editor.onMouseDown((event) => {
      if (!linkKey(event.event)) return;
      mouse = event.target.position ?? undefined;
      const found = linkAt();
      if (found) callbacks.current.go(found.link.to, found.link);
    });
    // The key can be pressed or let go without the mouse moving.
    const onKey = (event: KeyboardEvent) => underline(linkKey(event));
    const onBlur = () => underline(false);
    window.addEventListener("keydown", onKey);
    window.addEventListener("keyup", onKey);
    window.addEventListener("blur", onBlur);
    return () => {
      moves.dispose();
      leaves.dispose();
      downs.dispose();
      window.removeEventListener("keydown", onKey);
      window.removeEventListener("keyup", onKey);
      window.removeEventListener("blur", onBlur);
      collection.clear();
    };
  }, [editor, collection]);
}

/**
 * Reports the line under the mouse in editor, or undefined once it leaves.
 */
export function useHoveredLine(
  editor: CodeEditor | undefined,
  onLine: (line: number | undefined) => void,
) {
  const callback = useRef(onLine);
  callback.current = onLine;
  useEffect(() => {
    if (!editor) return;
    const moves = editor.onMouseMove((event) =>
      callback.current(event.target.position?.lineNumber),
    );
    const leaves = editor.onMouseLeave(() => callback.current(undefined));
    return () => {
      moves.dispose();
      leaves.dispose();
    };
  }, [editor]);
}

const SEVERITIES = {
  error: monaco.MarkerSeverity.Error,
  warning: monaco.MarkerSeverity.Warning,
  info: monaco.MarkerSeverity.Info,
};

/** Shows diagnostics as markers on editor: a squiggle under the word each
 * points at, with its message on hover. */
export function useMarkers(editor: CodeEditor | undefined, diagnostics: Diagnostic[]) {
  useEffect(() => {
    const model = editor?.getModel();
    if (!model) return;
    monaco.editor.setModelMarkers(
      model,
      "metaphir",
      diagnostics.map((d) => ({
        severity: SEVERITIES[d.severity],
        message: d.message,
        code: d.link && { value: d.link.text, target: monaco.Uri.parse(d.link.target) },
        startLineNumber: d.line,
        startColumn: d.column,
        endLineNumber: d.line,
        endColumn: tokenEnd(model, d.line, d.column),
      })),
    );
    return () => monaco.editor.setModelMarkers(model, "metaphir", []);
  }, [editor, diagnostics]);
}

/** Opens the page's own links (PAGE_SCHEME) with open, given their path. */
export function useLinkOpener(open: (path: string) => void) {
  const current = useRef(open);
  current.current = open;
  useEffect(() => {
    const opener = monaco.editor.registerLinkOpener({
      open(uri) {
        if (uri.scheme !== PAGE_SCHEME) return false;
        current.current(uri.path);
        return true;
      },
    });
    return () => opener.dispose();
  }, []);
}

/** The column after the token at line and column of model, such as a meta
 * variable '?a' or a value '%r'; Monaco's words leave out their sigils. */
function tokenEnd(model: monaco.editor.ITextModel, line: number, column: number): number {
  if (line < 1 || line > model.getLineCount()) return column;
  const text = model.getLineContent(line);
  const token = /^[\w?%@.$:-]+/.exec(text.slice(column - 1));
  return column + (token ? token[0].length : 1);
}

/** Selects to in editor, in view, and focuses it. */
export function selectRange(editor: CodeEditor, to: Definition) {
  const range = new monaco.Range(to.line, to.column, to.line, to.column + to.length);
  editor.setSelection(range);
  editor.revealRangeInCenterIfOutsideViewport(range);
  editor.focus();
}

/** Selects target in editor each time it is set anew (a new object). */
export function useJumpTarget(editor: CodeEditor | undefined, target: Definition | undefined) {
  useEffect(() => {
    if (editor && target) selectRange(editor, target);
    // Only a new target is gone to, not the same once the editor changes.
  }, [target]);
}

/**
 * What an editor showing IR does with a match's links, while they hold
 * (linked): highlights the instructions they matched, and those hovered;
 * reports the line hovered; and goes from a value Ctrl/⌘+clicked to its
 * definition in text. Returns the lines highlighted.
 */
export function useIRLinks(
  editor: CodeEditor | undefined,
  text: string | undefined,
  links: Link[],
  hovered: Link[],
  linked: boolean,
  onHover: (line: number | undefined) => void,
): number[] {
  const lines = useMemo(() => (linked ? linkLines(links, "irLine") : []), [links, linked]);
  const hoveredLines = useMemo(
    () => (linked ? linkLines(hovered, "irLine") : []),
    [hovered, linked],
  );
  useLineDecorations(editor, lines, hoveredLines, "bound-line", true);
  useHoveredLine(editor, onHover);
  useModifierLinks(
    editor,
    (_, column, line) => (text !== undefined ? irLink({ column, text: line, ir: text }) : undefined),
    (to) => editor && selectRange(editor, to),
  );
  return lines;
}
