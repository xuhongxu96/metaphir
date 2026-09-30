import Editor, { type OnMount } from "@monaco-editor/react";
import { useCallback, useEffect, useMemo, useRef, useState } from "react";
import { Group, Panel, Separator, useDefaultLayout } from "react-resizable-panels";
import { useColorScheme, type SchemePreference } from "./colorScheme.ts";
import {
  matchLocal,
  PublishedCorpus,
  type FunctionIR,
  type Match,
  type Progress,
} from "./engine.ts";
import { monaco, themeName } from "./monaco.ts";

// The patterns of the evaluation, as examples.
const EXAMPLES: Record<string, string> = Object.fromEntries(
  Object.entries(
    import.meta.glob("../../eval/patterns/*.mpir", {
      query: "?raw",
      import: "default",
      eager: true,
    }) as Record<string, string>,
  )
    .map(([path, text]) => [path.slice(path.lastIndexOf("/") + 1, -".mpir".length), text])
    .sort(([a], [b]) => (a < b ? -1 : 1)),
);
/** Rows shown at most; the count shows how many more there are. */
const MAX_ROWS = 5000;

type Source = "published" | "local";

const EDITOR_OPTIONS = {
  minimap: { enabled: false },
  fontSize: 13,
  scrollBeyondLastLine: false,
  automaticLayout: true,
  renderLineHighlight: "none" as const,
  wordWrap: "on" as const,
};

/** "1 match", "2 matches". */
function count(n: number, noun: string, plural = `${noun}s`): string {
  return `${n.toLocaleString()} ${n === 1 ? noun : plural}`;
}

function describe(progress: Progress, local: boolean): string {
  const time = `${progress.seconds.toFixed(1)} s`;
  const matches = count(progress.matches, "match", "matches");
  if (local) return `${progress.stage} · ${matches} · ${time}`;
  const parts = [progress.stage];
  if (progress.matchable)
    parts.push(
      `${progress.matched.toLocaleString()} of ${count(progress.matchable, "function")} matched`,
    );
  parts.push(matches, `${(progress.bytes / 1e6).toFixed(1)} MB`, time);
  return parts.join(" · ");
}

function patternFromHash(): string | undefined {
  const match = /^#pattern=(.*)$/s.exec(location.hash);
  return match ? decodeURIComponent(match[1]) : undefined;
}

function linkTo(pattern: string): string {
  return `${location.origin}${location.pathname}#pattern=${encodeURIComponent(pattern)}`;
}

interface Status {
  text: string;
  error?: boolean;
  /** How far a run is, from 0 to 1; undefined while not known. */
  fraction?: number;
  running?: boolean;
}

export function App() {
  const { preference, setPreference, dark } = useColorScheme();
  const theme = themeName(dark);
  const [corpus, setCorpus] = useState<PublishedCorpus>();
  const [source, setSource] = useState<Source>("published");
  // A link can carry a pattern, as "#pattern=<encoded text>".
  const [pattern, setPattern] = useState(
    () => patternFromHash() ?? Object.values(EXAMPLES)[0] ?? "",
  );
  const [status, setStatus] = useState<Status>({ text: "Loading the corpus…", running: true });
  const [running, setRunning] = useState(false);
  const [matches, setMatches] = useState<Match[]>([]);
  const [selected, setSelected] = useState<Match>();
  const [copied, setCopied] = useState(false);
  // The pattern as last matched, whose lines the matches refer to.
  const [matchedPattern, setMatchedPattern] = useState<string>();
  const [patternEditor, setPatternEditor] = useState<CodeEditor>();
  const [hovered, setHovered] = useState<Link[]>([]);
  const ir = useFunctionIR(selected);
  const links = useMemo<Link[]>(
    () =>
      (selected?.instructions ?? []).map((matched) => ({
        name: matched.name,
        patternLine: matched.patternLine,
        irLine: ir?.lines[matched.position],
      })),
    [selected, ir],
  );
  // Pattern lines mean something only while the pattern is as matched.
  const patternLinked = pattern === matchedPattern;
  const patternLines = useMemo(
    () =>
      patternLinked ? links.flatMap((l) => (l.patternLine ? [l.patternLine] : [])) : [],
    [links, patternLinked],
  );
  const hoveredPatternLines = useMemo(
    () => hovered.flatMap((l) => (l.patternLine ? [l.patternLine] : [])),
    [hovered],
  );
  useLineDecorations(patternEditor, patternLines, hoveredPatternLines, "matched-line", false);
  // Hovering a linked line in either editor lights up both ends.
  useHoveredLine(patternEditor, (line) =>
    setHovered(patternLinked && line ? links.filter((l) => l.patternLine === line) : []),
  );
  const onIRHover = (line: number | undefined) =>
    setHovered(line ? links.filter((l) => l.irLine === line) : []);
  const localFiles = useRef<HTMLInputElement>(null);
  const localIndex = useRef<HTMLInputElement>(null);
  const local = import.meta.env.DEV && source === "local";

  useEffect(() => {
    PublishedCorpus.open().then(
      (opened) => {
        setCorpus(opened);
        setStatus({
          text: `Ready: ${count(opened.functions, "function")} of ${count(opened.modules, "module")}.`,
        });
      },
      (error: Error) => setStatus({ text: error.message, error: true }),
    );
  }, []);

  const canRun = !running && pattern.trim() !== "" && (local || corpus !== undefined);

  const run = useCallback(async () => {
    history.replaceState(null, "", `#pattern=${encodeURIComponent(pattern)}`);
    setMatchedPattern(pattern);
    setRunning(true);
    setMatches([]);
    setSelected(undefined);
    // Matches arrive by function; the table updates once a frame.
    let pending: Match[] = [];
    let frame = 0;
    const flush = () => {
      frame = 0;
      const arrived = pending;
      pending = [];
      if (arrived.length)
        setMatches((shown) => [...shown, ...arrived].sort((a, b) => a.key - b.key));
    };
    const onMatches = (found: Match[]) => {
      pending.push(...found);
      frame ||= requestAnimationFrame(flush);
    };
    const onProgress = (progress: Progress) =>
      setStatus({
        text: describe(progress, local),
        fraction: progress.fraction,
        running: progress.stage !== "done",
      });
    try {
      if (local)
        await matchLocal(
          Array.from(localFiles.current?.files ?? []),
          localIndex.current?.files?.[0],
          pattern,
          onProgress,
          onMatches,
        );
      else await corpus!.match(pattern, onProgress, onMatches);
    } catch (error) {
      setStatus({ text: (error as Error).message, error: true });
    } finally {
      if (frame) cancelAnimationFrame(frame);
      flush();
      setRunning(false);
    }
  }, [pattern, local, corpus]);

  // The first match is shown once it arrives.
  useEffect(() => {
    if (!selected && matches.length) setSelected(matches[0]);
  }, [matches, selected]);

  const runRef = useRef(run);
  runRef.current = run;
  const onPatternMount: OnMount = (editor) => {
    setPatternEditor(editor);
    // Ctrl/Cmd+Enter matches.
    editor.addCommand(monaco.KeyMod.CtrlCmd | monaco.KeyCode.Enter, () => {
      if (!document.getElementById("run")?.hasAttribute("disabled")) void runRef.current();
    });
  };

  async function share() {
    try {
      await navigator.clipboard.writeText(linkTo(pattern));
      setCopied(true);
      setTimeout(() => setCopied(false), 1500);
    } catch {
      // The clipboard may be unavailable; the address bar has the link too.
    }
  }

  const horizontal = useDefaultLayout({ id: "metaphir-horizontal" });
  const vertical = useDefaultLayout({ id: "metaphir-vertical" });

  return (
    <div className="app">
      <header className="toolbar">
        <h1>MetaphIR</h1>
        <label className="picker">
          example
          <select
            value=""
            onChange={(event) => {
              const text = EXAMPLES[event.target.value];
              if (text !== undefined) setPattern(text);
            }}
          >
            <option value="">choose…</option>
            {Object.keys(EXAMPLES).map((name) => (
              <option key={name} value={name}>
                {name}
              </option>
            ))}
          </select>
        </label>
        {import.meta.env.DEV && (
          <label className="picker">
            corpus
            <select value={source} onChange={(e) => setSource(e.target.value as Source)}>
              <option value="published">published</option>
              <option value="local">local files</option>
            </select>
          </label>
        )}
        <button id="run" className="primary" disabled={!canRun} onClick={() => void run()}>
          Match
        </button>
        <button onClick={() => void share()} title="Copy a link to this pattern">
          {copied ? "link copied" : "Share"}
        </button>
        <span
          id="status"
          role="status"
          className={`status${status.error ? " error" : ""}`}
          title={status.text}
        >
          {status.text}
        </span>
        <label className="picker">
          theme
          <select
            value={preference}
            onChange={(e) => setPreference(e.target.value as SchemePreference)}
          >
            <option value="system">system</option>
            <option value="light">light</option>
            <option value="dark">dark</option>
          </select>
        </label>
        <ProgressBar status={status} />
      </header>
      <main className="panes">
        <Group
          orientation="horizontal"
          defaultLayout={horizontal.defaultLayout}
          onLayoutChanged={horizontal.onLayoutChanged}
        >
          <Panel id="left-panel" defaultSize="45" minSize="20">
            <Group
              orientation="vertical"
              defaultLayout={vertical.defaultLayout}
              onLayoutChanged={vertical.onLayoutChanged}
            >
              <Panel id="pattern-panel" defaultSize="35" minSize="15">
                <section className="pane">
                  <div className="pane-header">
                    <span>Pattern</span>
                    <span className="hint">Ctrl/⌘+Enter to match</span>
                  </div>
                  {local && (
                    <div className="local">
                      <label>
                        .ll/.bc directory{" "}
                        <input ref={localFiles} type="file" multiple {...{ webkitdirectory: "" }} />
                      </label>
                      <label>
                        index (optional){" "}
                        <input ref={localIndex} type="file" accept=".mpidx" />
                      </label>
                    </div>
                  )}
                  <div className="pane-body">
                    <Editor
                      language="metaphir"
                      theme={theme}
                      value={pattern}
                      onChange={(value) => setPattern(value ?? "")}
                      onMount={onPatternMount}
                      options={EDITOR_OPTIONS}
                    />
                  </div>
                </section>
              </Panel>
              <Separator className="separator horizontal" />
              <Panel id="matches-panel" defaultSize="65" minSize="15">
                <Results
                  matches={matches}
                  selected={selected}
                  onSelect={setSelected}
                  running={running}
                />
              </Panel>
            </Group>
          </Panel>
          <Separator className="separator vertical" />
          <Panel id="ir-panel" defaultSize="55" minSize="20">
            <IRView
              match={selected}
              ir={ir}
              theme={theme}
              links={links}
              hovered={hovered}
              onHover={onIRHover}
            />
          </Panel>
        </Group>
      </main>
    </div>
  );
}

function ProgressBar({ status }: { status: Status }) {
  if (!status.running) return null;
  const known = status.fraction !== undefined;
  return (
    <div
      className={`progress${known ? "" : " indeterminate"}`}
      role="progressbar"
      aria-valuemin={0}
      aria-valuemax={100}
      aria-valuenow={known ? Math.round(status.fraction! * 100) : undefined}
    >
      <div style={known ? { width: `${status.fraction! * 100}%` } : undefined} />
    </div>
  );
}

function Results(props: {
  matches: Match[];
  selected?: Match;
  onSelect: (match: Match) => void;
  running: boolean;
}) {
  const { matches, selected, onSelect, running } = props;
  const body = useRef<HTMLTableSectionElement>(null);
  const shown = matches.slice(0, MAX_ROWS);
  const index = selected ? shown.indexOf(selected) : -1;

  // Arrow keys move the selection; the selected row stays in view.
  const onKeyDown = (event: React.KeyboardEvent) => {
    const step = event.key === "ArrowDown" ? 1 : event.key === "ArrowUp" ? -1 : 0;
    if (!step || !shown.length) return;
    event.preventDefault();
    onSelect(shown[Math.min(Math.max(index + step, 0), shown.length - 1)]);
  };
  useEffect(() => {
    body.current?.children[index]?.scrollIntoView({ block: "nearest" });
  }, [index]);

  return (
    <section className="pane">
      <div className="pane-header">
        <span>
          Matches{matches.length ? ` (${matches.length.toLocaleString()})` : ""}
        </span>
        {matches.length > MAX_ROWS && (
          <span className="hint">showing the first {MAX_ROWS.toLocaleString()}</span>
        )}
      </div>
      <div className="pane-body results" tabIndex={0} onKeyDown={onKeyDown}>
        {matches.length ? (
          <table>
            <colgroup>
              <col className="module" />
              <col className="function" />
              <col />
            </colgroup>
            <thead>
              <tr>
                <th>Module</th>
                <th>Function</th>
                <th>Bindings</th>
              </tr>
            </thead>
            <tbody id="matches" ref={body}>
              {shown.map((match) => (
                <tr
                  key={match.key}
                  className={match === selected ? "selected" : undefined}
                  onClick={() => onSelect(match)}
                >
                  <td title={match.module}>{match.module}</td>
                  <td title={match.fn}>{match.fn}</td>
                  <td title={match.bindings}>{match.bindings}</td>
                </tr>
              ))}
            </tbody>
          </table>
        ) : (
          <p className="empty">
            {running ? "Searching…" : "No matches yet: write a pattern and press Match."}
          </p>
        )}
      </div>
    </section>
  );
}

/** A match's bindings, "{?a = %x, ?b = 1}", one by one. */
function Bindings({ bindings }: { bindings: string }) {
  const each = bindings
    .replace(/^\{|\}$/g, "")
    // Values can have commas of their own, as vectors do.
    .split(/, (?=\?[\w.]+ = )/)
    .filter(Boolean);
  if (!each.length) return null;
  return (
    <div className="binding-list">
      {each.map((binding) => {
        const at = binding.indexOf(" = ");
        return (
          <span key={binding} className="binding" title={binding}>
            <span className="variable">{binding.slice(0, at)}</span>
            {binding.slice(at)}
          </span>
        );
      })}
    </div>
  );
}

type CodeEditor = Parameters<OnMount>[0];

/** A pattern instruction and the IR instruction it matched, by line. */
interface Link {
  name: string;
  /** In the pattern, unless the instruction is from a library. */
  patternLine?: number;
  /** In the matched function's IR. */
  irLine?: number;
}

/**
 * Keeps whole-line decorations on editor: className on lines, and
 * hoverClassName on those of them hovered.
 */
function useLineDecorations(
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
  // The first line is brought into view when the lines change.
  useEffect(() => {
    if (editor && reveal && lines.length) editor.revealLineInCenterIfOutsideViewport(Math.min(...lines));
  }, [editor, lines, reveal]);
}

/**
 * Reports the line under the mouse in editor, or undefined once it leaves.
 */
function useHoveredLine(
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

/** The IR of the selected match's function, once loaded. */
function useFunctionIR(match: Match | undefined) {
  const [loaded, setLoaded] = useState<{ match: Match; ir: FunctionIR }>();
  useEffect(() => {
    let current = true;
    if (!match?.ir) return;
    match.ir().then(
      (ir) => current && setLoaded({ match, ir }),
      (error: Error) =>
        current && setLoaded({ match, ir: { text: `; ${error.message}`, lines: [] } }),
    );
    return () => {
      current = false;
    };
  }, [match]);
  return loaded && loaded.match === match ? loaded.ir : undefined;
}

function IRView(props: {
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
      {match && <Bindings bindings={match.bindings} />}
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

function CopyButton({ text }: { text: string }) {
  const [copied, setCopied] = useState(false);
  return (
    <button
      className="small"
      onClick={() =>
        void navigator.clipboard.writeText(text).then(() => {
          setCopied(true);
          setTimeout(() => setCopied(false), 1200);
        })
      }
    >
      {copied ? "copied" : "copy"}
    </button>
  );
}
