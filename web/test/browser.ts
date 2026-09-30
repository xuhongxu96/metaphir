// Matches a pattern in the production build of the site, in headless
// Chromium, against a published directory, and prints the matches as
// metaphir-match --matches-only --packs does, then the page's status and
// the IR of the first match. The page is then reloaded and the query run
// again, which must read nothing over the network, the blocks read the
// first time being kept.
//
//   npm run build
//   node test/browser.ts <published directory> <pattern>

import { readFileSync } from "node:fs";
import { resolve } from "node:path";
import { chromium } from "playwright";
import { preview } from "vite";

const [published, patternFile] = process.argv.slice(2);
if (!published || !patternFile) {
  console.error("usage: node test/browser.ts <published directory> <pattern>");
  process.exit(2);
}
process.env.METAPHIR_DATA = resolve(published);
const server = await preview({
  root: resolve(import.meta.dirname, ".."),
  preview: { port: 0, host: "127.0.0.1" },
});
const url = server.resolvedUrls!.local[0];
const browser = await chromium.launch();
const status = () => document.getElementById("status")!;
try {
  const page = await browser.newPage();
  page.on("pageerror", (error) => console.error("page error:", error.message));
  const pattern = encodeURIComponent(readFileSync(patternFile, "utf8"));
  const run = async (reload: boolean) => {
    if (reload) await page.reload();
    else await page.goto(`${url}#pattern=${pattern}`);
    await page.waitForFunction(
      (status) => {
        const s = eval(status)();
        return s.textContent!.startsWith("Ready") || s.className.includes("error");
      },
      `(${status})`,
    );
    await page.click("#run");
    await page.waitForFunction(
      (status) => {
        const s = eval(status)();
        return s.textContent!.startsWith("done") || s.className.includes("error");
      },
      `(${status})`,
      { timeout: 600_000 },
    );
    return page.textContent("#status");
  };
  const first = await run(false);
  const rows = await page.$$eval("#matches tr", (rows) =>
    rows.map((row) => [...row.children].map((cell) => cell.textContent).join("\t")),
  );
  for (const row of rows) console.log(row);
  console.error(first);
  if (rows.length) {
    await page.click("#matches tr");
    await page.waitForSelector(".ir-editor .view-lines");
    // Monaco renders the lines in view, around the bound instructions.
    await page.waitForFunction(
      () => document.querySelector(".ir-editor .view-lines")!.textContent!.length > 0,
    );
    const bound = await page.$$eval(".ir-editor .bound-line", (lines) => lines.length);
    console.error(`IR shown, ${bound} bound lines highlighted`);
  }
  console.error(`after reloading: ${await run(true)}`);
} finally {
  await browser.close();
  server.httpServer.close();
}
