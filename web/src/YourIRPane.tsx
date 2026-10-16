// The IR the pattern is matched in, written in the page: an editor with the
// selected match's bindings above it, and while the IR is as matched, the
// instructions the match matched highlighted and the IR's errors marked.

import Editor from "@monaco-editor/react";
import { useEffect, useMemo, useState } from "react";
import { BindingList } from "./BindingList.tsx";
import type { Diagnostic } from "./diagnostics.ts";
import {
  EDITOR_OPTIONS,
  useHoveredLine,
  useLineDecorations,
  useMarkers,
  type CodeEditor,
} from "./editor.ts";
import type { Match } from "./engine.ts";
import type { Definition } from "./irDefinition.ts";
import { monaco } from "./monaco.ts";
import type { Link } from "./navigation.ts";
import { definitionLine } from "./yourIR.ts";

export function YourIRPane(props: {
  value: string;
  onChange: (value: string) => void;
  match?: Match;
  /** Whether value is the IR the matches were found in. */
  linked: boolean;
  links: Link[];
  hovered: Link[];
  onHover: (line: number | undefined) => void;
  diagnostics: Diagnostic[];
  theme: string;
  /** Where to go in the IR, each time it is set anew. */
  target?: Definition;
}) {
  const { value, onChange, match, linked, links, hovered, onHover, diagnostics, theme, target } =
    props;
  const [editor, setEditor] = useState<CodeEditor>();
  const lines = (of: Link[]) => (linked ? of.flatMap((l) => (l.irLine ? [l.irLine] : [])) : []);
  const irLines = useMemo(() => lines(links), [links, linked]);
  const hoveredLines = useMemo(() => lines(hovered), [hovered, linked]);
  useLineDecorations(editor, irLines, hoveredLines, "bound-line", true);
  useHoveredLine(editor, onHover);
  useMarkers(editor, diagnostics);
  // A function opened with nothing matched, such as one without a match, is
  // shown from its definition.
  useEffect(() => {
    if (!editor || !match || !linked || irLines.length) return;
    const line = definitionLine(value, match.fn);
    if (line) {
      editor.revealLineNearTop(line);
      editor.setPosition({ lineNumber: line, column: 1 });
    }
    // Only when another function is opened, not as the IR is edited.
  }, [editor, match, linked]);

  const jump = ({ line, column, length }: Definition) => {
    if (!editor) return;
    const range = new monaco.Range(line, column, line, column + length);
    editor.setSelection(range);
    editor.revealRangeInCenterIfOutsideViewport(range);
    editor.focus();
  };
  useEffect(() => {
    if (target) jump(target);
    // Only a new target is gone to, not the same once the editor changes.
  }, [target]);

  return (
    <section className="pane">
      <div className="pane-header">
        <span className="title">Your IR</span>
        {match && linked && <span>{match.fn}</span>}
        <span className="hint">LLVM IR, matched in the page</span>
      </div>
      {match && linked && <BindingList bindings={match.bindings} ir={value} onJump={jump} />}
      <div className="pane-body ir-editor">
        <Editor
          language="llvm"
          theme={theme}
          path="your.ll"
          value={value}
          onChange={(text) => onChange(text ?? "")}
          onMount={setEditor}
          options={{ ...EDITOR_OPTIONS, wordWrap: "off" }}
        />
      </div>
    </section>
  );
}
