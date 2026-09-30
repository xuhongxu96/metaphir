// The IR of a match's function, loaded when the match is selected.

import { useEffect, useState } from "react";
import type { FunctionIR, Match } from "./engine.ts";

/** The IR of match's function, once loaded; a comment if it cannot be. */
export function useFunctionIR(match: Match | undefined) {
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
