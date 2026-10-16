// Diagnostics in the messages of the tools, "file:line:column: error: text"
// followed by the source line and a caret, as markers in the editor.

export interface Diagnostic {
  line: number;
  column: number;
  severity: "error" | "warning" | "info";
  message: string;
}

const LOCATED = /^(?:.*?: )?[^\s:]+:(\d+):(\d+): (error|warning): (.*)$/gm;

/** The located diagnostics in text, in order. */
export function parseDiagnostics(text: string): Diagnostic[] {
  return [...text.matchAll(LOCATED)].map(([, line, column, severity, message]) => ({
    line: Number(line),
    column: Number(column),
    severity: severity as Diagnostic["severity"],
    message,
  }));
}
