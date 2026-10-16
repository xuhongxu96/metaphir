// The status in the toolbar: a line of what the query does, which opens a
// popover with its numbers and the buttons to go on or stop. The popover
// is shown while a query runs, and when it pauses or fails; closed, it
// stays so until the next.

import { useEffect, useRef, useState, type RefObject } from "react";
import { count } from "./engine.ts";
import type { QueryControl } from "./pipeline.ts";
import { describeRejection, type Status } from "./status.ts";

export function StatusChip({ status, control }: { status: Status; control?: QueryControl }) {
  const [open, setOpen] = useState(false);
  const root = useRef<HTMLDivElement>(null);
  const paused = control !== undefined && status.pause?.kind === "matches";
  useEffect(() => {
    setOpen(!!status.running);
  }, [status.running]);
  useEffect(() => {
    if (paused || status.error) setOpen(true);
  }, [paused, status.error]);
  useDismiss(root, open, () => setOpen(false));
  // A diagnostic's source line and caret follow its first line; they are
  // shown apart, in a fixed-width font, so that the caret lines up.
  const [headline, ...rest] = status.text.trimEnd().split("\n");
  const more = rest.join("\n");
  const warnings = status.warnings ?? [];
  const rejections = status.rejections ?? [];
  const failures = rejections.filter((r) => r.reason).length;
  const alerts = warnings.length + failures;

  return (
    <div ref={root} className="status-chip-wrap">
      <button
        id="status-chip"
        className={`status-chip${status.error ? " error" : ""}${paused ? " attention" : ""}`}
        onClick={() => setOpen(!open)}
        aria-expanded={open}
        aria-controls="status-panel"
        title={headline}
      >
        <span id="status" role="status" className="status">
          {headline}
        </span>
        {alerts > 0 && (
          <span className="status-alerts" title={count(alerts, "warning")}>
            ⚠ {alerts.toLocaleString()}
          </span>
        )}
        {status.matches !== undefined && (
          <span className="status-count">{count(status.matches, "match", "matches")}</span>
        )}
        <span className="caret" aria-hidden="true">
          {open ? "▴" : "▾"}
        </span>
      </button>
      {open && (
        <div id="status-panel" className="status-panel" role="dialog" aria-label="Status">
          <p className={`status-text${status.error ? " error" : ""}`}>{headline}</p>
          {more && <pre className="status-source">{more}</pre>}
          {status.details && <Details details={status.details} />}
          {warnings.length > 0 && (
            <Notes title="Warnings" items={warnings.map((w) => located(w.line, w.message))} />
          )}
          {rejections.length > 0 && (
            <Notes
              title="Constraints that rejected structural matches"
              items={rejections.map((r) => located(r.line, describeRejection(r)))}
              hint="Counted in the functions matched: those the index rules out are not."
            />
          )}
          {control && <Actions control={control} paused={paused} />}
        </div>
      )}
    </div>
  );
}

const located = (line: number, message: string) =>
  line > 0 ? `line ${line}: ${message}` : message;

function Notes({ title, items, hint }: { title: string; items: string[]; hint?: string }) {
  return (
    <div className="status-notes">
      <h3>{title}</h3>
      <ul>
        {items.map((item, i) => (
          <li key={i}>{item}</li>
        ))}
      </ul>
      {hint && <p className="hint">{hint}</p>}
    </div>
  );
}

function Details({ details }: { details: [string, string][] }) {
  return (
    <dl className="status-details">
      {details.map(([label, value]) => (
        <div key={label}>
          <dt>{label}</dt>
          <dd>{value}</dd>
        </div>
      ))}
    </dl>
  );
}

/** Stop, and while paused at a number of matches, the ways to go on. */
function Actions({ control, paused }: { control: QueryControl; paused: boolean }) {
  return (
    <div className="status-actions">
      {paused && (
        <>
          <button id="continue" className="primary small" onClick={() => control.resume()}>
            Continue
          </button>
          <button
            id="continue-to-end"
            className="small"
            onClick={() => control.runToEnd()}
            title="Match everything without pausing again"
          >
            Continue to end
          </button>
        </>
      )}
      <button id="stop" className="small" onClick={() => control.stop()} title="Stop matching">
        Stop
      </button>
    </div>
  );
}

/** Calls onDismiss, while open, on a click outside root or on Escape. */
function useDismiss(
  root: RefObject<HTMLElement | null>,
  open: boolean,
  onDismiss: () => void,
) {
  const dismiss = useRef(onDismiss);
  dismiss.current = onDismiss;
  useEffect(() => {
    if (!open) return;
    const onDown = (event: MouseEvent) => {
      if (!root.current?.contains(event.target as Node)) dismiss.current();
    };
    const onKey = (event: KeyboardEvent) => {
      if (event.key === "Escape") dismiss.current();
    };
    document.addEventListener("mousedown", onDown);
    document.addEventListener("keydown", onKey);
    return () => {
      document.removeEventListener("mousedown", onDown);
      document.removeEventListener("keydown", onKey);
    };
  }, [root, open]);
}
