// The matches, as a table, with a search: only the matches with every
// binding and word of it are listed (see matchSearch.ts). Arrow keys move
// the selection, in the table or the search; Escape clears the search. A
// second tab lists what was rejected: the constraints that rejected
// functions' structural matches, with some of those functions to open, or
// for your IR each function without a match and why.

import { useEffect, useMemo, useRef, useState, type KeyboardEvent } from "react";
import {
  count,
  REJECTION_SAMPLES,
  rejectionKey,
  type Match,
  type Rejection,
} from "./engine.ts";
import { filterMatches } from "./matchSearch.ts";
import type { FunctionResult } from "./yourIR.ts";

export type MatchesTab = "matches" | "rejected";

/** Rows shown at most; the count shows how many more there are. */
const MAX_ROWS = 5000;

export function MatchesPane(props: {
  matches: Match[];
  selected?: Match;
  onSelect: (match: Match) => void;
  running: boolean;
  /** The functions without a match, when it is known why (your IR). */
  misses?: FunctionResult[];
  /** The constraints that rejected structural matches (the corpus). */
  rejections?: Rejection[];
  tab: MatchesTab;
  onTab: (tab: MatchesTab) => void;
  /** A rejecting constraint to bring into view, each time it is set anew. */
  focus?: { key: string };
}) {
  const { matches, selected, onSelect, running, misses = [], rejections = [] } = props;
  const { tab, onTab: setTab, focus } = props;
  const rejected = misses.length + rejections.length;
  const [query, setQuery] = useState("");
  const body = useRef<HTMLTableSectionElement>(null);
  const found = useMemo(() => filterMatches(matches, query), [matches, query]);
  const shown = found.slice(0, MAX_ROWS);
  const index = selected ? shown.indexOf(selected) : -1;

  const onKeyDown = (event: KeyboardEvent) => {
    const step = event.key === "ArrowDown" ? 1 : event.key === "ArrowUp" ? -1 : 0;
    if (!step || !shown.length) return;
    event.preventDefault();
    onSelect(shown[Math.min(Math.max(index + step, 0), shown.length - 1)]);
  };
  useEffect(() => {
    body.current?.children[index]?.scrollIntoView({ block: "nearest" });
  }, [index]);
  // The first match the search lists is shown once it arrives.
  const first = shown[0];
  useEffect(() => {
    if (!selected && first) onSelect(first);
  }, [selected, first, onSelect]);

  const searching = query.trim() !== "";
  const total = matches.length.toLocaleString();
  return (
    <section className="pane">
      <div className="pane-header">
        <div className="tabs" role="tablist">
          <button
            role="tab"
            aria-selected={tab === "matches"}
            onClick={() => setTab("matches")}
            className="count"
          >
            Matches
            {matches.length
              ? searching
                ? ` (${found.length.toLocaleString()} of ${total})`
                : ` (${total})`
              : ""}
          </button>
          <button
            id="rejected-tab"
            role="tab"
            aria-selected={tab === "rejected"}
            onClick={() => setTab("rejected")}
            className="count"
            title="What the constraints rejected"
          >
            Rejected{rejected ? ` (${rejected.toLocaleString()})` : ""}
          </button>
        </div>
        {tab === "matches" && (
          <input
            id="match-search"
            className="search"
            type="search"
            placeholder="Search module, function, ?a = %x"
            aria-label="Search the matches"
            value={query}
            onChange={(event) => setQuery(event.target.value)}
            onKeyDown={(event) => {
              if (event.key === "Escape") setQuery("");
              else onKeyDown(event);
            }}
          />
        )}
        {tab === "matches" && found.length > MAX_ROWS && (
          <span className="hint">first {MAX_ROWS.toLocaleString()} shown</span>
        )}
      </div>
      {tab === "rejected" ? (
        <div className="pane-body results" tabIndex={0}>
          {rejections.length > 0 && (
            <Rejections
              rejections={rejections}
              selected={selected}
              onSelect={onSelect}
              focus={focus}
            />
          )}
          {misses.length > 0 && <Misses misses={misses} />}
          {!rejected && (
            <p className="empty">
              {running ? "Searching…" : "No constraint rejected a structural match."}
            </p>
          )}
        </div>
      ) : (
      <div className="pane-body results" tabIndex={0} onKeyDown={onKeyDown}>
        {shown.length ? (
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
            {matches.length
              ? "No match has every binding and word of the search."
              : running
                ? "Searching…"
                : rejected
                  ? "No matches: the Rejected tab says why."
                  : "No matches yet: write a pattern and press Match."}
          </p>
        )}
      </div>
      )}
    </section>
  );
}

/** Why each function without a match has none. */
function Misses({ misses }: { misses: FunctionResult[] }) {
  return (
    <div id="misses" className="misses">
      <h3>No match</h3>
      <ul>
        {misses.map((miss) => (
          <li key={miss.fn}>
            <span className="fn">{miss.fn}</span>
            {miss.rejected.length === 0 ? (
              <span className="why"> has none of the pattern's instructions</span>
            ) : (
              <ul>
                {miss.rejected.map((r, i) => (
                  <li key={i}>
                    <code>{r.constraint}</code>{" "}
                    {r.reason ? `could not be evaluated: ${r.reason}` : "is false"}
                  </li>
                ))}
              </ul>
            )}
          </li>
        ))}
      </ul>
    </div>
  );
}

/** Each constraint that rejected structural matches, with the first of the
 * functions it rejected, to open. */
function Rejections(props: {
  rejections: Rejection[];
  selected?: Match;
  onSelect: (match: Match) => void;
  focus?: { key: string };
}) {
  const { rejections, selected, onSelect, focus } = props;
  const root = useRef<HTMLDivElement>(null);
  const [focused, setFocused] = useState<string>();
  useEffect(() => {
    if (!focus) return;
    const index = rejections.findIndex((r) => rejectionKey(r) === focus.key);
    root.current?.children[index]?.scrollIntoView({ block: "start" });
    setFocused(focus.key);
    const done = setTimeout(() => setFocused(undefined), 1500);
    return () => clearTimeout(done);
    // Only a new focus is brought into view, not the same as more arrive.
  }, [focus]);
  return (
    <div id="rejections" className="rejections" ref={root}>
      {rejections.map((r) => (
        <div
          key={rejectionKey(r)}
          className={`rejection${focused === rejectionKey(r) ? " focused" : ""}`}
        >
          <p>
            <code>{r.message}</code>
            {r.line > 0 && <span className="where"> line {r.line}</span>}{" "}
            {r.reason
              ? `could not be evaluated in ${count(r.functions, "function")}: ${r.reason}`
              : `rejected the structural matches of ${count(r.functions, "function")}`}
            {r.functions > r.samples.length && (
              <span className="hint">
                {" "}
                (first {Math.min(REJECTION_SAMPLES, r.samples.length)} listed)
              </span>
            )}
          </p>
          <table>
            <colgroup>
              <col className="module" />
              <col />
            </colgroup>
            <tbody>
              {r.samples.map((sample) => (
                <tr
                  key={sample.key}
                  className={sample === selected ? "selected" : undefined}
                  onClick={() => onSelect(sample)}
                >
                  <td title={sample.module}>{sample.module}</td>
                  <td title={sample.fn}>{sample.fn}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      ))}
      <p className="hint">Counted in the functions matched: those the index rules out are not.</p>
    </div>
  );
}
