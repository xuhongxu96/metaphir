// Matches a pattern in the production build of the site, in headless
// Chromium, against a published directory, and prints the matches as
// metaphir-match --matches-only --packs does, then the page's status and
// the IR of the first match. The query is then run again in the page, whose
// matched instructions must be highlighted again; then the page is reloaded
// and the query run again, which must read nothing over the network, the
// blocks read the first time being kept.
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
  // The status and its details, on one line.
  const describe = async () => {
    if (!(await page.$("#status-panel"))) await page.click("#status-chip");
    return page.$eval("#status-panel", (panel) =>
      [
        document.getElementById("status")!.textContent,
        ...[...panel.querySelectorAll(".status-details > div")].map(
          (d) => `${d.children[0].textContent} ${d.children[1].textContent}`,
        ),
      ].join(" · "),
    );
  };
  // Continues whenever the query pauses, until it is done.
  const finish = async () => {
    for (;;) {
      await page.waitForFunction(
        (status) => {
          const s = eval(status)();
          return (
            /^(done|paused)/.test(s.textContent!) || s.className.includes("error")
          );
        },
        `(${status})`,
        { timeout: 600_000 },
      );
      const paused = (await page.textContent("#status"))!;
      if (!paused.startsWith("paused")) return;
      // A large search asks first, in a dialog.
      await page.click((await page.$("#dialog-confirm")) ? "#dialog-confirm" : "#continue");
      // The next pause can come before the page shows the query going on.
      await page.waitForFunction(
        ([status, paused]) => eval(status)().textContent !== paused,
        [`(${status})`, paused],
      );
    }
  };
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
    await finish();
    return describe();
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

    // Matching again highlights the new matches' instructions as well.
    await page.click("#run");
    await finish();
    await page.waitForSelector(".ir-editor .view-lines");
    await page.waitForTimeout(1000);
    const again = await page.$$eval(".ir-editor .bound-line", (lines) => lines.length);
    console.error(`matched again, ${again} bound lines highlighted`);
    if (bound > 0 && again === 0) {
      console.error("error: matching again lost the highlighting");
      process.exitCode = 1;
    }
  }
  console.error(`after reloading: ${await run(true)}`);
} finally {
  await browser.close();
  server.httpServer.close();
}
