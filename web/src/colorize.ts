// Code colored as the editors color it, outside an editor: Monaco's
// colorizer, in the page's theme, read back as the ranges of the code each
// of its token classes colors, so that other markup can go over them.

import { useEffect, useState } from "react";
import { monaco } from "./monaco.ts";

/** A range of code, from start to end, colored by Monaco's className. */
export interface ColorRun {
  start: number;
  end: number;
  className: string;
}

/** The languages the page colors. */
export type CodeLanguage = "metaphir" | "llvm" | "cpp";

const cache = new Map<string, Promise<ColorRun[] | undefined>>();

/** The colored ranges of text in language; undefined if they cannot be
 * read back, and then the text is shown plain. */
export function colorRuns(text: string, language: CodeLanguage): Promise<ColorRun[] | undefined> {
  const key = `${language}\n${text}`;
  let runs = cache.get(key);
  if (!runs) {
    runs = monaco.editor.colorize(text, language, { tabSize: 2 }).then((html) => {
      const page = new DOMParser().parseFromString(`<div>${html}</div>`, "text/html");
      const found: ColorRun[] = [];
      let at = 0;
      const walk = (node: Node) => {
        if (node.nodeName === "BR") at += 1;
        else if (node instanceof Element && /\bmtk\d+/.test(node.className) && !node.querySelector("span")) {
          const length = (node.textContent ?? "").length;
          found.push({ start: at, end: at + length, className: node.className });
          at += length;
        } else if (node.nodeType === Node.TEXT_NODE) at += (node.textContent ?? "").length;
        else node.childNodes.forEach(walk);
      };
      walk(page.body.firstChild!);
      // The colorizer ends the last line with a break of its own.
      return at === text.length || at === text.length + 1 ? found : undefined;
    });
    cache.set(key, runs);
  }
  return runs;
}

/** The colored ranges of text, once known. */
export function useColorRuns(text: string, language: CodeLanguage): ColorRun[] | undefined {
  const [runs, setRuns] = useState<ColorRun[]>();
  useEffect(() => {
    let current = true;
    setRuns(undefined);
    void colorRuns(text, language).then((found) => current && setRuns(found));
    return () => {
      current = false;
    };
  }, [text, language]);
  return runs;
}

/** The pieces of text from start to end, each with the class that colors
 * it, if any. */
export function colored(
  text: string,
  start: number,
  runs: ColorRun[] | undefined,
): { text: string; className?: string }[] {
  const end = start + text.length;
  const pieces: { text: string; className?: string }[] = [];
  let at = start;
  for (const run of runs ?? []) {
    if (run.end <= at || run.start >= end) continue;
    if (run.start > at) pieces.push({ text: text.slice(at - start, run.start - start) });
    const to = Math.min(run.end, end);
    pieces.push({ text: text.slice(Math.max(run.start, at) - start, to - start), className: run.className });
    at = to;
  }
  if (at < end) pieces.push({ text: text.slice(at - start) });
  return pieces;
}
