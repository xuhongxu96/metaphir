import { createReadStream, rmSync, statSync } from "node:fs";
import { join, normalize, resolve } from "node:path";
import react from "@vitejs/plugin-react";
import { defineConfig, type Connect, type Plugin } from "vite";

/**
 * With METAPHIR_DATA set to a directory published by metaphir-index publish,
 * the development server serves it at /data, byte ranges included, and the
 * site reads it instead of the configured corpus.
 */
function localData(): Plugin {
  const dir = process.env.METAPHIR_DATA;
  const serve = (server: { middlewares: Connect.Server }) => {
      if (!dir) return;
      const root = resolve(dir);
      server.middlewares.use((request, response, next) => {
        const url = new URL(request.url ?? "/", "http://localhost");
        if (url.pathname.endsWith("/config.json")) {
          response.setHeader("content-type", "application/json");
          response.end(JSON.stringify({ data: "/data" }));
          return;
        }
        if (!url.pathname.startsWith("/data/")) return next();
        const file = normalize(join(root, url.pathname.slice("/data/".length)));
        if (!file.startsWith(root)) return next();
        let size: number;
        try {
          size = statSync(file).size;
        } catch {
          response.statusCode = 404;
          response.end();
          return;
        }
        const range = /bytes=(\d+)-(\d+)/.exec(request.headers.range ?? "");
        if (!range) {
          response.setHeader("content-length", size);
          createReadStream(file).pipe(response);
          return;
        }
        const start = Number(range[1]);
        const end = Math.min(Number(range[2]), size - 1);
        response.statusCode = 206;
        response.setHeader("content-range", `bytes ${start}-${end}/${size}`);
        response.setHeader("content-length", end - start + 1);
        createReadStream(file, { start, end }).pipe(response);
      });
  };
  return {
    name: "metaphir-local-data",
    configureServer: serve,
    configurePreviewServer: serve,
  };
}

/** Local files are matched in the development server only. */
function withoutLocalMatcher(): Plugin {
  let outDir = "dist";
  return {
    name: "metaphir-without-local-matcher",
    apply: "build",
    configResolved(config) {
      outDir = resolve(config.root, config.build.outDir);
    },
    closeBundle() {
      for (const ext of ["js", "wasm"])
        rmSync(join(outDir, "wasm", `metaphir-match.${ext}`), { force: true });
    },
  };
}

export default defineConfig({
  // Served from a subpath of GitHub Pages.
  base: "./",
  plugins: [react(), localData(), withoutLocalMatcher()],
  resolve: {
    alias: {
      // Monaco's package exports only its scripts; its icon font's style is
      // imported directly.
      "monaco-codicon.css": resolve(
        import.meta.dirname,
        "node_modules/monaco-editor/esm/vs/base/browser/ui/codicons/codicon/codicon.css",
      ),
    },
  },
  worker: { format: "es" },
  server: { fs: { allow: [".."] } },
  build: { target: "es2022" },
});
