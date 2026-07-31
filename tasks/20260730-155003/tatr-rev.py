#!/usr/bin/env python3
"""Prove the root `tatr` flake input is the published tatr default-branch tip.

Two things this must not get wrong:

- `flake.lock` holds TWO tatr nodes. `scufris` pulls its own, older one, so
  looking the node up by the name "tatr" reads the wrong revision. The root's
  input map is the only correct way in.
- "published" means the revision `github:alexjercan/tatr` would resolve to,
  which is the remote default branch. Compare against the local checkout's
  `origin/HEAD`, not its working branch.

Also asserts the locked revision actually CONTAINS every prerequisite tatr
Story of Epic 20260730-153122, so a tip that predates them fails here rather
than at the Epic's Finish.

The tatr checkout defaults to ~/personal/tatr; override with TATR_REPO.
"""

import json
import os
import pathlib
import subprocess
import sys

PREREQUISITE_STORIES = [
    "20260730-153325",  # typed v2 workflow schema and history migration
    "20260730-154657",  # transactional flow lifecycle commands and guards
    "20260730-154740",  # Epic graph, frontier, claims and phase context
    "20260730-154745",  # flow artifact schema scaffolding and validation
    "20260730-154756",  # user disposition required for lesson promotions
]

REPO = pathlib.Path(__file__).resolve().parents[2]
TATR = pathlib.Path(
    os.environ.get("TATR_REPO", pathlib.Path.home() / "personal" / "tatr")
)


def git(*args):
    return subprocess.run(
        ["git", "-C", str(TATR), *args],
        check=True,
        capture_output=True,
        text=True,
    ).stdout.strip()


def fail(message):
    print("FAIL: " + message)
    sys.exit(1)


def locked_rev():
    lock = json.loads((REPO / "flake.lock").read_text())
    nodes = lock["nodes"]
    root_inputs = nodes[lock["root"]]["inputs"]
    if "tatr" not in root_inputs:
        fail("flake.lock root has no `tatr` input")
    node = root_inputs["tatr"]
    if isinstance(node, list):  # a `follows` chain, not a direct input
        fail("root `tatr` input follows " + "/".join(node) + " instead of pinning")
    return node, nodes[node]["locked"]["rev"]


def published_rev():
    """The revision `github:alexjercan/tatr` resolves to, per the local clone.

    The fetch is BEST EFFORT: no check in this repository may require the
    network (AGENTS.md), so an unreachable remote degrades to reading the
    remote-tracking ref as it stands and says so, rather than dying. Everything
    after it is local and its failure is a real failure.
    """
    if not (TATR / ".git").exists():
        fail("no tatr checkout at " + str(TATR) + " (set TATR_REPO)")
    try:
        git("fetch", "--quiet", "origin")
    except subprocess.CalledProcessError:
        print("WARNING: could not fetch " + str(TATR) + "; origin refs may be stale")
    try:
        head = git("symbolic-ref", "--quiet", "refs/remotes/origin/HEAD")
    except subprocess.CalledProcessError:
        fail(
            "no refs/remotes/origin/HEAD in "
            + str(TATR)
            + "; set it with `git remote set-head origin --auto`"
        )
    try:
        return head, git("rev-parse", head)
    except subprocess.CalledProcessError:
        fail(head + " does not resolve in " + str(TATR))


def story_status(rev, story):
    path = "tasks/" + story + "/TASK.md"
    try:
        body = git("show", rev + ":" + path)
    except subprocess.CalledProcessError:
        return None
    for line in body.splitlines():
        if line.startswith("- STATUS:"):
            return line.split(":", 1)[1].strip()
    return None


def main():
    node, locked = locked_rev()
    ref, published = published_rev()

    print("root tatr node: " + node)
    print("locked rev:     " + locked)
    print("published rev:  " + published + "  (" + ref + ")")

    if locked != published:
        fail("flake.lock root `tatr` is not the published tip")

    for story in PREREQUISITE_STORIES:
        status = story_status(locked, story)
        if status != "CLOSED":
            fail(
                "prerequisite Story "
                + story
                + " is "
                + (status or "absent")
                + " at the locked revision, not CLOSED"
            )
        print("prerequisite " + story + ": CLOSED")

    print("OK")


if __name__ == "__main__":
    main()
