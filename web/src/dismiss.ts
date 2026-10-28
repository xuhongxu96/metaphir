// Closing a popover: on Escape, and on a click anywhere but in it.

import { useEffect, useRef, type RefObject } from "react";

export function useDismiss(
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
