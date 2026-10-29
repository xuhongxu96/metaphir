// The user's own corpora, over the page: a list to add to, edit and delete
// from, each a name and the URL of a published build, e.g. one in their own
// Hugging Face bucket. Escape or the close button closes it, and focus goes
// back where it was. The list is kept by the page; this only asks for changes.

import { useEffect, useRef, useState, type FormEvent } from "react";
import { checkBuild, checkEntry, type CustomCorpus } from "./customCorpora.ts";

export function CustomCorporaDialog(props: {
  corpora: CustomCorpus[];
  /** The id of the corpus the page searches. */
  activeId?: string;
  onAdd: (fields: { label: string; data: string }) => void;
  onUpdate: (id: string, fields: { label: string; data: string }) => void;
  onDelete: (id: string) => void;
  onUse: (id: string) => void;
  onClose: () => void;
}) {
  const { corpora, activeId, onAdd, onUpdate, onDelete, onUse, onClose } = props;
  // The corpus being edited, "new" for a new one, or none.
  const [editing, setEditing] = useState<string | "new" | undefined>(
    corpora.length === 0 ? "new" : undefined,
  );
  const [label, setLabel] = useState("");
  const [link, setLink] = useState("");
  const [error, setError] = useState<string>();
  // A build that could not be read, which a second Save keeps anyway.
  const [unverified, setUnverified] = useState<string>();
  const [checking, setChecking] = useState(false);
  const [deleting, setDeleting] = useState<string>();
  const abort = useRef<AbortController>(null);
  const nameInput = useRef<HTMLInputElement>(null);

  useEffect(() => {
    const focused = document.activeElement as HTMLElement | null;
    return () => {
      abort.current?.abort();
      focused?.focus();
    };
  }, []);
  useEffect(() => {
    if (editing !== undefined) nameInput.current?.focus();
  }, [editing]);

  const open = (id: string | "new") => {
    const corpus = corpora.find((c) => c.id === id);
    setEditing(id);
    setLabel(corpus?.label ?? "");
    setLink(corpus?.data ?? "");
    setError(undefined);
    setUnverified(undefined);
    setDeleting(undefined);
  };
  const close = () => {
    abort.current?.abort();
    setEditing(undefined);
    setChecking(false);
    setError(undefined);
    setUnverified(undefined);
  };

  const save = async (event: FormEvent) => {
    event.preventDefault();
    if (editing === undefined || checking) return;
    let fields: { label: string; data: string };
    try {
      fields = checkEntry(
        label,
        link,
        corpora.filter((c) => c.id !== editing),
      );
    } catch (e) {
      setError((e as Error).message);
      return;
    }
    if (unverified !== fields.data) {
      abort.current?.abort();
      const controller = new AbortController();
      abort.current = controller;
      setChecking(true);
      setError(undefined);
      try {
        await checkBuild(fields.data, controller.signal);
      } catch (e) {
        if (controller.signal.aborted) return;
        setChecking(false);
        setUnverified(fields.data);
        setError(`${(e as Error).message} Save again to keep it anyway.`);
        return;
      }
      if (controller.signal.aborted) return;
      setChecking(false);
    }
    if (editing === "new") onAdd(fields);
    else onUpdate(editing, fields);
    close();
  };

  // Escape leaves the form, then the dialog; focus may be nowhere in the
  // dialog once a button it held has gone, so listen on the document.
  const escape = useRef<() => void>(() => {});
  escape.current = () => {
    if (editing !== undefined && corpora.length > 0) close();
    else onClose();
  };
  useEffect(() => {
    const onKey = (event: globalThis.KeyboardEvent) => {
      if (event.key !== "Escape") return;
      event.preventDefault();
      escape.current();
    };
    document.addEventListener("keydown", onKey);
    return () => document.removeEventListener("keydown", onKey);
  }, []);

  return (
    <div
      className="dialog-backdrop"
      onMouseDown={(event) => {
        if (event.target === event.currentTarget) onClose();
      }}
    >
      <div
        id="corpora-dialog"
        className="dialog corpora-dialog"
        role="dialog"
        aria-modal="true"
        aria-labelledby="corpora-title"
      >
        <header className="corpora-head">
          <div>
            <h2 id="corpora-title">Your corpora</h2>
            <p>Published builds you add are kept in this browser, and must be public.</p>
          </div>
          <button id="corpora-close" className="corpora-x" onClick={onClose} aria-label="Close">
            <svg viewBox="0 0 12 12" width="12" height="12" aria-hidden="true">
              <path
                d="M2 2l8 8M10 2l-8 8"
                stroke="currentColor"
                strokeWidth="1.6"
                strokeLinecap="round"
              />
            </svg>
          </button>
        </header>
        <div className="corpora-body">
          {corpora.length === 0 && editing === undefined && (
            <p className="corpora-empty">No corpora yet.</p>
          )}
          {corpora.length > 0 && (
            <ul className="corpora-list">
              {corpora.map((c) => (
                <li key={c.id} data-active={c.id === activeId}>
                  <span className="corpus-text">
                    <span className="corpus-name" title={c.label}>
                      {c.label}
                    </span>
                    <span className="corpus-url" title={c.data}>
                      {c.data.replace(/^https:\/\//, "")}
                    </span>
                  </span>
                  <span className="corpus-actions">
                    {c.id === activeId ? (
                      <span className="corpus-badge">In use</span>
                    ) : (
                      <button onClick={() => onUse(c.id)} title="Search this corpus">
                        Use
                      </button>
                    )}
                    <button
                      className="quiet"
                      onClick={() => open(c.id)}
                      aria-label={`Edit ${c.label}`}
                    >
                      Edit
                    </button>
                    {deleting === c.id ? (
                      <button
                        className="quiet danger"
                        onClick={() => {
                          setDeleting(undefined);
                          if (editing === c.id) close();
                          onDelete(c.id);
                        }}
                        onBlur={() => setDeleting(undefined)}
                        autoFocus
                      >
                        Confirm
                      </button>
                    ) : (
                      <button
                        className="quiet"
                        onClick={() => setDeleting(c.id)}
                        aria-label={`Delete ${c.label}`}
                      >
                        Delete
                      </button>
                    )}
                  </span>
                </li>
              ))}
            </ul>
          )}
          {editing === undefined ? (
            <button id="corpus-add" className="corpora-add" onClick={() => open("new")}>
              + Add a corpus
            </button>
          ) : (
            <form className="corpora-form" onSubmit={(e) => void save(e)}>
              <h3>{editing === "new" ? "Add a corpus" : "Edit corpus"}</h3>
              <label>
                <span>Name</span>
                <input
                  ref={nameInput}
                  id="corpus-name"
                  value={label}
                  onChange={(e) => setLabel(e.target.value)}
                  placeholder="My corpus"
                />
              </label>
              <label>
                <span>Build URL</span>
                <input
                  id="corpus-url"
                  value={link}
                  onChange={(e) => {
                    setLink(e.target.value);
                    setUnverified(undefined);
                  }}
                  placeholder="https://huggingface.co/buckets/owner/bucket/resolve/builds/…"
                  spellCheck={false}
                  autoCapitalize="off"
                />
                <small>
                  Where <code>manifest.json</code> is, as <code>web/scripts/publish.py</code>{" "}
                  uploads it.
                </small>
              </label>
              {error && (
                <p className="form-error" role="alert">
                  {error}
                </p>
              )}
              <div className="form-actions">
                {corpora.length > 0 && (
                  <button type="button" onClick={close}>
                    Cancel
                  </button>
                )}
                <button id="corpus-save" type="submit" className="primary" disabled={checking}>
                  {checking ? "Checking…" : editing === "new" ? "Add" : "Save"}
                </button>
              </div>
            </form>
          )}
        </div>
      </div>
    </div>
  );
}
