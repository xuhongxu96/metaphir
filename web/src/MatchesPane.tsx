// The matches, as a table, with a search: only the matches with every
// binding and word of it are listed (see matchSearch.ts). Arrow keys move
// the selection, in the table or the search; Escape clears the search.

import { useEffect, useMemo, useRef, useState, type KeyboardEvent } from "react";
import type { Match } from "./engine.ts";
import { filterMatches } from "./matchSearch.ts";

/** Rows shown at most; the count shows how many more there are. */
const MAX_ROWS = 5000;

export function MatchesPane(props: {
  matches: Match[];
  selected?: Match;
  onSelect: (match: Match) => void;
  running: boolean;
}) {
  const { matches, selected, onSelect, running } = props;
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

  const searching = query.trim() !== "";
  const total = matches.length.toLocaleString();
  return (
    <section className="pane">
      <div className="pane-header">
        <span className="count">
          Matches
          {matches.length
            ? searching
              ? ` (${found.length.toLocaleString()} of ${total})`
              : ` (${total})`
            : ""}
        </span>
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
        {found.length > MAX_ROWS && (
          <span className="hint">first {MAX_ROWS.toLocaleString()} shown</span>
        )}
      </div>
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
                : "No matches yet: write a pattern and press Match."}
          </p>
        )}
      </div>
    </section>
  );
}
