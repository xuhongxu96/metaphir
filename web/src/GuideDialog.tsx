// The pattern guide, over the page, which opens with the page until asked
// not to: first demonstrations, each a pattern beside
// IR it matches, their parts named and explained where they are; then
// patterns that put them together, to try; then the reference, of every
// meta flag, constraint operator and matcher there is. Trying a pattern puts
// it in the editor. Escape, the close button or a click outside closes it,
// and focus goes back where it was.

import { Fragment, useEffect, useRef, useState, type KeyboardEvent, type ReactNode } from "react";
import {
  DEMOS,
  IDIOMS,
  MATCHERS,
  META_FLAGS,
  OPERATORS,
  SETTINGS,
  TRY,
  marked,
  markOf,
  unmarked,
  type Demo,
  type Entry,
  type Group,
} from "./guide.ts";
import { colored, useColorRuns, type CodeLanguage } from "./colorize.ts";

/** Code colored as the editors color it. */
function Code({ text, language }: { text: string; language: CodeLanguage }) {
  const runs = useColorRuns(text, language);
  return colored(text, 0, runs).map((piece, i) =>
    piece.className ? (
      <span key={i} className={piece.className}>
        {piece.text}
      </span>
    ) : (
      <Fragment key={i}>{piece.text}</Fragment>
    ),
  );
}

/** Text with `code` in backquotes, and its lines broken where it breaks them.
 * The code is colored unless plain. */
function Prose({ text, plain }: { text: string; plain?: boolean }) {
  return text.split("\n").map((line, l) => (
    <Fragment key={l}>
      {l > 0 && <br />}
      {line.split("`").map((piece, i) => (i % 2 ? (
          <code key={i}>{plain ? piece : <Code text={piece} language="metaphir" />}</code>
        ) : (
          piece
        )))}
    </Fragment>
  ));
}

/** A marked pattern or IR. Each mark is underlined in its kind's color;
 * the first of each name has the name under it, and hovering or focusing it
 * says what it is. The uses of a meta variable or local, and what it binds
 * in the IR, light up together. */
type MarkedProps = {
  text: string;
  demo: Demo;
  /** Whether text is the IR, whose marks are named by what binds them. */
  ir?: boolean;
  lit?: string;
  onLight: (variable: string | undefined) => void;
};

function Marked(props: MarkedProps) {
  return (
    <pre className="help-code annotated">
      <MarkedParts {...props} />
    </pre>
  );
}

function MarkedParts(props: MarkedProps) {
  const { text, demo, ir, lit, onLight } = props;
  const named = new Set<string>();
  // The code is colored, and a mark in the color of its kind over it.
  const runs = useColorRuns(unmarked(text), ir ? "llvm" : "metaphir");
  let at = 0;
  return (
    <>
      {marked(text).map((part, i) => {
        const start = at;
        at += part.text.length;
        if (!part.kind)
          return colored(part.text, start, runs).map((piece, j) =>
            piece.className ? (
              <span key={`${i}.${j}`} className={piece.className}>
                {piece.text}
              </span>
            ) : (
              <Fragment key={`${i}.${j}`}>{piece.text}</Fragment>
            ),
          );
        const mark = ir ? undefined : markOf(demo, part.text, part.kind);
        const name = ir ? part.of : mark?.name;
        const says = ir ? part.of && `Bound by ${part.of}.` : mark?.says;
        // A meta variable or local lights with its other uses, and with what
        // it binds in the IR.
        const variable = ir ? part.of : /^[?%][\w$.]+$/.test(part.text) ? part.text : undefined;
        // In the IR, a name shows while what binds it is lit.
        const first = name !== undefined && (ir || !named.has(name));
        if (name) named.add(name);
        const light = variable && (() => onLight(variable));
        return (
          <span
            key={i}
            className={`mark mark-${part.kind}${variable && variable === lit ? " lit" : ""}`}
            data-says={says ? "" : undefined}
            tabIndex={says ? 0 : undefined}
            onMouseEnter={light || undefined}
            onFocus={light || undefined}
            onMouseLeave={light ? () => onLight(undefined) : undefined}
            onBlur={light ? () => onLight(undefined) : undefined}
          >
            {part.text}
            {says && (
              // Above the part, so that the pointer does not hide what it says
              // of: the part as written, then its name and what it is.
              <span className="mark-tip" role="tooltip">
                <code>{part.text}</code>
                {!ir && name && <b>{name}</b>}
                <span>{says}</span>
              </span>
            )}
            {first && (!ir || variable === lit) && (
              <span className="mark-name" aria-hidden="true">
                {name}
              </span>
            )}
          </span>
        );
      })}
    </>
  );
}

/** Patterns matched each on its own: hovering or focusing one lights the
 * instructions it matches, with what it binds in each, and dims the rest. */
function Cases({ demo }: { demo: Demo }) {
  const [on, setOn] = useState<number>();
  const shown = on === undefined ? undefined : demo.cases![on];
  const noLight = () => {};
  return (
    <div className="help-pair">
      <div>
        <div className="help-label">Patterns</div>
        <div className="help-code annotated help-cases">
          {demo.cases!.map((c, i) => (
            <div
              key={c.pattern}
              className={`case${i === on ? " on" : ""}`}
              tabIndex={0}
              onMouseEnter={() => setOn(i)}
              onFocus={() => setOn(i)}
              onMouseLeave={() => setOn(undefined)}
              onBlur={() => setOn(undefined)}
            >
              <MarkedParts text={c.pattern} demo={demo} onLight={noLight} />
            </div>
          ))}
        </div>
      </div>
      <div>
        <div className="help-label">{shown ? "It Matches" : "Instructions"}</div>
        <div className="help-code annotated help-cases">
          {demo.matches.split("\n").map((line, i) => {
            const at = shown?.matches.indexOf(i) ?? -1;
            const state = !shown ? "" : at < 0 ? " dim" : " on";
            return (
              <div key={i} className={`case-line${state}`}>
                <Code text={line} language="llvm" />
                {at >= 0 && <span className="case-note">✓ {shown!.binds?.[at] ?? ""}</span>}
              </div>
            );
          })}
        </div>
      </div>
    </div>
  );
}

function DemoSection({ demo, onGo }: { demo: Demo; onGo: (id: string) => void }) {
  const [lit, setLit] = useState<string>();
  return (
    <section id={`help-${demo.id}`} className="help-section">
      <h3>{demo.title}</h3>
      <p>
        <Prose text={demo.intro} />
      </p>
      {demo.cases ? (
        <Cases demo={demo} />
      ) : (
        <div className="help-pair">
          <div>
            <div className="help-label">Pattern</div>
            <Marked text={demo.pattern} demo={demo} lit={lit} onLight={setLit} />
          </div>
          <div>
            <div className="help-label">Matches</div>
            <Marked text={demo.matches} demo={demo} ir lit={lit} onLight={setLit} />
          </div>
        </div>
      )}
      {demo.aside && (
        <div className="help-aside">
          <div className="help-label">{demo.aside.title}</div>
          <pre className="help-code">
            <Code text={demo.aside.code} language="cpp" />
          </pre>
        </div>
      )}
      {demo.notes && (
        <ul className="help-notes">
          {demo.notes.map((note) => (
            <li key={note}>
              <Prose text={note} />
            </li>
          ))}
        </ul>
      )}
      {demo.see && (
        <p className="help-see">
          See{" "}
          {demo.see.map((id, i) => (
            <Fragment key={id}>
              {i > 0 && " and "}
              <button className="link" onClick={() => onGo(id)}>
                {REFERENCE.find(([ref]) => ref === id)![1]}
              </button>
            </Fragment>
          ))}{" "}
          in the reference.
        </p>
      )}
    </section>
  );
}

/** Entries, each as written beside what it means. */
const Entries = ({ entries }: { entries: Entry[] }) => (
  <dl className="help-entries">
    {entries.map(([written, means]) => (
      <div key={written}>
        <dt>
          <code>{written}</code>
        </dt>
        <dd>{means}</dd>
      </div>
    ))}
  </dl>
);

function Groups({ groups }: { groups: Group[] }) {
  return groups.map((group) => (
    <div key={group.title} className="help-group">
      <h4>{group.title}</h4>
      {group.about && (
        <p className="help-about">
          <Prose text={group.about} plain />
        </p>
      )}
      <Entries entries={group.entries} />
    </div>
  ));
}

const LEARN: [string, string][] = [
  ...DEMOS.map((d): [string, string] => [d.id, d.title]),
  ["try", "Try These"],
];
const REFERENCE: [string, string][] = [
  ["ref-flags", "Meta Flags"],
  ["ref-operators", "Constraint Operators"],
  ["ref-matchers", "Matchers"],
  ["ref-settings", "Settings"],
  ["ref-idioms", "From InstCombine"],
];

function Reference({ id, title, children }: { id: string; title: string; children: ReactNode }) {
  return (
    <section id={`help-${id}`} className="help-section">
      <h3>{title}</h3>
      {children}
    </section>
  );
}

const DISMISSED_KEY = "metaphir-guide-dismissed";

/** Whether the guide is not to open when the page does, as asked. */
export function guideDismissed(): boolean {
  try {
    return localStorage.getItem(DISMISSED_KEY) === "1";
  } catch {
    return false;
  }
}

function setGuideDismissed(dismissed: boolean) {
  try {
    if (dismissed) localStorage.setItem(DISMISSED_KEY, "1");
    else localStorage.removeItem(DISMISSED_KEY);
  } catch {
    // Storage may be unavailable; the guide then opens each time.
  }
}

export function GuideDialog(props: { onTry: (pattern: string) => void; onClose: () => void }) {
  const { onTry, onClose } = props;
  const [dismissed, setDismissed] = useState(guideDismissed);
  const close = useRef<HTMLButtonElement>(null);
  const body = useRef<HTMLDivElement>(null);
  useEffect(() => {
    const focused = document.activeElement as HTMLElement | null;
    close.current?.focus();
    return () => focused?.focus();
  }, []);
  const onKeyDown = (event: KeyboardEvent<HTMLDivElement>) => {
    if (event.key === "Escape") {
      event.preventDefault();
      onClose();
    }
  };
  // The section being read: the last whose top is at the top of the body,
  // or the last of all at the end.
  const [current, setCurrent] = useState<string>(LEARN[0][0]);
  const follow = () => {
    const root = body.current;
    if (!root) return;
    const top = root.getBoundingClientRect().top + 24;
    const sections = [...LEARN, ...REFERENCE].map(([id]) => id);
    const atEnd = root.scrollTop + root.clientHeight >= root.scrollHeight - 2;
    let reading = sections[0];
    for (const id of sections) {
      const section = root.querySelector(`#help-${id}`);
      if (section && section.getBoundingClientRect().top <= top) reading = id;
    }
    setCurrent(atEnd ? sections[sections.length - 1] : reading);
  };
  const go = (id: string) => body.current?.querySelector(`#help-${id}`)?.scrollIntoView({ block: "start" });
  const nav = (links: [string, string][]) =>
    links.map(([id, title]) => (
      <button
        key={id}
        className={`link${id === current ? " current" : ""}`}
        aria-current={id === current ? "location" : undefined}
        onClick={() => go(id)}
      >
        {title}
      </button>
    ));
  return (
    <div className="dialog-backdrop" onClick={(e) => e.target === e.currentTarget && onClose()}>
      <div
        id="help"
        className="dialog help-dialog"
        role="dialog"
        aria-modal="true"
        aria-labelledby="help-title"
        onKeyDown={onKeyDown}
      >
        <div className="help-header">
          <h2 id="help-title">Pattern Guide</h2>
          <span className="spacer" />
          <label className="help-dismiss">
            <input
              id="help-dismiss"
              type="checkbox"
              checked={dismissed}
              onChange={(e) => {
                setDismissed(e.target.checked);
                setGuideDismissed(e.target.checked);
              }}
            />
            Don't show again
          </label>
          <button id="help-close" ref={close} onClick={onClose}>
            Close
          </button>
        </div>
        <nav className="help-nav">
          <div>
            <span>Learn</span>
            {nav(LEARN)}
          </div>
          <div>
            <span>Reference</span>
            {nav(REFERENCE)}
          </div>
        </nav>
        <div className="help-body" ref={body} onScroll={follow}>
          {DEMOS.map((demo) => (
            <DemoSection key={demo.id} demo={demo} onGo={go} />
          ))}
          <section id="help-try" className="help-section">
            <h3>Try These</h3>
            <p>Patterns that combine the above. Try one in the corpus.</p>
            <div className="help-tries">
              {TRY.map((example) => (
                <div key={example.title} className="help-try">
                  <div className="help-try-header">
                    <span>{example.title}</span>
                    <button className="link" onClick={() => onTry(example.pattern)}>
                      try
                    </button>
                  </div>
                  <pre className="help-code">
                    <Code text={example.pattern} language="metaphir" />
                  </pre>
                </div>
              ))}
            </div>
          </section>
          <h2 className="help-part">Reference</h2>
          <Reference id="ref-flags" title="Meta Flags">
            <Groups groups={META_FLAGS} />
          </Reference>
          <Reference id="ref-operators" title="Constraint Operators">
{OPERATORS.map((o) => (
              <div key={o.title} className="help-group">
                <h4>{o.title}</h4>
                {o.about && (
                  <p className="help-about">
                    <Prose text={o.about} plain />
                  </p>
                )}
                <Entries entries={o.entries} />
                <code className="help-example">e.g. ;; {o.example}</code>
              </div>
            ))}
          </Reference>
          <Reference id="ref-matchers" title="Matchers of the Standard Library">
            <Groups groups={MATCHERS} />
          </Reference>
          <Reference id="ref-settings" title="Settings">
            <Entries entries={SETTINGS.map((s): Entry => [s.setting, s.says])} />
          </Reference>
          <Reference id="ref-idioms" title="From InstCombine: PatternMatch.h and Patterns">
            <table className="help-table help-idioms">
              <thead>
                <tr>
                  <th>PatternMatch.h</th>
                  <th>Pattern</th>
                </tr>
              </thead>
              <tbody>
                {IDIOMS.map((idiom) => (
                  <tr key={idiom.llvm}>
                    <td>
                      <pre>
                        <Code text={idiom.llvm} language="cpp" />
                      </pre>
                    </td>
                    <td>
                      <pre>
                        <Code text={idiom.pattern} language="metaphir" />
                      </pre>
                      {idiom.note && <p className="help-idiom-note">{idiom.note}</p>}
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </Reference>
        </div>
      </div>
    </div>
  );
}
