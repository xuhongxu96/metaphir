// The status in the toolbar: a line of what the query does, which opens a
// popover with its numbers and the buttons to go on or stop. The popover
// opens by itself when the query pauses or fails.

import { useEffect, useRef, useState, type RefObject } from "react";
import type { QueryControl } from "./pipeline.ts";
import type { Status } from "./status.ts";

export function StatusChip({ status, control }: { status: Status; control?: QueryControl }) {
  const [open, setOpen] = useState(false);
  const root = useRef<HTMLDivElement>(null);
  const paused = control !== undefined && status.pause?.kind === "matches";
  useEffect(() => {
    if (paused || status.error) setOpen(true);
  }, [paused, status.error]);
  useDismiss(root, open, () => setOpen(false));
  const matches = status.details?.find(([label]) => label === "matches")?.[1];

  return (
    <div ref={root} className="status-chip-wrap">
      <button
        id="status-chip"
        className={`status-chip${status.error ? " error" : ""}${paused ? " attention" : ""}`}
        onClick={() => setOpen(!open)}
        aria-expanded={open}
        aria-controls="status-panel"
        title={status.text}
      >
        <span id="status" role="status" className="status">
          {status.text}
        </span>
        {matches !== undefined && <span className="status-count">{matches} matches</span>}
        <span className="caret" aria-hidden="true">
          {open ? "▴" : "▾"}
        </span>
      </button>
      {open && (
        <div id="status-panel" className="status-panel" role="dialog" aria-label="Status">
          <p className={`status-text${status.error ? " error" : ""}`}>{status.text}</p>
          {status.details && <Details details={status.details} />}
          {control && <Actions control={control} paused={paused} />}
        </div>
      )}
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
