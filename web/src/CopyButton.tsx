// Copies text, or what text gives, to the clipboard, and says so for a
// moment. A clipboard that is unavailable leaves the button as it was.

import { useState } from "react";

export function CopyButton(props: {
  text: string | (() => Promise<string>);
  label?: string;
  copiedLabel?: string;
  title?: string;
  className?: string;
}) {
  const { text, label = "copy", copiedLabel = "copied", title, className = "small" } = props;
  const [copied, setCopied] = useState(false);
  return (
    <button
      className={className}
      title={title}
      onClick={(event) => {
        event.stopPropagation();
        void (typeof text === "string" ? Promise.resolve(text) : text())
          .then((value) => navigator.clipboard.writeText(value))
          .then(() => {
            setCopied(true);
            setTimeout(() => setCopied(false), 1200);
          })
          .catch(() => {});
      }}
    >
      {copied ? copiedLabel : label}
    </button>
  );
}
