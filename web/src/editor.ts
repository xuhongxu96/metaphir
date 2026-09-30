// What the page's Monaco editors share: their options, and hooks to
// highlight lines and follow the mouse.

import type { OnMount } from "@monaco-editor/react";
import { useEffect, useMemo, useRef } from "react";
import type { Definition } from "./irDefinition.ts";
import { monaco } from "./monaco.ts";
import type { NavLink } from "./navigation.ts";

export type CodeEditor = Parameters<OnMount>[0];

export const EDITOR_OPTIONS = {
  minimap: { enabled: false },
  fontSize: 13,
  scrollBeyondLastLine: false,
  automaticLayout: true,
  renderLineHighlight: "none" as const,
  wordWrap: "on" as const,
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
export function useModifierLinks(
  editor: CodeEditor | undefined,
  resolve: (line: number, column: number, text: string) => NavLink | undefined,
  go: (to: Definition) => void,
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
      if (found) callbacks.current.go(found.link.to);
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
