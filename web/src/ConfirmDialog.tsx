// A modal question, over the page: confirming takes the primary button
// (focused first), cancelling the other or Escape. Focus stays within it
// and goes back where it was once it closes.

import { useEffect, useRef, type KeyboardEvent, type ReactNode } from "react";

export function ConfirmDialog(props: {
  title: string;
  confirmLabel: string;
  cancelLabel: string;
  onConfirm: () => void;
  onCancel: () => void;
  children: ReactNode;
}) {
  const { title, confirmLabel, cancelLabel, onConfirm, onCancel, children } = props;
  const confirm = useRef<HTMLButtonElement>(null);
  useEffect(() => {
    const focused = document.activeElement as HTMLElement | null;
    confirm.current?.focus();
    return () => focused?.focus();
  }, []);
  const onKeyDown = (event: KeyboardEvent<HTMLDivElement>) => {
    if (event.key === "Escape") {
      event.preventDefault();
      onCancel();
    } else if (event.key === "Tab") {
      const buttons = [...event.currentTarget.querySelectorAll("button")];
      const at = buttons.indexOf(document.activeElement as HTMLButtonElement);
      const next = (at + (event.shiftKey ? -1 : 1) + buttons.length) % buttons.length;
      event.preventDefault();
      buttons[next]?.focus();
    }
  };
  return (
    <div className="dialog-backdrop">
      <div
        id="dialog"
        className="dialog"
        role="alertdialog"
        aria-modal="true"
        aria-labelledby="dialog-title"
        onKeyDown={onKeyDown}
      >
        <h2 id="dialog-title">{title}</h2>
        <div className="dialog-body">{children}</div>
        <div className="dialog-actions">
          <button id="dialog-cancel" onClick={onCancel}>
            {cancelLabel}
          </button>
          <button id="dialog-confirm" ref={confirm} className="primary" onClick={onConfirm}>
            {confirmLabel}
          </button>
        </div>
      </div>
    </div>
  );
}
