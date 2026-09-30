// The selected match's function: its bindings, and its IR with the
// instructions the pattern matched highlighted. A binding, or a value
// Ctrl/⌘+clicked in the IR, takes to where the value is defined; the page
// can take it elsewhere, with target.

import Editor from "@monaco-editor/react";
import { useEffect, useMemo, useState } from "react";
import { BindingList } from "./BindingList.tsx";
import { CopyButton } from "./CopyButton.tsx";
import {
  EDITOR_OPTIONS,
  useHoveredLine,
  useLineDecorations,
  useModifierLinks,
  type CodeEditor,
} from "./editor.ts";
import type { FunctionIR, Match } from "./engine.ts";
import type { Definition } from "./irDefinition.ts";
import { monaco } from "./monaco.ts";
import { irLink, type Link } from "./navigation.ts";

export function IRPane(props: {
  match?: Match;
  ir?: FunctionIR;
  theme: string;
  links: Link[];
  hovered: Link[];
  onHover: (line: number | undefined) => void;
  /** Where to go in the IR, each time it is set anew. */
  target?: Definition;
}) {
  const { match, ir, theme, links, hovered, onHover, target } = props;
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

  // What is gone to is selected, in view.
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
  useModifierLinks(
    editor,
    (_, column, text) => (ir ? irLink({ column, text, ir: ir.text }) : undefined),
    jump,
  );

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
