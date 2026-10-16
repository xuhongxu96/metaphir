// The selected match's function: its bindings, and its IR with the
// instructions the pattern matched highlighted. A binding, or a value
// Ctrl/⌘+clicked in the IR, takes to where the value is defined; the page
// can take it elsewhere, with target.

import Editor from "@monaco-editor/react";
import { useEffect, useState } from "react";
import { BindingList } from "./BindingList.tsx";
import { CopyButton } from "./CopyButton.tsx";
import {
  EDITOR_OPTIONS,
  selectRange,
  useIRLinks,
  useJumpTarget,
  type CodeEditor,
} from "./editor.ts";
import type { FunctionIR, Match } from "./engine.ts";
import type { Definition } from "./irDefinition.ts";
import type { Link } from "./navigation.ts";

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
  const lines = useIRLinks(editor, ir?.text, links, hovered, ir !== undefined, onHover);
  useJumpTarget(editor, target);
  // A function with nothing highlighted, such as a rejected one, is shown
  // from its start.
  useEffect(() => {
    if (editor && ir && !lines.length) editor.setScrollTop(0);
  }, [editor, ir, lines]);

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
      {match && (
        <BindingList
          bindings={match.bindings}
          ir={ir?.text}
          onJump={(to) => editor && selectRange(editor, to)}
        />
      )}
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
