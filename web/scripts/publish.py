#!/usr/bin/env python3
"""Uploads a corpus published by `metaphir-index publish` to a Hugging Face
bucket, where the site reads it.

The files go under builds/<corpus>/<build>/, the build named in manifest.json,
which is uploaded last: a build is complete once its manifest is there.
Uploading needs the `hf` CLI, logged in (`hf auth login`) with write access to
the bucket, which is created (public) if needed.

  web/scripts/publish.py <published directory> --corpus <id> \\
      [<owner>/<bucket>] [--label <label>] [--description <text>] [--default] \\
      [--keep <builds>] [--config <config.json> | --no-config]

Each corpus keeps the 3 (--keep) builds last published, this one among them;
other corpora's builds are never touched. The site's config.json is upserted:
the matching corpus entry's data (and optional label/description) is replaced,
the other entries and the default are preserved. --default makes this corpus
the default.
"""

from __future__ import annotations

import argparse
import json
import subprocess
import sys
from datetime import datetime
from pathlib import Path

BUCKET = "xuhongxu96/llvm-opt-benchmark-index"
CONFIG = Path(__file__).resolve().parent.parent / "public" / "config.json"
KEEP = 3


def stale_builds(
    listing: list[dict], keep: int, current: str, corpus: str
) -> tuple[list[str], list[str]]:
    """This corpus's builds to remove: the complete ones but the keep last
    published (current among them whatever its date), and the builds with no
    manifest, whose upload failed or goes on. Other corpora are ignored."""
    builds: set[str] = set()
    published: dict[str, datetime] = {}
    for item in listing:
        parts = item["path"].split("/")
        if (
            item["type"] != "file"
            or len(parts) != 4
            or parts[0] != "builds"
            or parts[1] != corpus
        ):
            continue
        build = parts[2]
        builds.add(build)
        if parts[3] == "manifest.json":
            published[build] = datetime.fromisoformat(item["uploaded_at"])
    last = sorted(published, key=lambda b: (b == current, published[b]), reverse=True)
    return sorted(last[keep:]), sorted(builds - published.keys())


def prune(bucket: str, keep: int, current: str, corpus: str) -> None:
    """Removes this corpus's builds but the keep last published."""
    listed = subprocess.run(
        ["hf", "buckets", "ls", bucket, "-R", "--json"],
        check=True,
        capture_output=True,
        text=True,
    ).stdout
    # An empty bucket is listed as "(empty)".
    listing = json.loads(listed) if listed.lstrip().startswith("[") else []
    stale, incomplete = stale_builds(listing, keep, current, corpus)
    for build in stale:
        print(f"removing build {corpus}/{build}")
        subprocess.run(
            [
                "hf", "buckets", "rm", f"{bucket}/builds/{corpus}/{build}/",
                "--recursive", "--yes",
            ],
            check=True,
        )
    for build in incomplete:
        print(
            f"build {corpus}/{build} has no manifest: its upload failed or goes on"
        )


def upsert_config(
    path: Path,
    corpus: str,
    data: str,
    label: str | None,
    description: str | None,
    make_default: bool,
) -> None:
    """Adds or updates this corpus in the site's config, preserving the rest."""
    config = json.loads(path.read_text()) if path.is_file() else {}
    corpora = config.get("corpora")
    if not isinstance(corpora, list):
        corpora = []
    entry = next(
        (e for e in corpora if isinstance(e, dict) and e.get("id") == corpus),
        None,
    )
    if entry is None:
        entry = {"id": corpus}
        corpora.append(entry)
    entry["data"] = data
    entry.setdefault("label", corpus)
    if label is not None:
        entry["label"] = label
    if description is not None:
        entry["description"] = description
    # The legacy single-corpus key is superseded by the list.
    config.pop("data", None)
    config["corpora"] = corpora
    if make_default:
        config["default"] = corpus
    ids = [e.get("id") for e in corpora if isinstance(e, dict)]
    if config.get("default") not in ids:
        config["default"] = ids[0] if ids else corpus
    path.write_text(json.dumps(config, indent=2) + "\n")


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__.split("\n\n")[0])
    parser.add_argument("published", type=Path, help="the published directory")
    parser.add_argument(
        "--corpus", required=True, help="the corpus id, e.g. o2-final"
    )
    parser.add_argument(
        "bucket", nargs="?", default=BUCKET,
        help=f"the bucket, as <owner>/<bucket> ({BUCKET} by default)",
    )
    parser.add_argument("--label", help="the display label in config.json")
    parser.add_argument("--description", help="the description in config.json")
    parser.add_argument(
        "--default",
        action="store_true",
        help="make this corpus the site's default",
    )
    parser.add_argument(
        "--keep", type=int, default=KEEP,
        help=f"how many builds of this corpus the bucket keeps ({KEEP} by default)",
    )
    config = parser.add_mutually_exclusive_group()
    config.add_argument(
        "--config", type=Path, default=CONFIG,
        help="the site's config.json to update (web/public/config.json)",
    )
    config.add_argument(
        "--no-config", dest="config", action="store_const", const=None,
        help="leave the site's config.json as it is",
    )
    args = parser.parse_args()

    if args.keep < 1:
        parser.error("--keep must be at least 1")
    manifest = json.loads((args.published / "manifest.json").read_text())
    build = manifest["build"]
    for name, size in manifest["files"].items():
        actual = (args.published / name).stat().st_size
        if actual != size:
            sys.exit(f"{name}: {actual} bytes, the manifest says {size}")

    destination = f"hf://buckets/{args.bucket}/builds/{args.corpus}/{build}"
    subprocess.run(["hf", "buckets", "create", args.bucket, "--exist-ok"], check=True)
    subprocess.run(
        [
            "hf", "buckets", "sync", str(args.published), destination,
            "--exclude", "manifest.json",
        ],
        check=True,
    )
    subprocess.run(
        [
            "hf", "buckets", "cp", str(args.published / "manifest.json"),
            f"{destination}/manifest.json",
        ],
        check=True,
    )

    data = (
        f"https://huggingface.co/buckets/{args.bucket}/resolve/"
        f"builds/{args.corpus}/{build}"
    )
    print(f"published build {args.corpus}/{build}: {data}")
    prune(args.bucket, args.keep, build, args.corpus)
    if args.config:
        upsert_config(
            args.config,
            args.corpus,
            data,
            args.label,
            args.description,
            args.default,
        )
        print(f"updated {args.config}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
