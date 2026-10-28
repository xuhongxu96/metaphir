// A button that opens a list to choose from. The list closes on a choice, on
// Escape and on a click elsewhere; the arrow keys move through it.

import { useEffect, useLayoutEffect, useRef, useState, type ReactNode } from "react";
import { useDismiss } from "./dismiss.ts";

export interface MenuItem {
  id: string;
  label: string;
  /** A link shown beside the item, opened in a new tab. */
  link?: { href: string; text: string; title?: string };
}

export function Menu({
  id,
  className,
  title,
  label,
  items,
  selected,
  pressed,
  wide,
  onPress,
  onSelect,
  children,
}: {
  id: string;
  className?: string;
  title?: string;
  /** The button's name, when its content is an icon. */
  label?: string;
  items: MenuItem[];
  /** The id of the chosen item. */
  selected?: string;
  /** Whether the button reads as pressed, in a segmented control. */
  pressed?: boolean;
  /** Lets the list be as wide as its items, not the button. */
  wide?: boolean;
  /** Called on each press; returns false to keep the list closed. */
  onPress?: () => boolean | void;
  onSelect: (id: string) => void;
  children: ReactNode;
}) {
  const [open, setOpen] = useState(false);
  const root = useRef<HTMLDivElement>(null);
  const list = useRef<HTMLDivElement>(null);
  // The list hangs from the button's right edge when it would run past the
  // window's.
  const [flip, setFlip] = useState(false);
  const choosable = items.length > 1;
  useDismiss(root, open, () => setOpen(false));
  useLayoutEffect(() => {
    if (!open) return setFlip(false);
    const box = list.current?.getBoundingClientRect();
    if (box && box.right > window.innerWidth - 8) setFlip(true);
  }, [open]);
  useEffect(() => {
    if (!open) return;
    const chosen = list.current?.querySelector<HTMLElement>('[aria-selected="true"]');
    (chosen ?? list.current?.querySelector<HTMLElement>("button"))?.focus();
  }, [open]);

  const move = (key: string) => {
    const buttons = [...(list.current?.querySelectorAll<HTMLElement>("button") ?? [])];
    if (buttons.length === 0) return;
    const at = buttons.indexOf(document.activeElement as HTMLElement);
    const next = key === "ArrowDown" ? at + 1 : at - 1;
    buttons[(next + buttons.length) % buttons.length].focus();
  };

  return (
    <div ref={root} className="menu-wrap">
      <button
        id={id}
        className={className}
        title={title}
        aria-label={label}
        aria-haspopup={choosable ? "listbox" : undefined}
        aria-expanded={choosable ? open : undefined}
        aria-pressed={pressed}
        onClick={() => {
          if (onPress?.() === false) return;
          if (choosable) setOpen(!open);
        }}
      >
        {children}
        {choosable && (
          <svg className="caret" viewBox="0 0 12 12" width="12" height="12" aria-hidden="true">
            <path
              d="M2.5 4.5 6 8l3.5-3.5"
              fill="none"
              stroke="currentColor"
              strokeWidth="1.7"
              strokeLinecap="round"
              strokeLinejoin="round"
            />
          </svg>
        )}
      </button>
      {open && (
        <div
          ref={list}
          role="listbox"
          className={`menu-list${wide ? " wide" : ""}${flip ? " flip" : ""}`}
          onKeyDown={(event) => {
            if (event.key === "ArrowDown" || event.key === "ArrowUp") {
              event.preventDefault();
              move(event.key);
            }
          }}
        >
          {items.map((item) => (
            <div key={item.id} role="none" className="menu-row">
              <button
                role="option"
                aria-selected={item.id === selected}
                className="menu-item"
                onClick={() => {
                  setOpen(false);
                  onSelect(item.id);
                }}
              >
                {item.label}
              </button>
              {item.link && (
                <a
                  className="menu-link"
                  href={item.link.href}
                  target="_blank"
                  rel="noreferrer"
                  title={item.link.title}
                >
                  {item.link.text}
                </a>
              )}
            </div>
          ))}
        </div>
      )}
    </div>
  );
}
