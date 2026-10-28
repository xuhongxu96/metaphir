import Editor, { type OnMount } from "@monaco-editor/react";
import { useCallback, useEffect, useMemo, useRef, useState } from "react";
import { Group, Panel, Separator, useDefaultLayout } from "react-resizable-panels";
import { useColorScheme, type SchemePreference } from "./colorScheme.ts";
import { Menu } from "./Menu.tsx";
import { findCorpus, loadConfig, type SiteConfig } from "./corpora.ts";
import {
  EDITOR_OPTIONS,
  selectRange,
  useHoveredLine,
  useLineDecorations,
  useLinkOpener,
  useMarkers,
  useModifierLinks,
  type CodeEditor,
} from "./editor.ts";
import { inFile, parseDiagnostics } from "./diagnostics.ts";
import {
  PublishedCorpus,
  rejectionKey,
  type Match,
  type Progress,
  type Rejection,
} from "./engine.ts";
import { IRPane } from "./IRPane.tsx";
import { definitionLink, definitionsIn, type DefinitionFile } from "./mpirDefinitions.ts";
import type { Definition } from "./irDefinition.ts";
import { GuideDialog, guideDismissed } from "./GuideDialog.tsx";
import { LargeSearchDialog } from "./LargeSearchDialog.tsx";
import { MatchesPane } from "./MatchesPane.tsx";
import { linkLines, patternLink, type Link, type NavLink } from "./navigation.ts";
import { monaco, themeName } from "./monaco.ts";
import { QueryControl } from "./pipeline.ts";
import { ProgressBar } from "./ProgressBar.tsx";
import { exampleLabel, exampleTitle, pullRequest, pullRequestUrl } from "./examples.ts";
import { patternHash, readPatternHash } from "./share/patternLink.ts";
import {
  corpusDetails,
  describe,
  linkedRejection,
  matchDetails,
  statusDiagnostics,
} from "./status.ts";
import { StatusChip } from "./StatusChip.tsx";
import { CopyButton } from "./CopyButton.tsx";
import { useResults } from "./results.ts";
import { useFunctionIR } from "./useFunctionIR.ts";
import { YourIRPane } from "./YourIRPane.tsx";
import { IR_FILE, matchYourIR, SAMPLE_IR } from "./yourIR.ts";

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
// Each example names what it folds, and links to the pull request that added
// the fold.
const EXAMPLE_ITEMS = Object.keys(EXAMPLES).map((name) => {
  const pr = pullRequest(name);
  return {
    id: name,
    label: exampleTitle(name),
    link:
      pr === undefined
        ? undefined
        : {
            href: pullRequestUrl(pr),
            text: `#${pr}`,
            title: "The LLVM pull request that added the fold",
          },
  };
});
const SCHEME_ICON: Record<SchemePreference, string> = {
  system: "◐",
  light: "☀",
  dark: "☾",
};
const SCHEME_ITEMS = (["system", "light", "dark"] as const).map((id) => ({
  id,
  label: `${SCHEME_ICON[id]}  ${id[0].toUpperCase()}${id.slice(1)}`,
}));
// The standard library the patterns use, shown beside the pattern.
const STDLIB = Object.values(
  import.meta.glob("../../metaphir/StdLib/stdlib.mpir", {
    query: "?raw",
    import: "default",
    eager: true,
  }) as Record<string, string>,
)[0];
// What Match searches: the published corpus or the IR written in the page.
type Source = "published" | "ir";

const IR_KEY = "metaphir-your-ir";
function savedIR(): string {
  try {
    return localStorage.getItem(IR_KEY) ?? SAMPLE_IR;
  } catch {
    return SAMPLE_IR;
  }
}
type PatternTab = "pattern" | "stdlib";
const STDLIB_DEFINITIONS = definitionsIn(STDLIB);


export function App() {
  const { preference, setPreference, dark } = useColorScheme();
  const theme = themeName(dark);
  const [siteConfig, setSiteConfig] = useState<SiteConfig>();
  const [corpusId, setCorpusId] = useState<string>();
  const [corpus, setCorpus] = useState<PublishedCorpus>();
  const [source, setSource] = useState<Source>("published");
  const corpusItems = (siteConfig?.corpora ?? []).map((c) => ({ id: c.id, label: c.label }));
  const activeCorpus =
    siteConfig && findCorpus(siteConfig, corpusId ?? siteConfig.default);
  // The guide opens with the page, until asked not to.
  const [helpOpen, setHelpOpen] = useState(() => !guideDismissed());
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
  const [pattern, setPattern] = useState("");
  // A link can carry a pattern (see share/patternLink.ts); else the first
  // example is shown.
  useEffect(() => {
    void readPatternHash(location.hash).then((shared) =>
      setPattern(shared ?? Object.values(EXAMPLES)[0] ?? ""),
    );
  }, []);
  // The example the pattern is, until it is edited.
  const example = Object.keys(EXAMPLES).find((name) => EXAMPLES[name] === pattern);
  const examplePr = example === undefined ? undefined : pullRequest(example);
  // Each source keeps its own results.
  const results = {
    published: useResults({ text: "Loading the corpus…", running: true }),
    ir: useResults({ text: "Ready" }),
  };
  const shown = results[source];
  const { matches, selected, setSelected, misses, status, matchedPattern, diagnostics, running } =
    shown;
  // The published query running, to pause, continue or stop.
  const [control, setControl] = useState<QueryControl>();
  // Bumped when the corpus changes, so a run of the old corpus cannot update
  // the new one's status.
  const generation = useRef(0);
  const controlRef = useRef<QueryControl | undefined>(undefined);
  controlRef.current = control;
  const [patternEditor, setPatternEditor] = useState<CodeEditor>();
  const [patternTab, setPatternTab] = useState<PatternTab>("pattern");
  const [rejectionFocus, setRejectionFocus] = useState<{ key: string }>();
  // What a run found wrong in the pattern is gone once it is edited.
  useEffect(() => {
    for (const r of Object.values(results)) r.setDiagnostics([]);
  }, [pattern]);
  const [hovered, setHovered] = useState<Link[]>([]);
  const yourIR = source === "ir";
  const irLinked = yourIR && userIR === matchedIR;
  // Links into the IR hold while it is the IR they were found in: the
  // corpus's always, yours until it is edited.
  const irCurrent = !yourIR || irLinked;
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
  const showRejection = (r: Rejection) => {
    shown.setTab("rejected");
    // A new object each time, brought into view even if the same.
    setRejectionFocus({ key: rejectionKey(r) });
  };
  // The links of the notes' hovers in the pattern.
  useLinkOpener((path) => {
    const r = linkedRejection(status.rejections ?? [], path);
    if (r) showRejection(r);
  });
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
      patternLinked ? linkLines(links, "patternLine") : [],
    [links, patternLinked],
  );
  const hoveredPatternLines = useMemo(
    () => linkLines(hovered, "patternLine"),
    [hovered],
  );
  useLineDecorations(patternEditor, patternLines, hoveredPatternLines, "matched-line", false);
  // Hovering a linked line in either editor lights up both ends.
  useHoveredLine(patternEditor, (line) =>
    setHovered(patternLinked && line ? links.filter((l) => l.patternLine === line) : []),
  );
  const onIRHover = (line: number | undefined) =>
    setHovered(irCurrent && line ? links.filter((l) => l.irLine === line) : []);
  // Ctrl/⌘+clicking the pattern goes to what it matched in the IR.
  const [irTarget, setIRTarget] = useState<Definition>();
  // Ctrl/⌘+clicking a matcher, metaflag or constraint goes to its
  // definition, in the pattern or in stdlib.mpir (in its tab).
  const patternDefinitions = useMemo(() => definitionsIn(pattern), [pattern]);
  const definitionAt = (text: string, column: number) =>
    definitionLink(text, column, [
      ["pattern", patternDefinitions],
      ["stdlib", STDLIB_DEFINITIONS],
    ]);
  const [stdlibEditor, setStdlibEditor] = useState<CodeEditor>();
  const [stdlibTarget, setStdlibTarget] = useState<Definition>();
  // In the pattern, a name with a definition goes there; else what the
  // match bound it to goes to the IR.
  useModifierLinks<NavLink & { file: DefinitionFile | "ir" }>(
    patternEditor,
    (line, column, text) => {
      const definition = definitionAt(text, column);
      if (definition) return definition;
      if (!patternLinked || !irCurrent || !selected || !ir) return undefined;
      const toIR = patternLink({ line, column, text, links, bindings: selected.bindings, ir: ir.text });
      return toIR && { ...toIR, file: "ir" };
    },
    // A new object each time, gone to even if the same.
    (to, { file }) => {
      if (file === "ir") setIRTarget({ ...to });
      else if (file === "pattern") patternEditor && selectRange(patternEditor, to);
      else {
        setPatternTab("stdlib");
        setStdlibTarget({ ...to });
      }
    },
  );
  useModifierLinks(
    stdlibEditor,
    (_, column, text) => definitionLink(text, column, [["stdlib", STDLIB_DEFINITIONS]]),
    (to) => setStdlibTarget({ ...to }),
  );
  // The library's editor is laid out once its tab is shown.
  useEffect(() => {
    if (patternTab !== "stdlib" || !stdlibEditor || !stdlibTarget) return;
    const frame = requestAnimationFrame(() => {
      stdlibEditor.layout();
      selectRange(stdlibEditor, stdlibTarget);
    });
    return () => cancelAnimationFrame(frame);
  }, [patternTab, stdlibEditor, stdlibTarget]);

  // Load the corpus list once. ?corpus= selects one, else config.default.
  useEffect(() => {
    loadConfig().then(
      (config) => {
        const requested = new URLSearchParams(location.search).get("corpus");
        setSiteConfig(config);
        setCorpusId(findCorpus(config, requested).id);
      },
      (error: Error) =>
        results.published.setStatus({ text: error.message, error: true }),
    );
  }, []);

  // Keep the selected corpus in the address bar (?corpus=<id>), preserving
  // the pattern hash.
  useEffect(() => {
    if (!siteConfig || !corpusId) return;
    const params = new URLSearchParams(location.search);
    if (corpusId !== siteConfig.default) params.set("corpus", corpusId);
    else params.delete("corpus");
    const search = params.toString();
    history.replaceState(
      null,
      "",
      `${location.pathname}${search ? `?${search}` : ""}${location.hash}`,
    );
  }, [siteConfig, corpusId]);

  // Open the selected corpus; cancel and dispose the previous one on switch.
  useEffect(() => {
    if (!siteConfig || !corpusId) return;
    const selected = findCorpus(siteConfig, corpusId);
    if (selected.id !== corpusId) {
      setCorpusId(selected.id);
      return;
    }
    generation.current++;
    controlRef.current?.stop();
    setControl(undefined);
    const abort = new AbortController();
    let opened: PublishedCorpus | undefined;
    const {
      setStatus,
      setMatches,
      setSelected,
      setMisses,
      setDiagnostics,
      setMatchedPattern,
      setRunning,
    } = results.published;
    setCorpus(undefined);
    setRunning(false);
    setMatches([]);
    setSelected(undefined);
    setMisses([]);
    setDiagnostics([]);
    setMatchedPattern("");
    setStatus({ text: `Loading ${selected.label}…`, running: true });
    PublishedCorpus.open(selected, abort.signal).then(
      (next) => {
        if (abort.signal.aborted) {
          next.dispose();
          return;
        }
        opened = next;
        setCorpus(next);
        setStatus({
          text: "Ready",
          details: corpusDetails(next.functions, next.modules),
        });
      },
      (error: Error) => {
        if (!abort.signal.aborted)
          setStatus({ text: error.message, error: true });
      },
    );
    return () => {
      abort.abort();
      opened?.dispose();
      setCorpus((current) => (current === opened ? undefined : current));
    };
  }, [siteConfig, corpusId]);

  const irDiagnostics = useMemo(
    () => (irLinked ? diagnostics.filter((d) => d.file && inFile(d, IR_FILE)) : []),
    [irLinked, diagnostics],
  );
  const canRun =
    !running && pattern.trim() !== "" && (yourIR || corpus !== undefined);

  // The page URL: ?corpus=<id> (when non-default) plus the pattern hash.
  const urlFor = useCallback(
    (hash: string) => {
      const params = new URLSearchParams(location.search);
      if (siteConfig && corpusId && corpusId !== siteConfig.default)
        params.set("corpus", corpusId);
      else params.delete("corpus");
      const search = params.toString();
      return `${location.origin}${location.pathname}${search ? `?${search}` : ""}${hash}`;
    },
    [siteConfig, corpusId],
  );

  const run = useCallback(async () => {
    // A run's results go to the source it started in, even if another is
    // shown meanwhile.
    const gen = generation.current;
    const into = results[source];
    const {
      setMatches,
      setSelected,
      setMisses,
      setStatus,
      setMatchedPattern,
      setDiagnostics,
      setRunning,
    } = into;
    void patternHash(pattern).then((hash) =>
      history.replaceState(null, "", urlFor(hash)),
    );
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
      if (gen !== generation.current) return;
      pending.push(...found);
      frame ||= requestAnimationFrame(flush);
    };
    const onProgress = (progress: Progress) => {
      if (gen === generation.current) setStatus(describe(progress));
    };
    try {
      if (yourIR) {
        setStatus({ text: "matching your IR", running: true });
        const result = await matchYourIR(userIR, pattern);
        onMatches(result.matches);
        const { functions } = result;
        setMisses(functions.filter((f) => f.matches === 0));
        setStatus({
          text: "done",
          details: [
            { label: "functions in your IR", value: functions.length.toLocaleString() },
            // Constraints are reported only of functions with a structural match.
            ...matchDetails(
              1,
              functions.filter((f) => f.matches > 0 || f.rejected.length > 0).length,
              functions.filter((f) => f.matches > 0).length,
              result.matches.length,
            ),
          ],
          matches: result.matches.length,
          warnings: parseDiagnostics(result.messages)
            .filter((d) => d.severity === "warning")
            .map(({ message, line, column }) => ({ message, line, column })),
        });
      } else {
        const control = new QueryControl();
        setControl(control);
        await corpus!.match(pattern, onProgress, onMatches, control);
      }
    } catch (error) {
      if (gen === generation.current) {
        const message = (error as Error).message;
        setStatus({ text: message, error: true });
        setDiagnostics(parseDiagnostics(message));
      }
    } finally {
      if (frame) cancelAnimationFrame(frame);
      if (gen === generation.current) {
        flush();
        setRunning(false);
        if (!yourIR) setControl(undefined);
      }
    }
  }, [pattern, source, yourIR, userIR, corpus, urlFor]);

  // The editor's command is added once: it calls the run of the moment.
  const runRef = useRef<typeof run | undefined>(run);
  runRef.current = canRun ? run : undefined;
  const onPatternMount: OnMount = (editor) => {
    setPatternEditor(editor);
    // Ctrl/Cmd+Enter matches, as the Match button would.
    editor.addCommand(monaco.KeyMod.CtrlCmd | monaco.KeyCode.Enter, () => {
      void runRef.current?.();
    });
  };

  // The link Share copies; the address bar has it too.
  const shareLink = async () => urlFor(await patternHash(pattern));

  const horizontal = useDefaultLayout({ id: "metaphir-horizontal" });
  const vertical = useDefaultLayout({ id: "metaphir-vertical" });

  return (
    <div className="app">
      <header className="toolbar">
        <h1>MetaphIR</h1>
        <Menu
          id="example"
          title={example ? exampleLabel(example) : "An example pattern"}
          items={EXAMPLE_ITEMS}
          selected={example}
          wide
          onSelect={(name) => {
            const text = EXAMPLES[name];
            if (text !== undefined) setPattern(text);
          }}
        >
          Examples
          {examplePr !== undefined && <span className="menu-pr">#{examplePr}</span>}
        </Menu>
        <div className="segmented" role="group" aria-label="What to match">
          <Menu
            id="source-corpus"
            title="Match the published corpus"
            items={corpusItems}
            selected={activeCorpus?.id}
            pressed={source === "published"}
            onPress={() => {
              if (source === "published") return;
              setSource("published");
              return false;
            }}
            onSelect={(id) => {
              setCorpusId(id);
              setSource("published");
            }}
          >
            {corpusItems.length > 1 && activeCorpus ? `Corpus: ${activeCorpus.label}` : "Corpus"}
          </Menu>
          <button
            id="source-ir"
            aria-pressed={source === "ir"}
            onClick={() => setSource("ir")}
            title="Match IR you write, in the page"
          >
            Your IR
          </button>
        </div>
        <button id="run" className="primary" disabled={!canRun} onClick={() => void run()}>
          Match
        </button>
        <CopyButton
          text={shareLink}
          label="Share"
          copiedLabel="link copied"
          title="Copy a link to this pattern"
          className=""
        />
        <StatusChip
          status={status}
          control={yourIR ? undefined : control}
          onRejection={showRejection}
        />
        <Menu
          id="theme-button"
          className="icon-button"
          title={`Theme: ${preference}`}
          label={`Theme: ${preference}`}
          items={SCHEME_ITEMS}
          selected={preference}
          onSelect={(id) => setPreference(id as SchemePreference)}
        >
          {SCHEME_ICON[preference]}
        </Menu>
        <button id="help-button" onClick={() => setHelpOpen(true)} title="The syntax, by example">
          Help
        </button>
        <a
          id="github-link"
          className="icon-link"
          href="https://github.com/xuhongxu96/metaphir"
          target="_blank"
          rel="noreferrer"
          title="MetaphIR on GitHub"
          aria-label="MetaphIR on GitHub"
        >
          {/* GitHub's mark (Octicons mark-github). */}
          <svg viewBox="0 0 16 16" width="20" height="20" aria-hidden="true">
            <path
              fill="currentColor"
              d="M8 0c4.42 0 8 3.58 8 8a8.013 8.013 0 0 1-5.45 7.59c-.4.08-.55-.17-.55-.38 0-.27.01-1.13.01-2.2 0-.75-.25-1.23-.54-1.48 1.78-.2 3.65-.88 3.65-3.95 0-.88-.31-1.59-.82-2.15.08-.2.36-1.02-.08-2.12 0 0-.67-.22-2.2.82-.64-.18-1.32-.27-2-.27-.68 0-1.36.09-2 .27-1.53-1.03-2.2-.82-2.2-.82-.44 1.1-.16 1.92-.08 2.12-.51.56-.82 1.28-.82 2.15 0 3.06 1.86 3.75 3.64 3.95-.23.2-.44.55-.51 1.07-.46.21-1.61.55-2.33-.66-.15-.24-.6-.83-1.23-.82-.67.01-.27.38.01.53.34.19.73.9.82 1.13.16.45.68 1.31 2.69.94 0 .67.01 1.3.01 1.49 0 .21-.15.45-.55.38A7.995 7.995 0 0 1 0 8c0-4.42 3.58-8 8-8Z"
            />
          </svg>
        </a>
        <ProgressBar status={status} />
      </header>
      {helpOpen && (
        <GuideDialog
          onTry={(text) => {
            setPattern(text);
            setPatternTab("pattern");
            setHelpOpen(false);
          }}
          onClose={() => setHelpOpen(false)}
        />
      )}
      {!yourIR && control && status.pause?.kind === "candidates" && (
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
                        ? "Ctrl/⌘+Enter to match · Ctrl/⌘+click to follow a name"
                        : "read-only · Ctrl/⌘+click to follow a name"}
                    </span>
                  </div>
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
                      onMount={setStdlibEditor}
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
                  rejections={yourIR ? undefined : status.rejections}
                  tab={shown.tab}
                  onTab={shown.setTab}
                  focus={rejectionFocus}
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
