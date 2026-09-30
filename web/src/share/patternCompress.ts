// Patterns in share links, compressed as instcombine-instrumentor's links
// compress IR:
//
//   pattern → its tokens as bytes (patternDictionary.ts) → raw DEFLATE
//     (the browser's CompressionStream) → a version byte first → base64url
//
// Version 1 has the tokens as bytes. Patterns are ASCII but for comments;
// the bytes of other characters would be read as tokens, so a pattern with
// any is version 2: its UTF-8 bytes, deflated as they are.

import { DICTIONARY, type DictEntry } from "./patternDictionary.ts";

const VERSION_TOKENS = 0x01;
const VERSION_UTF8 = 0x02;
const FIRST_TOKEN_BYTE = 0x80;

/** The tokens by their first character, the longest first. */
const tokensByHead: Map<string, (DictEntry & { byte: number })[]> = (() => {
  const byHead = new Map<string, (DictEntry & { byte: number })[]>();
  DICTIONARY.forEach((entry, i) => {
    const head = entry.token[0];
    if (!byHead.has(head)) byHead.set(head, []);
    byHead.get(head)!.push({ ...entry, byte: FIRST_TOKEN_BYTE + i });
  });
  for (const tokens of byHead.values()) tokens.sort((a, b) => b.token.length - a.token.length);
  return byHead;
})();

const isWordChar = (c: string | undefined) => c !== undefined && /\w/.test(c);
const isAscii = (text: string) => /^[\x00-\x7f]*$/.test(text);

/** The bytes of ASCII text, its tokens as one byte each. */
export function substituteTokens(text: string): Uint8Array {
  const out: number[] = [];
  for (let i = 0; i < text.length; ) {
    const token = tokensByHead
      .get(text[i])
      ?.find(
        ({ token, wordBoundary }) =>
          text.startsWith(token, i) &&
          (!wordBoundary || (!isWordChar(text[i - 1]) && !isWordChar(text[i + token.length]))),
      );
    if (token) {
      out.push(token.byte);
      i += token.token.length;
    } else {
      out.push(text.charCodeAt(i));
      i++;
    }
  }
  return new Uint8Array(out);
}

/** The text of bytes from substituteTokens. */
export function restoreTokens(bytes: Uint8Array): string {
  let text = "";
  for (const byte of bytes) {
    if (byte < FIRST_TOKEN_BYTE) text += String.fromCharCode(byte);
    else {
      const entry = DICTIONARY[byte - FIRST_TOKEN_BYTE];
      if (!entry) throw new Error(`no token ${byte - FIRST_TOKEN_BYTE}`);
      text += entry.token;
    }
  }
  return text;
}

function toBase64Url(bytes: Uint8Array): string {
  let binary = "";
  for (const byte of bytes) binary += String.fromCharCode(byte);
  return btoa(binary).replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/, "");
}

function fromBase64Url(text: string): Uint8Array {
  if (!/^[A-Za-z0-9_-]*$/.test(text)) throw new Error("not base64url");
  const binary = atob(text.replace(/-/g, "+").replace(/_/g, "/"));
  return Uint8Array.from(binary, (c) => c.charCodeAt(0));
}

/** Whether this browser can compress links. */
export function canCompress(): boolean {
  return typeof CompressionStream === "function" && typeof DecompressionStream === "function";
}

async function transform(bytes: Uint8Array, stream: CompressionStream | DecompressionStream) {
  const piped = new Blob([bytes as BlobPart]).stream().pipeThrough(stream);
  return new Uint8Array(await new Response(piped).arrayBuffer());
}

export async function compressPattern(pattern: string): Promise<string> {
  const ascii = isAscii(pattern);
  const bytes = ascii ? substituteTokens(pattern) : new TextEncoder().encode(pattern);
  const deflated = await transform(bytes, new CompressionStream("deflate-raw"));
  const framed = new Uint8Array(1 + deflated.length);
  framed[0] = ascii ? VERSION_TOKENS : VERSION_UTF8;
  framed.set(deflated, 1);
  return toBase64Url(framed);
}

export async function decompressPattern(link: string): Promise<string> {
  const framed = fromBase64Url(link);
  const version = framed[0];
  if (version !== VERSION_TOKENS && version !== VERSION_UTF8)
    throw new Error(`no link version ${version ?? "given"}`);
  const bytes = await transform(framed.subarray(1), new DecompressionStream("deflate-raw"));
  return version === VERSION_TOKENS
    ? restoreTokens(bytes)
    : new TextDecoder("utf-8", { fatal: true }).decode(bytes);
}
