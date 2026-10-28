import { createHash } from "node:crypto";
import { createReadStream, existsSync, readdirSync, readFileSync, statSync } from "node:fs";
import { join, normalize, resolve } from "node:path";
import react from "@vitejs/plugin-react";
import { defineConfig, type Connect, type Plugin } from "vite";

/**
 * With METAPHIR_DATA set to a directory published by metaphir-index publish,
 * the development server serves it at /data, byte ranges included, and the
 * site reads it instead of the configured corpora. METAPHIR_ONLINE=1 keeps
 * the configured, online corpora whatever METAPHIR_DATA says.
 */
function localData(): Plugin {
  const online = !["", "0", "false"].includes(process.env.METAPHIR_ONLINE ?? "");
  const dir = online ? undefined : process.env.METAPHIR_DATA;
  const serve = (server: { middlewares: Connect.Server }) => {
    if (!dir) return;
    const root = resolve(dir);
    server.middlewares.use((request, response, next) => {
      const url = new URL(request.url ?? "/", "http://localhost");
      if (url.pathname.endsWith("/config.json")) {
        response.setHeader("content-type", "application/json");
        response.end(
          JSON.stringify({
            default: process.env.METAPHIR_CORPUS ?? "local",
            corpora: [
              {
                id: process.env.METAPHIR_CORPUS ?? "local",
                label: "Local corpus",
                data: "/data",
              },
            ],
          }),
        );
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
      // "bytes=start-end" or "bytes=start-", as HTTP has them.
      const range = /^bytes=(\d+)-(\d*)$/.exec(request.headers.range ?? "");
      if (!range) {
        response.setHeader("content-length", size);
        createReadStream(file).pipe(response);
        return;
      }
      const start = Number(range[1]);
      if (start >= size) {
        response.statusCode = 416;
        response.setHeader("content-range", `bytes */${size}`);
        response.end();
        return;
      }
      const end = Math.min(range[2] ? Number(range[2]) : size - 1, size - 1);
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

/**
 * With METAPHIR_ONLINE=1 and no WebAssembly modules built in public/wasm, the
 * development server fetches them from the deployed site (METAPHIR_WASM_URL,
 * by default https://xuhongxu.com/metaphir/wasm), so that the page runs
 * without scripts/build_wasm.sh. Modules built here are served as they are.
 */
function onlineWasm(): Plugin {
  const online = !["", "0", "false"].includes(process.env.METAPHIR_ONLINE ?? "");
  const built = existsSync(resolve(import.meta.dirname, "public/wasm/metaphir.js"));
  return {
    name: "metaphir-online-wasm",
    config() {
      if (!online || built) return;
      const site = new URL(process.env.METAPHIR_WASM_URL ?? "https://xuhongxu.com/metaphir/wasm");
      const prefix = site.pathname.replace(/\/$/, "");
      return {
        server: {
          proxy: {
            "/wasm": { target: site.origin, changeOrigin: true, rewrite: (path) => prefix + path.slice("/wasm".length) },
          },
        },
      };
    },
  };
}

/**
 * A hash of the WebAssembly modules, which the page adds to their URLs:
 * modules from an earlier build are then never taken from a cache.
 */
function wasmVersion(): string {
  const dir = resolve(import.meta.dirname, "public/wasm");
  const hash = createHash("sha256");
  try {
    for (const name of readdirSync(dir).sort()) hash.update(name).update(readFileSync(join(dir, name)));
  } catch {
    // No modules built yet.
  }
  return hash.digest("hex").slice(0, 12);
}

export default defineConfig({
  define: { __WASM_VERSION__: JSON.stringify(wasmVersion()) },
  // Served from a subpath of GitHub Pages.
  base: "./",
  plugins: [react(), localData(), onlineWasm()],
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
