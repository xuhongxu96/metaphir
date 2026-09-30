// What the page's Monaco editors share: their options, and hooks to
// highlight lines and follow the mouse.

import type { OnMount } from "@monaco-editor/react";
import { useEffect, useMemo, useRef } from "react";
import { monaco } from "./monaco.ts";

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
