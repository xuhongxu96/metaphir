// A match's bindings, "{?a = %x, ?b = 1}", one by one. A binding whose
// value is defined in the function shown, as %x is, takes there once
// clicked.

import { splitBindings } from "./bindings.ts";
import { findDefinition, type Definition } from "./irDefinition.ts";

export function BindingList(props: {
  bindings: string;
  /** The IR of the function, once loaded, to find the values in. */
  ir?: string;
  onJump: (definition: Definition) => void;
}) {
  const { bindings, ir, onJump } = props;
  const each = splitBindings(bindings);
  if (!each.length) return null;
  return (
    <div className="binding-list">
      {each.map((binding) => {
        const at = binding.indexOf(" = ");
        const content = (
          <>
            <span className="variable">{binding.slice(0, at)}</span>
            {binding.slice(at)}
          </>
        );
        const definition = ir === undefined ? undefined : findDefinition(ir, binding.slice(at + 3));
        return definition ? (
          <button
            key={binding}
            className="binding"
            title={`${binding}: go to its definition`}
            onClick={() => onJump(definition)}
          >
            {content}
          </button>
        ) : (
          <span key={binding} className="binding" title={binding}>
            {content}
          </span>
        );
      })}
    </div>
  );
}
