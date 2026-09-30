// The selected match's function: its bindings, and its IR with the
// instructions the pattern matched highlighted. A binding takes to the
// definition of its value.

import Editor from "@monaco-editor/react";
import { useMemo, useState } from "react";
import { BindingList } from "./BindingList.tsx";
import { CopyButton } from "./CopyButton.tsx";
import {
  EDITOR_OPTIONS,
  useHoveredLine,
  useLineDecorations,
  type CodeEditor,
} from "./editor.ts";
import type { FunctionIR, Match } from "./engine.ts";
import type { Definition } from "./irDefinition.ts";
import { monaco } from "./monaco.ts";

/** A pattern instruction and the IR instruction it matched, by line. */
export interface Link {
  name: string;
  /** In the pattern, unless the instruction is from a library. */
  patternLine?: number;
  /** In the matched function's IR. */
  irLine?: number;
}

export function IRPane(props: {
  match?: Match;
  ir?: FunctionIR;
  theme: string;
  links: Link[];
  hovered: Link[];
  onHover: (line: number | undefined) => void;
}) {
  const { match, ir, theme, links, hovered, onHover } = props;
  const [editor, setEditor] = useState<CodeEditor>();
  const irLines = useMemo(
    () => links.flatMap((link) => (link.irLine ? [link.irLine] : [])),
    [links],
  );
  const hoveredLines = useMemo(
    () => hovered.flatMap((link) => (link.irLine ? [link.irLine] : [])),
    [hovered],
  );
  useLineDecorations(editor, ir ? irLines : [], hoveredLines, "bound-line", true);
  useHoveredLine(editor, onHover);

  // The definition is selected, in view.
  const jump = ({ line, column, length }: Definition) => {
    if (!editor) return;
    editor.setSelection(new monaco.Range(line, column, line, column + length));
    editor.revealRangeInCenterIfOutsideViewport(
      new monaco.Range(line, column, line, column + length),
    );
    editor.focus();
  };

  return (
    <section className="pane">
      <div className="pane-header">
        {match ? (
          <>
            <span id="ir-title" className="title">
              {match.module} {match.fn}
            </span>
            <span className="spacer" />
            {ir && <CopyButton text={ir.text} />}
          </>
        ) : (
          <span>Function IR</span>
        )}
      </div>
      {match && <BindingList bindings={match.bindings} ir={ir?.text} onJump={jump} />}
      <div className="pane-body ir-editor">
        {!match ? (
          <p className="empty">Select a match to see its function.</p>
        ) : !match.ir ? (
          <p className="empty">This function's IR cannot be shown (bitcode).</p>
        ) : (
          <Editor
            language="llvm"
            theme={theme}
            value={ir?.text ?? "; loading…"}
            onMount={setEditor}
            options={{ ...EDITOR_OPTIONS, readOnly: true, wordWrap: "off" }}
          />
        )}
      </div>
    </section>
  );
}
