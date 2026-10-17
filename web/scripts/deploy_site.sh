#!/bin/bash
# Builds the website and copies it into a separate repository that deploys it
# to GitHub Pages as it is (with web/site/'s workflow), so that this
# repository can stay private.
#
# Usage: web/scripts/deploy_site.sh <site repository> [--data <url>] [--commit]
#
#   --data <url>  the published corpus the site reads (its config.json);
#                 web/public/config.json's otherwise
#   --commit      commit the site in the site repository (then push it)
#
# The site repository is created (git init) if it does not exist. Everything
# in it but .git is replaced. Run scripts/build_wasm.sh first.
set -euo pipefail

WEB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TARGET=""
DATA=""
COMMIT=0
while [ $# -gt 0 ]; do
    case "$1" in
        --data) DATA="$2"; shift 2 ;;
        --commit) COMMIT=1; shift ;;
        -h|--help) sed -n '2,13p' "$0"; exit 0 ;;
        *)
            if [ -n "$TARGET" ]; then
                echo "Error: unexpected argument '$1'." >&2
                exit 1
            fi
            TARGET="$1"; shift ;;
    esac
done
if [ -z "$TARGET" ]; then
    echo "Usage: $0 <site repository> [--data <url>] [--commit]" >&2
    exit 1
fi
if [ ! -f "$WEB_DIR/public/wasm/metaphir.wasm" ]; then
    echo "Error: no web/public/wasm/metaphir.wasm; run scripts/build_wasm.sh first." >&2
    exit 1
fi

echo "[$(date)] Building the site..."
(cd "$WEB_DIR" && npm ci --silent && npm run build)

mkdir -p "$TARGET"
if [ ! -d "$TARGET/.git" ]; then
    git -C "$TARGET" init -q -b main
fi
find "$TARGET" -mindepth 1 -maxdepth 1 ! -name .git -exec rm -rf {} +
cp -r "$WEB_DIR/dist/." "$TARGET/"
cp -r "$WEB_DIR/site/." "$TARGET/"
# Served as it is, without Jekyll.
touch "$TARGET/.nojekyll"
if [ -n "$DATA" ]; then
    printf '{\n  "data": "%s"\n}\n' "$DATA" > "$TARGET/config.json"
fi
echo "[$(date)] The site is in $TARGET; it reads $(sed -n 's/.*"data": "\(.*\)".*/\1/p' "$TARGET/config.json")"

if [ "$COMMIT" -eq 1 ]; then
    SOURCE="$(git -C "$WEB_DIR" rev-parse --short HEAD 2>/dev/null || echo unknown)"
    git -C "$TARGET" add -A
    if git -C "$TARGET" diff --cached --quiet; then
        echo "Nothing changed since the last deployment."
    else
        git -C "$TARGET" commit -q -m "Deploy MetaphIR $SOURCE"
        echo "Committed; push $TARGET to deploy it."
    fi
fi
