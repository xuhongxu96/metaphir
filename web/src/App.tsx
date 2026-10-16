import Editor, { type OnMount } from "@monaco-editor/react";
import { useCallback, useEffect, useMemo, useRef, useState } from "react";
import { Group, Panel, Separator, useDefaultLayout } from "react-resizable-panels";
import { useColorScheme, type SchemePreference } from "./colorScheme.ts";
import {
  EDITOR_OPTIONS,
  useHoveredLine,
  useLineDecorations,
  useMarkers,
  useModifierLinks,
  type CodeEditor,
} from "./editor.ts";
import { inFile, parseDiagnostics, type Diagnostic } from "./diagnostics.ts";
import { count, matchLocal, PublishedCorpus, type Match, type Progress } from "./engine.ts";
import { IRPane } from "./IRPane.tsx";
import type { Definition } from "./irDefinition.ts";
import { LargeSearchDialog } from "./LargeSearchDialog.tsx";
import { MatchesPane } from "./MatchesPane.tsx";
import { patternLink, type Link } from "./navigation.ts";
import { monaco, themeName } from "./monaco.ts";
import { QueryControl } from "./pipeline.ts";
import { ProgressBar } from "./ProgressBar.tsx";
import { patternHash, readPatternHash } from "./share/patternLink.ts";
import { describe, statusDiagnostics, type Status } from "./status.ts";
import { StatusChip } from "./StatusChip.tsx";
import { useFunctionIR } from "./useFunctionIR.ts";
import { YourIRPane } from "./YourIRPane.tsx";
import { IR_FILE, matchYourIR, SAMPLE_IR, type FunctionResult } from "./yourIR.ts";

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
// The standard library the patterns use, shown beside the pattern.
const STDLIB = Object.values(
  import.meta.glob("../../metaphir/StdLib/stdlib.mpir", {
    query: "?raw",
    import: "default",
    eager: true,
  }) as Record<string, string>,
)[0];
// What Match searches: the published corpus, the IR written in the page,
// or (in the development server) local files.
type Source = "published" | "ir" | "local";

const IR_KEY = "metaphir-your-ir";
function savedIR(): string {
  try {
    return localStorage.getItem(IR_KEY) ?? SAMPLE_IR;
  } catch {
    return SAMPLE_IR;
  }
}
type PatternTab = "pattern" | "stdlib";

export function App() {
  const { preference, setPreference, dark } = useColorScheme();
  const theme = themeName(dark);
  const [corpus, setCorpus] = useState<PublishedCorpus>();
  const [source, setSource] = useState<Source>("published");
  // The IR written in the page, kept in this browser, and as last matched.
  const [userIR, setUserIR] = useState(savedIR);
  const [matchedIR, setMatchedIR] = useState<string>();
  useEffect(() => {
    try {
      localStorage.setItem(IR_KEY, userIR);
    } catch {
      // Storage may be unavailable; the IR is then not kept.
    }
  }, [userIR]);
  // The functions of the IR without a match, and why.
  const [misses, setMisses] = useState<FunctionResult[]>([]);
  const [pattern, setPattern] = useState("");
  // A link can carry a pattern (see share/patternLink.ts); else the first
  // example is shown.
  useEffect(() => {
    void readPatternHash(location.hash).then((shared) =>
      setPattern(shared ?? Object.values(EXAMPLES)[0] ?? ""),
    );
  }, []);
  const [status, setStatus] = useState<Status>({ text: "Loading the corpus…", running: true });
  const [running, setRunning] = useState(false);
  // The published query running, to pause, continue or stop.
  const [control, setControl] = useState<QueryControl>();
  const [matches, setMatches] = useState<Match[]>([]);
  const [selected, setSelected] = useState<Match>();
  const [copied, setCopied] = useState(false);
  // The pattern as last matched, whose lines the matches refer to.
  const [matchedPattern, setMatchedPattern] = useState<string>();
  const [patternEditor, setPatternEditor] = useState<CodeEditor>();
  const [patternTab, setPatternTab] = useState<PatternTab>("pattern");
  // What the last run found wrong in the pattern, until it is edited.
  const [diagnostics, setDiagnostics] = useState<Diagnostic[]>([]);
  useEffect(() => setDiagnostics([]), [pattern]);
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
  // The pattern's errors, and the warnings of the run, while it is as run.
  const notes = useMemo(() => statusDiagnostics(status), [status]);
  useMarkers(
    patternEditor,
    useMemo(
      () => {
        const own = diagnostics.filter((d) => inFile(d, "pattern.mpir"));
        return patternLinked ? [...own, ...notes] : own;
      },
      [patternLinked, diagnostics, notes],
    ),
  );
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
  // Ctrl/⌘+clicking the pattern goes to what it matched in the IR.
  const [irTarget, setIRTarget] = useState<Definition>();
  useModifierLinks(
    patternEditor,
    (line, column, text) =>
      patternLinked && selected && ir
        ? patternLink({ line, column, text, links, bindings: selected.bindings, ir: ir.text })
        : undefined,
    // A new object each time, gone to even if the same.
    (to) => setIRTarget({ ...to }),
  );
  const localFiles = useRef<HTMLInputElement>(null);
  const localIndex = useRef<HTMLInputElement>(null);
  const local = import.meta.env.DEV && source === "local";

  useEffect(() => {
    PublishedCorpus.open().then(
      (opened) => {
        setCorpus(opened);
        setStatus({
          text: "Ready",
          details: [
            ["functions", opened.functions.toLocaleString()],
            ["modules", opened.modules.toLocaleString()],
          ],
        });
      },
      (error: Error) => setStatus({ text: error.message, error: true }),
    );
  }, []);

  const yourIR = source === "ir";
  const irLinked = yourIR && userIR === matchedIR;
  const irDiagnostics = useMemo(
    () => (irLinked ? diagnostics.filter((d) => d.file && inFile(d, IR_FILE)) : []),
    [irLinked, diagnostics],
  );
  const canRun =
    !running && pattern.trim() !== "" && (local || yourIR || corpus !== undefined);

  const run = useCallback(async () => {
    void patternHash(pattern).then((hash) => history.replaceState(null, "", hash));
    setMatchedPattern(pattern);
    setRunning(true);
    setMatches([]);
    setSelected(undefined);
    setDiagnostics([]);
    setMisses([]);
    if (yourIR) setMatchedIR(userIR);
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
    const onProgress = (progress: Progress) => setStatus(describe(progress, local));
    try {
      if (yourIR) {
        setStatus({ text: "matching your IR", running: true });
        const result = await matchYourIR(userIR, pattern);
        onMatches(result.matches);
        const matched = result.functions.filter((f) => f.matches > 0).length;
        setMisses(result.functions.filter((f) => f.matches === 0));
        setStatus({
          text: "done",
          details: [
            ["functions", `${matched.toLocaleString()} of ${result.functions.length.toLocaleString()} matched`],
          ],
          matches: result.matches.length,
          warnings: parseDiagnostics(result.messages)
            .filter((d) => d.severity === "warning")
            .map(({ message, line, column }) => ({ message, line, column })),
        });
      } else if (local)
        await matchLocal(
          Array.from(localFiles.current?.files ?? []),
          localIndex.current?.files?.[0],
          pattern,
          onProgress,
          onMatches,
        );
      else {
        const control = new QueryControl();
        setControl(control);
        await corpus!.match(pattern, onProgress, onMatches, control);
      }
    } catch (error) {
      const message = (error as Error).message;
      setStatus({ text: message, error: true });
      setDiagnostics(parseDiagnostics(message));
    } finally {
      if (frame) cancelAnimationFrame(frame);
      flush();
      setRunning(false);
      setControl(undefined);
    }
  }, [pattern, local, yourIR, userIR, corpus]);

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
      const hash = await patternHash(pattern);
      await navigator.clipboard.writeText(`${location.origin}${location.pathname}${hash}`);
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
        <div className="segmented" role="group" aria-label="What to match">
          <button
            id="source-corpus"
            aria-pressed={source === "published"}
            onClick={() => setSource("published")}
            title="Match the published corpus"
          >
            Corpus
          </button>
          <button
            id="source-ir"
            aria-pressed={source === "ir"}
            onClick={() => setSource("ir")}
            title="Match IR you write, in the page"
          >
            Your IR
          </button>
          {import.meta.env.DEV && (
            <button aria-pressed={source === "local"} onClick={() => setSource("local")}>
              Local files
            </button>
          )}
        </div>
        <button id="run" className="primary" disabled={!canRun} onClick={() => void run()}>
          Match
        </button>
        <button onClick={() => void share()} title="Copy a link to this pattern">
          {copied ? "link copied" : "Share"}
        </button>
        <StatusChip status={status} control={control} />
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
      {control && status.pause?.kind === "candidates" && (
        <LargeSearchDialog candidates={status.pause.candidates} control={control} />
      )}
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
                    <div className="tabs" role="tablist">
                      <button
                        role="tab"
                        aria-selected={patternTab === "pattern"}
                        onClick={() => setPatternTab("pattern")}
                      >
                        Pattern
                      </button>
                      <button
                        id="stdlib-tab"
                        role="tab"
                        aria-selected={patternTab === "stdlib"}
                        onClick={() => setPatternTab("stdlib")}
                        title="The standard library's matchers, metaflags and constraints"
                      >
                        stdlib.mpir
                      </button>
                    </div>
                    <span className="hint">
                      {patternTab === "pattern"
                        ? "Ctrl/⌘+Enter to match · Ctrl/⌘+click to find in the IR"
                        : "read-only"}
                    </span>
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
                  {/* Both stay mounted, so the pattern keeps its undo history
                      and markers while the library is shown. */}
                  <div className="pane-body" hidden={patternTab !== "pattern"}>
                    <Editor
                      language="metaphir"
                      theme={theme}
                      path="pattern.mpir"
                      value={pattern}
                      onChange={(value) => setPattern(value ?? "")}
                      onMount={onPatternMount}
                      options={EDITOR_OPTIONS}
                    />
                  </div>
                  <div className="pane-body" hidden={patternTab !== "stdlib"}>
                    <Editor
                      language="metaphir"
                      theme={theme}
                      path="stdlib.mpir"
                      value={STDLIB}
                      options={{ ...EDITOR_OPTIONS, readOnly: true }}
                    />
                  </div>
                </section>
              </Panel>
              <Separator className="separator horizontal" />
              <Panel id="matches-panel" defaultSize="65" minSize="15">
                <MatchesPane
                  matches={matches}
                  selected={selected}
                  onSelect={setSelected}
                  running={running}
                  misses={yourIR ? misses : undefined}
                />
              </Panel>
            </Group>
          </Panel>
          <Separator className="separator vertical" />
          <Panel id="ir-panel" defaultSize="55" minSize="20">
            {yourIR ? (
              <YourIRPane
                value={userIR}
                onChange={setUserIR}
                match={selected}
                linked={irLinked}
                links={links}
                hovered={hovered}
                onHover={onIRHover}
                diagnostics={irDiagnostics}
                theme={theme}
                target={irTarget}
              />
            ) : (
              <IRPane
                match={selected}
                ir={ir}
                theme={theme}
                links={links}
                hovered={hovered}
                onHover={onIRHover}
                target={irTarget}
              />
            )}
          </Panel>
        </Group>
      </main>
    </div>
  );
}
