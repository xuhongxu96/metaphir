// Corpora the user adds: a name and the URL of a published build, kept in
// this browser and listed in the corpus menu beside the site's.

import type { CorpusConfig, SiteConfig } from "./corpora.ts";

export interface CustomCorpus {
  id: string;
  label: string;
  /** The build root: the URL under which manifest.json and the data live. */
  data: string;
}

export const CUSTOM_KEY = "metaphir-custom-corpora";

const ID = /^[A-Za-z0-9._-]+$/;
const HF = "https://huggingface.co/";

/**
 * The build root a typed link names. Accepts the build's URL, its
 * manifest.json, a Hugging Face bucket's tree/blob page, or `hf://buckets/…`.
 */
export function normalizeDataUrl(input: string): string {
  let text = input.trim();
  if (text === "") throw new Error("Enter the URL of the published build.");
  if (text.startsWith("hf://")) text = `${HF}${text.slice("hf://".length)}`;
  let url: URL;
  try {
    url = new URL(text);
  } catch {
    throw new Error("That is not a URL.");
  }
  const local = url.hostname === "localhost" || url.hostname === "127.0.0.1";
  if (url.protocol !== "https:" && !(url.protocol === "http:" && local))
    throw new Error("The URL must start with https://.");
  url.hash = "";
  url.search = "";
  let path = url.pathname.replace(/\/+$/, "").replace(/\/manifest\.json$/, "");
  if (url.host === "huggingface.co")
    path = path.replace(/^(\/buckets\/[^/]+\/[^/]+)\/(?:tree|blob)\/(?:main\/)?/, "$1/resolve/");
  return `${url.origin}${path}`;
}

/** A fresh id: unused here, and not one of `taken`. */
export function newCustomId(
  existing: readonly CustomCorpus[],
  taken: ReadonlySet<string> = new Set(),
  random: () => number = Math.random,
): string {
  for (;;) {
    const id = `u-${Math.floor(random() * 36 ** 6).toString(36).padStart(6, "0")}`;
    if (!taken.has(id) && !existing.some((c) => c.id === id)) return id;
  }
}

/** Checks a name and a link; returns the entry's fields, or throws. */
export function checkEntry(
  label: string,
  link: string,
  others: readonly CustomCorpus[],
): { label: string; data: string } {
  const name = label.trim();
  if (name === "") throw new Error("Enter a name.");
  const data = normalizeDataUrl(link);
  if (others.some((c) => c.label.toLowerCase() === name.toLowerCase()))
    throw new Error(`There is already a corpus named “${name}”.`);
  if (others.some((c) => c.data === data))
    throw new Error("That build is already in the list.");
  return { label: name, data };
}

export function addCorpus(list: readonly CustomCorpus[], corpus: CustomCorpus): CustomCorpus[] {
  return [...list, corpus];
}

export function updateCorpus(
  list: readonly CustomCorpus[],
  id: string,
  fields: { label: string; data: string },
): CustomCorpus[] {
  return list.map((c) => (c.id === id ? { ...c, ...fields } : c));
}

export function removeCorpus(list: readonly CustomCorpus[], id: string): CustomCorpus[] {
  return list.filter((c) => c.id !== id);
}

/** The stored list; entries that are not well formed are dropped. */
export function parseStored(raw: string | null): CustomCorpus[] {
  let value: unknown;
  try {
    value = JSON.parse(raw ?? "[]");
  } catch {
    return [];
  }
  if (!Array.isArray(value)) return [];
  const list: CustomCorpus[] = [];
  const seen = new Set<string>();
  for (const item of value) {
    if (typeof item !== "object" || item === null) continue;
    const { id, label, data } = item as Record<string, unknown>;
    if (typeof id !== "string" || !ID.test(id) || seen.has(id)) continue;
    if (typeof label !== "string" || label === "") continue;
    if (typeof data !== "string") continue;
    try {
      normalizeDataUrl(data);
    } catch {
      continue;
    }
    seen.add(id);
    list.push({ id, label, data });
  }
  return list;
}

export function loadCustom(): CustomCorpus[] {
  try {
    return parseStored(localStorage.getItem(CUSTOM_KEY));
  } catch {
    return [];
  }
}

export function saveCustom(list: readonly CustomCorpus[]): void {
  try {
    if (list.length === 0) localStorage.removeItem(CUSTOM_KEY);
    else localStorage.setItem(CUSTOM_KEY, JSON.stringify(list));
  } catch {
    // Kept for this visit only.
  }
}

/** The site's config with the user's corpora after its own. A custom corpus
 * whose id is a site corpus's is left out. */
export function withCustom(config: SiteConfig, custom: readonly CustomCorpus[]): SiteConfig {
  const taken = new Set(config.corpora.map((c) => c.id));
  const added: CorpusConfig[] = custom
    .filter((c) => !taken.has(c.id))
    .map((c) => ({ id: c.id, label: c.label, description: "Added by you", data: c.data }));
  return { ...config, corpora: [...config.corpora, ...added] };
}

/** Reads the build's manifest; throws what is wrong with the link. */
export async function checkBuild(data: string, signal?: AbortSignal): Promise<void> {
  let response: Response;
  try {
    response = await fetch(`${data}/manifest.json`, { signal, cache: "no-cache" });
  } catch (error) {
    if (signal?.aborted) throw error;
    throw new Error("Could not reach that URL (the host may not allow this page to read it).");
  }
  if (!response.ok) throw new Error(`No manifest.json there (HTTP ${response.status}).`);
  let manifest: unknown;
  try {
    manifest = await response.json();
  } catch {
    throw new Error("manifest.json there is not JSON.");
  }
  const m = manifest as { build?: unknown; files?: unknown } | null;
  if (typeof m?.build !== "string" || typeof m.files !== "object")
    throw new Error("That is not a published MetaphIR build.");
}
