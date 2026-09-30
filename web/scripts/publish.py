#!/usr/bin/env python3
"""Uploads a corpus published by `metaphir-index publish` to a Hugging Face
bucket, where the site reads it.

The files go under builds/<build>/, the build named in manifest.json, which
is uploaded last: a build is complete once its manifest is there. Uploading
needs the `hf` CLI, logged in (`hf auth login`) with write access to the
bucket, which is created (public) if needed.

  web/scripts/publish.py <published directory> [<owner>/<bucket>] \\
      [--keep <builds>] [--config <config.json> | --no-config]

The bucket is the site's, xuhongxu96/llvm-opt-benchmark-index, unless
another is given. It keeps the 3 (--keep) builds last published, this one
among them: older ones are removed. Builds with no manifest, whose upload
failed or goes on, are left, and listed.

The site's config.json (web/public/config.json, unless another is given) is
pointed at the build, but with --no-config.
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
    listing: list[dict], keep: int, current: str
) -> tuple[list[str], list[str]]:
    """The builds of a bucket's listing (`hf buckets ls -R --json`) to remove:
    the complete ones but the keep last published, by when their manifests
    were uploaded, current among them whatever its date. And the builds with
    no manifest, whose upload failed or goes on."""
    builds: set[str] = set()
    published: dict[str, datetime] = {}
    for item in listing:
        parts = item["path"].split("/")
        if item["type"] != "file" or len(parts) != 3 or parts[0] != "builds":
            continue
        builds.add(parts[1])
        if parts[2] == "manifest.json":
            published[parts[1]] = datetime.fromisoformat(item["uploaded_at"])
    last = sorted(published, key=lambda b: (b == current, published[b]), reverse=True)
    return sorted(last[keep:]), sorted(builds - published.keys())


def prune(bucket: str, keep: int, current: str) -> None:
    """Removes the builds of bucket but the keep last published."""
    listed = subprocess.run(
        ["hf", "buckets", "ls", bucket, "-R", "--json"],
        check=True, capture_output=True, text=True,
    ).stdout
    # An empty bucket is listed as "(empty)".
    listing = json.loads(listed) if listed.lstrip().startswith("[") else []
    stale, incomplete = stale_builds(listing, keep, current)
    for build in stale:
        print(f"removing build {build}")
        subprocess.run(
            [
                "hf", "buckets", "rm", f"{bucket}/builds/{build}/",
                "--recursive", "--yes",
            ],
            check=True,
        )
    for build in incomplete:
        print(f"build {build} has no manifest: its upload failed or goes on")


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__.split("\n\n")[0])
    parser.add_argument("published", type=Path, help="the published directory")
    parser.add_argument(
        "bucket", nargs="?", default=BUCKET,
        help=f"the bucket, as <owner>/<bucket> ({BUCKET} by default)",
    )
    parser.add_argument(
        "--keep", type=int, default=KEEP,
        help=f"how many builds the bucket keeps, this one among them ({KEEP})",
    )
    config = parser.add_mutually_exclusive_group()
    config.add_argument(
        "--config", type=Path, default=CONFIG,
        help="the site's config.json to point at the build (web/public/config.json)",
    )
    config.add_argument(
        "--no-config", dest="config", action="store_const", const=None,
        help="leave the site's config.json as it is",
    )
    args = parser.parse_args()

    manifest = json.loads((args.published / "manifest.json").read_text())
    build = manifest["build"]
    for name, size in manifest["files"].items():
        actual = (args.published / name).stat().st_size
        if actual != size:
            sys.exit(f"{name}: {actual} bytes, the manifest says {size}")

    destination = f"hf://buckets/{args.bucket}/builds/{build}"
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

    data = f"https://huggingface.co/buckets/{args.bucket}/resolve/builds/{build}"
    print(f"published build {build}: {data}")
    prune(args.bucket, args.keep, build)
    if args.config:
        args.config.write_text(json.dumps({"data": data}, indent=2) + "\n")
        print(f"pointed {args.config} at it")
    return 0


if __name__ == "__main__":
    sys.exit(main())
