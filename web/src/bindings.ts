// A match's bindings, as metaphir-match prints them: "{?a = %x, ?b = 1}".

/** The bindings of "{?a = %x, ?b = 1}": "?a = %x" and "?b = 1". */
export function splitBindings(bindings: string): string[] {
  return (
    bindings
      .replace(/^\{|\}$/g, "")
      // Values can have commas of their own, as vectors do.
      .split(/, (?=\?[\w.]+ = )/)
      .filter(Boolean)
  );
}

/** The value bound to variable ("?a"), if it is bound. */
export function bindingValue(bindings: string, variable: string): string | undefined {
  const binding = splitBindings(bindings).find((b) => b.startsWith(`${variable} = `));
  return binding?.slice(variable.length + 3);
}
