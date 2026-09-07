#!/usr/bin/env python3
"""Promote the exact podinfo image tag between adjacent GitOps environments."""

from __future__ import annotations

import argparse
import re
from pathlib import Path

ROOT_DEFAULT = Path("argocd-gitops-platform-reference")
ALLOWED_PROMOTIONS = {("dev", "staging"), ("staging", "prod")}
TAG_PATTERN = re.compile(r"^[0-9]+\.[0-9]+\.[0-9]+(?:[-+][0-9A-Za-z.-]+)?$")
NEW_TAG_PATTERN = re.compile(r"^(\s*newTag:\s*)(\S+)(\s*)$", re.MULTILINE)


def overlay_file(root: Path, environment: str) -> Path:
    return root / "workloads" / "podinfo" / "overlays" / environment / "kustomization.yaml"


def read_tag(path: Path) -> str:
    content = path.read_text(encoding="utf-8")
    matches = NEW_TAG_PATTERN.findall(content)
    if len(matches) != 1:
        raise ValueError(f"{path}: expected exactly one newTag entry, found {len(matches)}")
    return matches[0][1]


def write_tag(path: Path, tag: str) -> None:
    content = path.read_text(encoding="utf-8")
    updated, count = NEW_TAG_PATTERN.subn(lambda match: f"{match.group(1)}{tag}{match.group(3)}", content)
    if count != 1:
        raise ValueError(f"{path}: expected exactly one newTag entry, found {count}")
    path.write_text(updated, encoding="utf-8")


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("source", choices=("dev", "staging"))
    parser.add_argument("target", choices=("staging", "prod"))
    parser.add_argument("--root", type=Path, default=ROOT_DEFAULT)
    parser.add_argument("--check", action="store_true", help="validate the promotion without changing files")
    args = parser.parse_args()

    if (args.source, args.target) not in ALLOWED_PROMOTIONS:
        parser.error("only dev -> staging and staging -> prod promotions are allowed")

    source_path = overlay_file(args.root, args.source)
    target_path = overlay_file(args.root, args.target)
    source_tag = read_tag(source_path)
    target_tag = read_tag(target_path)

    if not TAG_PATTERN.fullmatch(source_tag):
        raise SystemExit(f"source tag {source_tag!r} is not an explicit versioned release tag")

    if args.check:
        print(f"Promotion valid: {args.source} {source_tag} -> {args.target} (currently {target_tag})")
        return 0

    if source_tag == target_tag:
        print(f"No change: {args.target} already references {source_tag}")
        return 0

    write_tag(target_path, source_tag)
    print(f"Promoted podinfo {source_tag}: {args.source} -> {args.target}")
    print(f"Review and commit only: {target_path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
