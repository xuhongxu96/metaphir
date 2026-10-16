// A table of rows to select. Dragging the right edge of a column's header
// resizes the column (the widths are kept per table in this browser), and a
// cell hovered shows a button that copies its full text.

import { useRef, useState, type PointerEvent, type ReactNode, type RefObject } from "react";
import { CopyButton } from "./CopyButton.tsx";

export interface Column<Row> {
  title: string;
  /** What the header says on hover. */
  hint?: string;
  /** The cell's full text, which is copied and shown on hover. */
  text: (row: Row) => string;
  /** What the cell shows, if not just its text. */
  render?: (row: Row) => ReactNode;
  /** The class of the column, for its starting width. */
  className?: string;
}

const MIN_WIDTH = 48;

function savedWidths(id: string): number[] | undefined {
  try {
    const saved = JSON.parse(localStorage.getItem(`metaphir-columns-${id}`) ?? "null");
    return Array.isArray(saved) ? saved : undefined;
  } catch {
    return undefined;
  }
}

function saveWidths(id: string, widths: number[]) {
  try {
    localStorage.setItem(`metaphir-columns-${id}`, JSON.stringify(widths));
  } catch {
    // Storage may be unavailable; the widths then last for the page.
  }
}

export function DataTable<Row>(props: {
  /** Names the table whose widths are kept. */
  id: string;
  columns: Column<Row>[];
  rows: Row[];
  rowKey: (row: Row) => string | number;
  selected?: Row;
  onSelect: (row: Row) => void;
  /** The rows' container, as the table's id and ref. */
  bodyId?: string;
  bodyRef?: RefObject<HTMLTableSectionElement | null>;
  className?: string;
}) {
  const { id, columns, rows, rowKey, selected, onSelect, bodyId, bodyRef, className } = props;
  // Pixel widths once a column was resized; until then the columns' classes
  // share the table's width.
  const [widths, setWidths] = useState<number[] | undefined>(() => {
    const saved = savedWidths(id);
    return saved?.length === columns.length ? saved : undefined;
  });
  const header = useRef<HTMLTableRowElement>(null);

  const startResize = (index: number, event: PointerEvent<HTMLElement>) => {
    event.preventDefault();
    event.stopPropagation();
    const cells = [...(header.current?.children ?? [])] as HTMLElement[];
    const start = cells.map((cell) => cell.getBoundingClientRect().width);
    const x = event.clientX;
    const handle = event.currentTarget;
    handle.setPointerCapture(event.pointerId);
    const move = (e: globalThis.PointerEvent) => {
      const next = [...start];
      next[index] = Math.max(MIN_WIDTH, start[index] + e.clientX - x);
      setWidths(next);
    };
    const end = (e: globalThis.PointerEvent) => {
      handle.removeEventListener("pointermove", move);
      handle.removeEventListener("pointerup", end);
      const next = [...start];
      next[index] = Math.max(MIN_WIDTH, start[index] + e.clientX - x);
      saveWidths(id, next);
    };
    handle.addEventListener("pointermove", move);
    handle.addEventListener("pointerup", end);
  };

  return (
    <table
      className={`data-table${className ? ` ${className}` : ""}`}
      style={widths ? { width: widths.reduce((a, b) => a + b, 0) } : undefined}
    >
      <colgroup>
        {columns.map((column, i) => (
          <col
            key={column.title}
            className={column.className}
            style={widths ? { width: widths[i] } : undefined}
          />
        ))}
      </colgroup>
      <thead>
        <tr ref={header}>
          {columns.map((column, i) => (
            <th key={column.title} title={column.hint}>
              {column.title}
              <span
                className="column-resize"
                onPointerDown={(event) => startResize(i, event)}
                onDoubleClick={() => {
                  setWidths(undefined);
                  saveWidths(id, []);
                }}
                title="Drag to resize; double-click to reset"
              />
            </th>
          ))}
        </tr>
      </thead>
      <tbody id={bodyId} ref={bodyRef}>
        {rows.map((row) => (
          <tr
            key={rowKey(row)}
            className={row === selected ? "selected" : undefined}
            onClick={() => onSelect(row)}
          >
            {columns.map((column) => (
              <td key={column.title} title={column.text(row)}>
                {column.render ? column.render(row) : column.text(row)}
                <CopyButton text={column.text(row)} className="cell-copy" title="Copy the cell" />
              </td>
            ))}
          </tr>
        ))}
      </tbody>
    </table>
  );
}
