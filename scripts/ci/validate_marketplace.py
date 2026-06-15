#!/usr/bin/env python3
"""Validate the plugin marketplace structure.

Checks (each a hard failure):
  1. .claude-plugin/marketplace.json is valid JSON with the expected shape.
  2. Every plugin's `source` directory exists.
  3. Every skill listed in a plugin's `skills[]` resolves to a directory
     containing a SKILL.md (catches a renamed source path that forgot to
     update a skill entry).
  4. Every SKILL.md (under any plugin) has YAML frontmatter with non-empty
     `name` and `description`.
  5. Every committed symlink under .claude/skills/ resolves to an existing
     directory (catches dev symlinks left dangling after a plugin rename).
  6. No orphan skills: every plugins/*/skills/*/SKILL.md is registered in
     some plugin's skills[].

Pure stdlib; no third-party deps. Run from the repo root.
"""

from __future__ import annotations

import json
import os
import re
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parents[2]
MARKETPLACE = REPO / ".claude-plugin" / "marketplace.json"

errors: list[str] = []


def err(msg: str) -> None:
    errors.append(msg)


def load_marketplace() -> dict | None:
    if not MARKETPLACE.is_file():
        err(f"{MARKETPLACE.relative_to(REPO)} not found")
        return None
    try:
        return json.loads(MARKETPLACE.read_text())
    except json.JSONDecodeError as e:
        err(f"marketplace.json is not valid JSON: {e}")
        return None


def frontmatter(skill_md: Path) -> dict[str, str]:
    """Parse the leading YAML frontmatter block (name/description only)."""
    try:
        text = skill_md.read_text(encoding="utf-8", errors="replace")
    except OSError as e:
        # Unreadable SKILL.md (missing, permissions, ...) -> report and treat as
        # empty frontmatter, so the name/description checks flag it loudly
        # instead of crashing the whole run.
        err(f"{skill_md.relative_to(REPO)}: could not read SKILL.md ({e})")
        return {}
    m = re.match(r"^---\n(.*?)\n---\n", text, re.DOTALL)
    if not m:
        return {}
    fields: dict[str, str] = {}
    for key in ("name", "description"):
        km = re.search(rf"^{key}:\s*(.+?)\s*$", m.group(1), re.MULTILINE)
        if km:
            fields[key] = km.group(1)
    return fields


def check_marketplace(data: dict) -> set[Path]:
    """Validate plugins + skills. Returns the set of registered SKILL.md paths."""
    registered: set[Path] = set()
    if "plugins" not in data or not isinstance(data["plugins"], list):
        err("marketplace.json missing a `plugins` array")
        return registered

    seen_names: set[str] = set()
    for p in data["plugins"]:
        name = p.get("name", "<unnamed>")
        if name in seen_names:
            err(f"duplicate plugin name: {name}")
        seen_names.add(name)

        source = p.get("source")
        if not source:
            err(f"plugin {name}: missing `source`")
            continue
        src_dir = (REPO / source.lstrip("./")).resolve()
        if not src_dir.is_dir():
            err(f"plugin {name}: source dir does not exist: {source}")
            continue

        for skill_ref in p.get("skills", []):
            skill_dir = (src_dir / skill_ref.lstrip("./")).resolve()
            skill_md = skill_dir / "SKILL.md"
            if not skill_dir.is_dir():
                err(f"plugin {name}: skill dir missing: {source}/{skill_ref}")
            elif not skill_md.is_file():
                err(f"plugin {name}: no SKILL.md in {source}/{skill_ref}")
            else:
                registered.add(skill_md.resolve())
    return registered


def check_all_skill_frontmatter() -> set[Path]:
    """Validate frontmatter of every SKILL.md; return the set found on disk."""
    found: set[Path] = set()
    plugins_dir = REPO / "plugins"
    if not plugins_dir.is_dir():
        err("plugins/ directory not found")
        return found
    for skill_md in plugins_dir.rglob("SKILL.md"):
        found.add(skill_md.resolve())
        fm = frontmatter(skill_md)
        rel = skill_md.relative_to(REPO)
        if not fm.get("name"):
            err(f"{rel}: frontmatter missing `name`")
        if not fm.get("description"):
            err(f"{rel}: frontmatter missing `description`")
    return found


def check_dev_symlinks() -> None:
    """Every .claude/skills/* symlink must resolve to an existing directory."""
    skills_dir = REPO / ".claude" / "skills"
    if not skills_dir.is_dir():
        return  # optional; absent is fine
    for entry in sorted(skills_dir.iterdir()):
        if not entry.is_symlink():
            continue
        target = os.readlink(entry)
        resolved = (entry.parent / target).resolve()
        # A tracked dev symlink should point at an in-repo skill dir. Flag any
        # that escape the repo (supply-chain hygiene) before the existence check.
        try:
            resolved.relative_to(REPO)
        except ValueError:
            err(
                f".claude/skills/{entry.name}: symlink points outside the repo "
                f"-> {target} (resolves to {resolved})"
            )
            continue
        if not resolved.is_dir():
            err(
                f".claude/skills/{entry.name}: dangling symlink -> {target} "
                f"(resolves to {resolved}, which does not exist)"
            )


def check_orphans(registered: set[Path], found: set[Path]) -> None:
    for skill_md in sorted(found - registered):
        err(
            f"orphan skill not registered in any plugin's skills[]: "
            f"{skill_md.relative_to(REPO)}"
        )


def main() -> int:
    data = load_marketplace()
    registered: set[Path] = set()
    if data is not None:
        registered = check_marketplace(data)
    found = check_all_skill_frontmatter()
    check_dev_symlinks()
    if data is not None:
        check_orphans(registered, found)

    if errors:
        print(f"✗ marketplace validation failed ({len(errors)} issue(s)):\n")
        for e in errors:
            print(f"  - {e}")
        return 1
    print("✓ marketplace validation passed")
    plugins = data.get("plugins") if data is not None else None
    plugin_count = len(plugins) if isinstance(plugins, list) else 0
    print(f"  plugins: {plugin_count}")
    print(f"  skills:  {len(found)}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
