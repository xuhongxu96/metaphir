// The IR the pattern is matched in, written in the page: an editor with the
// selected match's bindings above it, and while the IR is as matched, the
// instructions the match matched highlighted and the IR's errors marked.
// It shares IRPane's links into the IR (see useIRLinks).

import Editor from "@monaco-editor/react";
import { useEffect, useState } from "react";
import { BindingList } from "./BindingList.tsx";
import { CopyButton } from "./CopyButton.tsx";
import type { Diagnostic } from "./diagnostics.ts";
import {
  EDITOR_OPTIONS,
  selectRange,
  useIRLinks,
  useJumpTarget,
  useMarkers,
  type CodeEditor,
} from "./editor.ts";
import type { Match } from "./engine.ts";
import type { Definition } from "./irDefinition.ts";
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
  const lines = useIRLinks(editor, linked ? value : undefined, links, hovered, linked, onHover);
  useJumpTarget(editor, target);
  useMarkers(editor, diagnostics);
  // A function opened with nothing matched, such as one without a match, is
  // shown from its definition.
  useEffect(() => {
    if (!editor || !match || !linked || lines.length) return;
    const line = definitionLine(value, match.fn);
    if (line) {
      editor.revealLineNearTop(line);
      editor.setPosition({ lineNumber: line, column: 1 });
    }
    // Only when another function is opened, not as the IR is edited.
  }, [editor, match, linked]);

  return (
    <section className="pane">
      <div className="pane-header">
        <span className="title">Your IR</span>
        {match && linked && <span>{match.fn}</span>}
        <span className="spacer" />
        <span className="hint">LLVM IR, matched in the page</span>
        <CopyButton text={value} />
      </div>
      {match && linked && (
        <BindingList
          bindings={match.bindings}
          ir={value}
          onJump={(to) => editor && selectRange(editor, to)}
        />
      )}
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
