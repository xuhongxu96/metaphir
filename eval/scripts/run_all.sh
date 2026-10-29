#!/bin/bash
# Run every evaluation step on one corpus, writing all results to one place.
#
# Usage: eval/scripts/run_all.sh <corpus-name> [jobs]
#
# Corpus names: original | thinlto-prelink | before-ic1 | o2-final (see corpora.py).
#
# Every corpus is scored twice:
#   metrics/<tool>.txt            direct: its own gt/ (one instcombine)
#   metrics/<tool>-pipeline.txt   real scenario: original/gt-pipeline (the e2e
#                                 default<O2> run on the raw original IR)
# and gets REPORT.md/summary.json plus REPORT-pipeline.md/summary-pipeline.json.
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
NAME="${1:?usage: run_all.sh <corpus-name> [jobs]}"
JOBS="${2:-$(nproc)}"
cd "$REPO"

corpus() { uv run eval/scripts/corpora.py get "$NAME" "$1"; }
CORPUS="$(corpus corpus)"
INDEX="$(corpus index)"
RESULTS="$(corpus results)"
KIND="$(corpus kind)"
GT_RESULTS="$(corpus gt_pipeline_results)"
GT_DIR="$(corpus gt_pipeline_dir)"
LOGS="$RESULTS/logs"
mkdir -p "$LOGS" "$RESULTS/metrics"

run_eval() { uv run eval/scripts/run_eval.py "$@"; }
run_baseline() { uv run eval/scripts/run_baseline.py "$@"; }
step() { echo "[$(date '+%F %T')] $*"; }

if [[ "$KIND" == "original" ]]; then
    step "gt (direct: one instcombine)"
    run_eval gt --corpus "$CORPUS" --results "$RESULTS" --gt-dir gt -j "$JOBS" \
        >"$LOGS/gt.log" 2>&1
    step "gt-pipeline (real scenario: default<O2>, all firings)"
    run_eval gt --corpus "$CORPUS" --results "$RESULTS" --gt-dir gt-pipeline \
        --passes 'default<O2>' --firings all -j "$JOBS" \
        >"$LOGS/gt-pipeline.log" 2>&1
else
    step "gt (direct: one instcombine)"
    run_eval gt --corpus "$CORPUS" --results "$RESULTS" --gt-dir gt -j "$JOBS" \
        >"$LOGS/gt.log" 2>&1
fi

if [[ -f "$INDEX" ]]; then
    step "index (exists: $INDEX)"
else
    step "index"
    run_eval index --corpus "$CORPUS" --index "$INDEX" -j "$JOBS" \
        >"$LOGS/index.log" 2>&1
fi

step "check-index"
run_eval check-index --corpus "$CORPUS" --results "$RESULTS" --gt-dir gt \
    --index "$INDEX" -j "$JOBS" >"$LOGS/check-index.log" 2>&1 \
    || step "check-index found differences"

stats() { # <index> <log>
    for pattern in eval/patterns/*.mpir; do
        echo "== $(basename "$pattern" .mpir)"
        build/tools/metaphir-index stats "$pattern" "$1"
    done >"$2" 2>&1
}
step "stats"
stats "$INDEX" "$LOGS/stats.log"

step "metaphir-index timing"
run_baseline metaphir-index --corpus "$CORPUS" --index "$INDEX" \
    --results "$RESULTS" -j "$JOBS" --repeat 3 >"$LOGS/metaphir-index.log" 2>&1 \
    || step "metaphir-index reported failures"

step "metaphir-scan timing"
run_baseline metaphir-scan --corpus "$CORPUS" --results "$RESULTS" \
    -j "$JOBS" --repeat 3 >"$LOGS/metaphir-scan.log" 2>&1 \
    || step "metaphir-scan reported failures"

step "daggrep"
run_baseline daggrep --corpus "$CORPUS" --results "$RESULTS" \
    -j "$JOBS" --repeat 3 >"$LOGS/daggrep.log" 2>&1 \
    || step "daggrep reported failures"

step "ablation: index without value facts"
NOVF="${INDEX%.mpidx}-no-value-facts.mpidx"
if [[ ! -f "$NOVF" ]]; then
    /usr/bin/time -f "seconds=%e" build/tools/metaphir-index build -j "$JOBS" \
        --no-value-facts "$CORPUS" -o "$NOVF" >"$LOGS/index-no-value-facts.log" 2>&1
fi
stats "$NOVF" "$LOGS/stats-no-value-facts.log"
run_baseline metaphir-index --corpus "$CORPUS" --index "$NOVF" \
    --results "$RESULTS" --outdir "$RESULTS/ablation-no-value-facts" \
    -j "$JOBS" --repeat 3 >"$LOGS/ablation-no-value-facts.log" 2>&1 \
    || step "ablation-no-value-facts reported failures"

step "ablation: no constraint prefilter"
run_baseline metaphir-index --corpus "$CORPUS" --index "$INDEX" \
    --results "$RESULTS" --match-arg=--no-constraint-prefilter \
    --outdir "$RESULTS/ablation-no-constraint-prefilter" \
    -j "$JOBS" --repeat 3 >"$LOGS/ablation-no-constraint-prefilter.log" 2>&1 \
    || step "ablation-no-constraint-prefilter reported failures"

step "metrics (direct)"
for tool in metaphir-index metaphir-scan daggrep; do
    run_eval metrics --corpus "$CORPUS" --results "$RESULTS" --gt-dir gt \
        --tool "$tool" >"$RESULTS/metrics/$tool.txt" 2>&1
done

step "metrics (real scenario)"
for tool in metaphir-index metaphir-scan daggrep; do
    run_eval metrics --corpus "$CORPUS" --results "$RESULTS" \
        --gt "$GT_RESULTS" --gt-dir "$GT_DIR" --tool "$tool" \
        >"$RESULTS/metrics/$tool-pipeline.txt" 2>&1
done

step "report (direct)"
uv run eval/scripts/report.py "$RESULTS" --corpus "$CORPUS" --gt-dir gt \
    >"$LOGS/report.log" 2>&1

step "report (real scenario)"
uv run eval/scripts/report.py "$RESULTS" --corpus "$CORPUS" \
    --gt "$GT_RESULTS" --gt-dir "$GT_DIR" --suffix=-pipeline \
    >"$LOGS/report-pipeline.log" 2>&1

step "report (test suite)"
uv run eval/scripts/report.py "$RESULTS" --corpus "$CORPUS" --gt-dir gt \
    --source tests >"$LOGS/report-tests.log" 2>&1

step "done"
