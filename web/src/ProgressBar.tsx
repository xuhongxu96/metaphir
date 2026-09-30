// How far a run is, along the toolbar's bottom edge: a bar that fills while
// that is known, and one that sweeps while it is not. It holds still while
// the run is paused.

import type { Status } from "./status.ts";

export function ProgressBar({ status }: { status: Status }) {
  if (!status.running) return null;
  const known = status.fraction !== undefined;
  return (
    <div
      className={`progress${known ? "" : " indeterminate"}${status.pause ? " paused" : ""}`}
      role="progressbar"
      aria-valuemin={0}
      aria-valuemax={100}
      aria-valuenow={known ? Math.round(status.fraction! * 100) : undefined}
    >
      <div style={known ? { width: `${status.fraction! * 100}%` } : undefined} />
    </div>
  );
}
