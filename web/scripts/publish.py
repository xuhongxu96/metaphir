#!/usr/bin/env python3
"""Uploads a corpus published by `metaphir-index publish` to a Hugging Face
bucket, where the site reads it.

The files go under builds/<build>/, the build named in manifest.json, which
is uploaded last: a build is complete once its manifest is there. Uploading
needs the `hf` CLI, logged in (`hf auth login`) with write access to the
bucket, which is created (public) if needed.

  web/scripts/publish.py <published directory> <owner>/<bucket> \\
      [--config web/public/config.json]

With --config, the site's config.json is pointed at the build.
"""

from __future__ import annotations

import argparse
import json
import subprocess
import sys
from pathlib import Path


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__.split("\n\n")[0])
    parser.add_argument("published", type=Path, help="the published directory")
    parser.add_argument("bucket", help="the bucket, as <owner>/<bucket>")
    parser.add_argument(
        "--config", type=Path, help="the site's config.json to point at the build"
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
    if args.config:
        args.config.write_text(json.dumps({"data": data}, indent=2) + "\n")
        print(f"pointed {args.config} at it")
    return 0


if __name__ == "__main__":
    sys.exit(main())
