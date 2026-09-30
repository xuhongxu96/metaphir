// Matching local files, in the development server only: metaphir-match,
// built for WebAssembly, runs on the files placed in its in-memory file
// system, with their index when one is given, as it would on a machine.

export interface LocalFile {
  /** The path relative to the corpus directory. */
  path: string;
  bytes: Uint8Array;
}

export interface LocalResult {
  /** Matches as metaphir-match --matches-only prints them, paths relative. */
  out: string;
  err: string;
  status: number;
}

/** The corpus directory an index (from metaphir-index build) was built for. */
export function indexRoot(index: Uint8Array): string {
  let pos = 0;
  const bytes = (n: number) => index.subarray(pos, (pos += n));
  const uleb = () => {
    let value = 0;
    let shift = 0;
    for (;;) {
      const byte = index[pos++];
      if (byte === undefined) throw new Error("not a MetaphIR index");
      value += (byte & 0x7f) * 2 ** shift;
      shift += 7;
      if (byte < 0x80) return value;
    }
  };
  const string = () => new TextDecoder().decode(bytes(uleb()));
  if (new TextDecoder().decode(bytes(7)) !== "MPIRIDX")
    throw new Error("not a MetaphIR index");
  bytes(4); // format version, checked by metaphir-match
  string(); // LLVM version
  for (let names = uleb(); names > 0; names--) string();
  return string();
}

export async function matchLocalFiles(
  moduleUrl: string,
  files: LocalFile[],
  pattern: string,
  index?: Uint8Array,
): Promise<LocalResult> {
  let out = "";
  let err = "";
  const { default: create } = await import(/* @vite-ignore */ moduleUrl);
  // A fresh instance per run: the tool's options are parsed once.
  const tool = await create({
    print: (line: string) => (out += line + "\n"),
    printErr: (line: string) => (err += line + "\n"),
  });
  const FS = tool.FS;
  // With an index, the files go where it was built, so that it is used.
  const root = index ? indexRoot(index) : "/corpus";
  const write = (path: string, bytes: Uint8Array | string) => {
    FS.mkdirTree(path.slice(0, path.lastIndexOf("/")) || "/");
    FS.writeFile(path, bytes);
  };
  for (const file of files) write(`${root}/${file.path}`, file.bytes);
  FS.mkdirTree(root);
  write("/pattern.mpir", pattern);
  const args = ["--matches-only"];
  if (index) {
    write("/corpus.mpidx", index);
    args.push("--index", "/corpus.mpidx", "--trust-index");
  }
  args.push("/pattern.mpir", root);
  const status = tool.callMain(args);
  const prefix = `${root}/`;
  out = out
    .split("\n")
    .map((line) => (line.startsWith(prefix) ? line.slice(prefix.length) : line))
    .join("\n");
  return { out, err, status };
}
