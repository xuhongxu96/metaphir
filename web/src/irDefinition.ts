// Where a bound value is defined in its function's textual IR: the first
// local value it names (%x) is an argument, an instruction or a block.
// Constants and globals are not defined in the function.

/** A name in the IR, by line and column (from 1). */
export interface Definition {
  line: number;
  column: number;
  length: number;
}

const LOCAL = /%(?:"[^"]*"|[-\w.$]+)/;
/** What cannot follow a name that is not quoted: more of it. */
const END = "(?![-\\w.$])";

const escape = (text: string) => text.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");

export function findDefinition(ir: string, value: string): Definition | undefined {
  const local = LOCAL.exec(value)?.[0];
  if (!local) return undefined;
  const name = local.slice(1);
  const token = escape(local) + END;
  const instruction = new RegExp(`^(\\s*)${token}\\s*=`);
  const label = new RegExp(`^${escape(name)}:`);
  const lines = ir.split("\n");
  for (let i = 0; i < lines.length; i++) {
    const line = lines[i];
    if (line.startsWith("define ")) {
      const argument = new RegExp(token).exec(line);
      if (argument) return { line: i + 1, column: argument.index + 1, length: local.length };
      continue;
    }
    const defined = instruction.exec(line);
    if (defined) return { line: i + 1, column: defined[1].length + 1, length: local.length };
    if (label.test(line)) return { line: i + 1, column: 1, length: name.length };
  }
  return undefined;
}
