#!/usr/bin/env python3

from __future__ import annotations

import argparse
import fcntl
import os
import re
import sys
import tempfile
from contextlib import contextmanager
from dataclasses import dataclass
from pathlib import Path
from typing import Iterator

ID_RE = re.compile(r"^[a-z][a-z0-9-]*/[a-z][a-z0-9-]*$")
TAG_RE = re.compile(r"^[a-z][a-z0-9-]*$")
LOCK_NAME = ".knowledge.lock"


class KnowledgeError(Exception):
    def __init__(self, messages: str | list[str]) -> None:
        if isinstance(messages, str):
            messages = [messages]
        self.messages = messages
        super().__init__("\n".join(messages))


@dataclass(frozen=True)
class Lesson:
    id: str
    tags: tuple[str, ...]
    body: str
    path: Path
    text: str


def validate_id(lesson_id: str) -> None:
    if not ID_RE.fullmatch(lesson_id):
        raise KnowledgeError(f"invalid lesson ID: {lesson_id}")


def normalize_tags(tags: list[str]) -> tuple[str, ...]:
    invalid = sorted({tag for tag in tags if not TAG_RE.fullmatch(tag)})
    if invalid:
        raise KnowledgeError(f"invalid tag: {', '.join(invalid)}")
    normalized = tuple(sorted(set(tags)))
    if not normalized:
        raise KnowledgeError("at least one tag is required")
    return normalized


def read_body(value: str) -> str:
    if value == "-":
        return sys.stdin.read()
    if value.startswith("@"):
        return Path(value[1:]).read_text(encoding="utf-8")
    return value


def validate_body(body: str) -> None:
    if not body.strip():
        raise KnowledgeError("lesson body is empty")


def render_lesson(lesson_id: str, tags: tuple[str, ...], body: str) -> str:
    tag_lines = "\n".join(f"  - {tag}" for tag in tags)
    return f"---\nid: {lesson_id}\ntags:\n{tag_lines}\n---\n{body.rstrip()}\n"


def id_from_path(root: Path, path: Path) -> str:
    relative = path.relative_to(root)
    if len(relative.parts) != 2 or relative.suffix != ".md":
        raise KnowledgeError(f"{path}: invalid lesson path")
    lesson_id = f"{relative.parts[0]}/{relative.stem}"
    try:
        validate_id(lesson_id)
    except KnowledgeError as error:
        raise KnowledgeError(f"{path}: {error}") from error
    return lesson_id


def lesson_path(root: Path, lesson_id: str) -> Path:
    validate_id(lesson_id)
    lesson_type, slug = lesson_id.split("/", 1)
    return root / lesson_type / f"{slug}.md"


def parse_lesson(path: Path, text: str, expected_id: str) -> Lesson:
    messages: list[str] = []
    if not text.startswith("---\n"):
        raise KnowledgeError(f"{path}: missing frontmatter")
    try:
        frontmatter, body = text[4:].split("\n---\n", 1)
    except ValueError as error:
        raise KnowledgeError(f"{path}: unterminated frontmatter") from error

    lines = frontmatter.splitlines()
    lesson_id = ""
    tags: list[str] = []
    if not lines or not lines[0].startswith("id: "):
        messages.append(f"{path}: expected id frontmatter field")
    else:
        lesson_id = lines[0][4:]
        try:
            validate_id(lesson_id)
        except KnowledgeError:
            messages.append(f"{path}: invalid frontmatter ID: {lesson_id}")
    if len(lines) < 2 or lines[1] != "tags:":
        messages.append(f"{path}: expected tags frontmatter field")
    else:
        for line in lines[2:]:
            if not line.startswith("  - ") or not line[4:]:
                messages.append(f"{path}: invalid tags frontmatter")
                continue
            tags.append(line[4:])
        if not tags:
            messages.append(f"{path}: at least one tag is required")
        invalid_tags = sorted({tag for tag in tags if not TAG_RE.fullmatch(tag)})
        for tag in invalid_tags:
            messages.append(f"{path}: invalid tag: {tag}")
        if len(tags) != len(set(tags)):
            messages.append(f"{path}: duplicate tag")
        if tags != sorted(tags):
            messages.append(f"{path}: tags are not sorted")
    if lesson_id and lesson_id != expected_id:
        messages.append(f"{path}: ID does not match path: {lesson_id}")
    if not body.strip():
        messages.append(f"{path}: empty body")
    if messages:
        raise KnowledgeError(messages)
    return Lesson(
        id=lesson_id,
        tags=tuple(tags),
        body=body,
        path=path,
        text=text,
    )


def load_lesson(root: Path, lesson_id: str) -> Lesson:
    path = lesson_path(root, lesson_id)
    if path.is_symlink():
        raise KnowledgeError(f"{path}: symbolic link is not allowed")
    if not path.is_file():
        raise KnowledgeError(f"lesson does not exist: {lesson_id}")
    text = path.read_text(encoding="utf-8")
    return parse_lesson(path, text, lesson_id)


def collect_lessons(root: Path) -> list[Lesson]:
    if not root.exists():
        return []
    if not root.is_dir():
        raise KnowledgeError(f"knowledge directory is not a directory: {root}")

    messages: list[str] = []
    lessons: list[Lesson] = []
    for path in sorted(root.rglob("*")):
        if path.is_symlink():
            messages.append(f"{path}: symbolic link is not allowed")
            continue
        if path.is_dir():
            continue
        if path == root / LOCK_NAME:
            continue
        if path.suffix != ".md":
            messages.append(f"{path}: unexpected file")
            continue
        try:
            lesson_id = id_from_path(root, path)
            text = path.read_text(encoding="utf-8")
            lessons.append(parse_lesson(path, text, lesson_id))
        except (KnowledgeError, UnicodeError, OSError) as error:
            if isinstance(error, KnowledgeError):
                messages.extend(error.messages)
            else:
                messages.append(f"{path}: {error}")
    if messages:
        raise KnowledgeError(messages)
    return sorted(lessons, key=lambda lesson: lesson.id)


@contextmanager
def store_lock(root: Path) -> Iterator[None]:
    root.mkdir(parents=True, exist_ok=True)
    with (root / LOCK_NAME).open("a", encoding="utf-8") as lock:
        fcntl.flock(lock.fileno(), fcntl.LOCK_EX)
        try:
            yield
        finally:
            fcntl.flock(lock.fileno(), fcntl.LOCK_UN)


def write_atomic(path: Path, text: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    descriptor, temporary_name = tempfile.mkstemp(
        prefix=f".{path.name}.", suffix=".tmp", dir=path.parent, text=True
    )
    temporary = Path(temporary_name)
    try:
        with os.fdopen(descriptor, "w", encoding="utf-8") as handle:
            handle.write(text)
            handle.flush()
            os.fsync(handle.fileno())
        os.replace(temporary, path)
    except BaseException:
        temporary.unlink(missing_ok=True)
        raise


def create_lesson(
    root: Path, lesson_id: str, tags: list[str], body_value: str
) -> None:
    validate_id(lesson_id)
    normalized_tags = normalize_tags(tags)
    body = read_body(body_value)
    validate_body(body)
    path = lesson_path(root, lesson_id)
    with store_lock(root):
        if path.exists() or path.is_symlink():
            raise KnowledgeError(f"lesson already exists: {lesson_id}")
        write_atomic(path, render_lesson(lesson_id, normalized_tags, body))


def update_lesson(
    root: Path,
    lesson_id: str,
    tags: list[str] | None,
    body_value: str | None,
) -> None:
    if tags is None and body_value is None:
        raise KnowledgeError("update requires --tag or --body")
    normalized_tags = normalize_tags(tags) if tags is not None else None
    body = read_body(body_value) if body_value is not None else None
    if body is not None:
        validate_body(body)
    with store_lock(root):
        lesson = load_lesson(root, lesson_id)
        write_atomic(
            lesson.path,
            render_lesson(
                lesson.id,
                normalized_tags if normalized_tags is not None else lesson.tags,
                body if body is not None else lesson.body,
            ),
        )


def delete_lesson(root: Path, lesson_id: str) -> None:
    with store_lock(root):
        lesson = load_lesson(root, lesson_id)
        lesson.path.unlink()
        try:
            lesson.path.parent.rmdir()
        except OSError:
            pass


def resolve_directory(argument: Path | None) -> Path:
    if argument is not None:
        return argument.expanduser()
    configured = os.environ.get("AGENTS_KNOWLEDGE_DIR")
    if configured:
        return Path(configured).expanduser()
    xdg_data = os.environ.get("XDG_DATA_HOME")
    if xdg_data:
        return Path(xdg_data).expanduser() / "agents" / "knowledge"
    return Path.home() / ".local" / "share" / "agents" / "knowledge"


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        prog="knowledge",
        description="Manage durable local agent lessons.",
        epilog=(
            "Directory: --directory, AGENTS_KNOWLEDGE_DIR, "
            "$XDG_DATA_HOME/agents/knowledge, or ~/.local/share/agents/knowledge."
        ),
    )
    parser.add_argument("--directory", type=Path)
    commands = parser.add_subparsers(dest="command", required=True)

    create = commands.add_parser("create", help="Create a lesson")
    create.add_argument("id")
    create.add_argument("--tag", action="append", required=True, dest="tags")
    create.add_argument("--body", required=True)

    read = commands.add_parser("read", help="Read a lesson")
    read.add_argument("id")

    update = commands.add_parser("update", help="Update a lesson")
    update.add_argument("id")
    update.add_argument("--tag", action="append", dest="tags")
    update.add_argument("--body")

    delete = commands.add_parser("delete", help="Delete a lesson")
    delete.add_argument("id")

    commands.add_parser("list", help="List lesson IDs")

    search = commands.add_parser("search", help="Search lesson IDs, tags, and bodies")
    search.add_argument("query")

    commands.add_parser("check", help="Validate the lesson store")
    return parser


def run(args: argparse.Namespace) -> int:
    root = resolve_directory(args.directory)
    if args.command == "create":
        create_lesson(root, args.id, args.tags, args.body)
        print(args.id)
    elif args.command == "read":
        print(load_lesson(root, args.id).text, end="")
    elif args.command == "update":
        update_lesson(root, args.id, args.tags, args.body)
        print(args.id)
    elif args.command == "delete":
        delete_lesson(root, args.id)
        print(args.id)
    elif args.command == "list":
        for lesson in collect_lessons(root):
            print(lesson.id)
    elif args.command == "search":
        if not args.query:
            raise KnowledgeError("search query is empty")
        query = args.query.casefold()
        for lesson in collect_lessons(root):
            searchable = "\n".join((lesson.id, *lesson.tags, lesson.body)).casefold()
            if query in searchable:
                print(lesson.id)
    elif args.command == "check":
        collect_lessons(root)
    else:
        raise KnowledgeError(f"unknown command: {args.command}")
    return 0


def main(argv: list[str] | None = None) -> int:
    try:
        args = build_parser().parse_args(argv)
        return run(args)
    except (KnowledgeError, OSError, UnicodeError) as error:
        print(f"knowledge: {error}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
