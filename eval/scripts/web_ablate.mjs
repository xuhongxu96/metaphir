// Runs each pattern in the production build of the site, in headless
// Chromium, against a published directory, with the download throttled
// (default 10 MB/s), once per fresh browser context (cold caches).
//
//   node eval/scripts/web_ablate.mjs <published dir> <config name> <mode: full|no-constraints|no-index> \
//        <out.jsonl> [--mbps 10] [--only pr214541,...] [--throttle 1|0]
//
// Per pattern it records: bytes and requests over the network (CDP), split
// into the corpus header and the query; the page's own "read" and "time";
// and the counts the status panel shows.
import { readFileSync, readdirSync, appendFileSync, writeFileSync } from "node:fs";
import { resolve, join, dirname } from "node:path";
import { fileURLToPath } from "node:url";
import { chromium } from "../../web/node_modules/playwright/index.mjs";
import { preview } from "../../web/node_modules/vite/dist/node/index.js";

const [published, name, mode, out, ...rest] = process.argv.slice(2);
const opt = (k, d) => (rest.includes(k) ? rest[rest.indexOf(k) + 1] : d);
const limit = Number(opt("--limit", "1800")) * 1000; // per pattern
const mbps = Number(opt("--mbps", "10"));
const throttle = opt("--throttle", "1") === "1";
const only = opt("--only", "") ? opt("--only", "").split(",") : null;
const REPO = resolve(dirname(fileURLToPath(import.meta.url)), "../..");
const PATTERNS = join(REPO, "eval/patterns");
process.env.METAPHIR_DATA = resolve(published);
const server = await preview({
  root: join(REPO, "web"),
  preview: { port: 0, host: "127.0.0.1" },
});
const url = server.resolvedUrls.local[0];
const browser = await chromium.launch({
  executablePath: process.env.METAPHIR_CHROMIUM || undefined,
  args: ["--no-sandbox"],
});
const files = readdirSync(PATTERNS).filter((f) => f.endsWith(".mpir")).sort();
const status = () => document.getElementById("status");

async function runOne(file) {
  const pname = file.replace(/\.mpir$/, "");
  const text = readFileSync(join(PATTERNS, file), "utf8");
  const context = await browser.newContext();
  const page = await context.newPage();
  const cdp = await context.newCDPSession(page);
  await cdp.send("Network.enable");
  if (throttle)
    await cdp.send("Network.emulateNetworkConditions", {
      offline: false,
      latency: 0,
      downloadThroughput: (mbps * 1e6),
      uploadThroughput: 100e6,
    });
  const net = { requests: 0, bytes: 0, dataBytes: 0 };
  const urls = new Map();
  cdp.on("Network.responseReceived", (e) => urls.set(e.requestId, e.response.url));
  cdp.on("Network.loadingFinished", (e) => {
    const u = urls.get(e.requestId) ?? "";
    if (!u.includes("/data/")) return;
    net.requests++;
    net.bytes += e.encodedDataLength;
  });
  page.on("pageerror", (e) => console.error("page error:", e.message));
  await page.addInitScript(() => localStorage.setItem("metaphir-guide-dismissed", "1"));
  const q = mode === "full" ? "" : `?mode=${mode}`;
  await page.goto(`${url}${q}#pattern=${encodeURIComponent(text)}`);
  await page.waitForFunction(
    (s) => {
      const el = eval(s)();
      return el.textContent.startsWith("Ready") || el.className.includes("error");
    },
    `(${status})`,
    { timeout: 600_000 },
  );
  const header = { ...net };
  const t0 = Date.now();
  await page.click("#run");
  let seen = 0;
  for (;;) {
    await page.waitForFunction(
      (s) => {
        const el = eval(s)();
        return /^(done|paused|stopped)/.test(el.textContent) || el.className.includes("error");
      },
      `(${status})`,
      { timeout: limit, polling: 200 },
    );
    const s = await page.textContent("#status");
    if (!s.startsWith("paused")) break;
    if (await page.$("#dialog-confirm")) await page.click("#dialog-confirm");
    else {
      if (!(await page.$("#status-panel"))) await page.click("#status-chip");
      await page.click("#continue-to-end");
    }
    await page.waitForFunction(
      ([s2, p]) => eval(s2)().textContent !== p,
      [`(${status})`, s],
      { timeout: 60_000 },
    );
  }
  const wall = (Date.now() - t0) / 1000;
  if (!(await page.$("#status-panel"))) await page.click("#status-chip");
  const info = await page.$eval("#status-panel", (panel) => ({
    status: document.getElementById("status").textContent,
    details: Object.fromEntries(
      [...panel.querySelectorAll(".status-details > div")].map((d) => [
        d.children[0].textContent,
        d.children[1].textContent,
      ]),
    ),
  }));
  await context.close();
  return {
    config: name,
    mode,
    pattern: pname,
    mbps: throttle ? mbps : null,
    wall_s: wall,
    header_bytes: header.bytes,
    header_requests: header.requests,
    query_bytes: net.bytes - header.bytes,
    query_requests: net.requests - header.requests,
    ...info,
  };
}

writeFileSync(out, "");
try {
  for (const f of files) {
    if (only && !only.some((o) => f.startsWith(o))) continue;
    const t = Date.now();
    let row;
    try {
      row = await runOne(f);
    } catch (e) {
      // A pattern that matches very many functions can run for hours.
      row = { config: name, mode, pattern: f.replace(/\.mpir$/, ""), status: "timeout", error: String(e.message).split("\n")[0], wall_s: (Date.now() - t) / 1000, details: {}, query_bytes: 0, query_requests: 0 };
      for (const c of browser.contexts()) await c.close().catch(() => {}); // stop the page
      console.log(`${row.pattern}: timeout after ${row.wall_s.toFixed(0)} s`);
      appendFileSync(out, JSON.stringify(row) + "\n");
      continue;
    }
    appendFileSync(out, JSON.stringify(row) + "\n");
    console.log(
      `${row.pattern}: ${row.status} wall ${row.wall_s.toFixed(1)}s page ${row.details.time} read ${(row.query_bytes / 1e6).toFixed(1)} MB net/${row.details.read} reqs ${row.query_requests}`,
    );
  }
} finally {
  await browser.close();
  server.httpServer.close();
}
