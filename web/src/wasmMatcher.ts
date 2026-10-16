// metaphir-match, built for WebAssembly, run on files placed in its
// in-memory file system as it would on a machine: how the page matches the
// IR written in it.

import { locateBeside } from "./session.ts";

export interface MatcherFile {
  /** The path relative to the corpus directory. */
  path: string;
  bytes: Uint8Array;
}

export interface MatcherResult {
  /** Matches as metaphir-match --matches-only prints them, paths relative;
   * or with explain, its report of each function, with why each without a
   * match has none (--explain). */
  out: string;
  err: string;
  status: number;
}

export async function runMatcher(
  moduleUrl: string,
  files: MatcherFile[],
  pattern: string,
  explain = false,
): Promise<MatcherResult> {
  let out = "";
  let err = "";
  const { default: create } = await import(/* @vite-ignore */ moduleUrl);
  // A fresh instance per run: the tool's options are parsed once.
  const tool = await create({
    locateFile: locateBeside(moduleUrl),
    print: (line: string) => (out += line + "\n"),
    printErr: (line: string) => (err += line + "\n"),
  });
  const FS = tool.FS;
  const root = "/corpus";
  const write = (path: string, bytes: Uint8Array | string) => {
    FS.mkdirTree(path.slice(0, path.lastIndexOf("/")) || "/");
    FS.writeFile(path, bytes);
  };
  for (const file of files) write(`${root}/${file.path}`, file.bytes);
  FS.mkdirTree(root);
  write("/pattern.mpir", pattern);
  const args = explain ? ["--explain"] : ["--matches-only", "--print-instructions"];
  args.push("/pattern.mpir", root);
  const status = tool.callMain(args);
  const prefix = `${root}/`;
  out = out
    .split("\n")
    .map((line) => (line.startsWith(prefix) ? line.slice(prefix.length) : line))
    .join("\n");
  return { out, err, status };
}
