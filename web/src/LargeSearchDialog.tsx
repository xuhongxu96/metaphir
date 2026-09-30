// Asks whether to go on with a query that has many candidates, before their
// features are read (see CANDIDATE_PROMPT).

import { ConfirmDialog } from "./ConfirmDialog.tsx";
import { count, MATCH_BATCH } from "./engine.ts";
import type { QueryControl } from "./pipeline.ts";

export function LargeSearchDialog(props: { candidates: number; control: QueryControl }) {
  const { candidates, control } = props;
  return (
    <ConfirmDialog
      title="Large search"
      confirmLabel="Continue"
      cancelLabel="Stop"
      onConfirm={() => control.resume()}
      onCancel={() => control.stop()}
    >
      <p>
        The pattern may match <strong>{count(candidates, "function")}</strong>. Checking
        them all may trigger huge I/O over the network and may take a while.
      </p>
      <p>Continue anyway? Matching still pauses every {MATCH_BATCH} matches.</p>
    </ConfirmDialog>
  );
}
