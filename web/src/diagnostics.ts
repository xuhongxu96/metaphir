// Diagnostics in the messages of the tools, "file:line:column: error: text"
// followed by the source line and a caret, as markers in the editor.

export interface Diagnostic {
  /** The file the diagnostic is in, as the tool named it. */
  file?: string;
  line: number;
  column: number;
  severity: "error" | "warning" | "info";
  message: string;
  /** A link its hover shows after the message: the link's text, and the
   * URI it opens (see useLinkOpener). */
  link?: { text: string; target: string };
}

/** The scheme of the page's own links, such as those of diagnostics. */
export const PAGE_SCHEME = "metaphir";

const LOCATED = /^(?:.*?: )?([^\s:]+):(\d+):(\d+): (error|warning): (.*)$/gm;

/** Whether a diagnostic is in the file named name, wherever it was. */
export const inFile = (d: Diagnostic, name: string) =>
  d.file === undefined || d.file === name || d.file.endsWith(`/${name}`);

/** The located diagnostics in text, in order. */
export function parseDiagnostics(text: string): Diagnostic[] {
  return [...text.matchAll(LOCATED)].map(
    ([, file, line, column, severity, message]) => ({
      file,
      line: Number(line),
      column: Number(column),
      severity: severity as Diagnostic["severity"],
      message,
    }),
  );
}
