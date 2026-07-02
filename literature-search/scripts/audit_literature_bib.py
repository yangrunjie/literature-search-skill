#!/usr/bin/env python3
"""审计 Literature Search Skill 生成的 BibTeX 数据库。"""

from __future__ import annotations

import argparse
import json
import math
import re
import sys
from collections import Counter
from dataclasses import asdict, dataclass
from datetime import date
from pathlib import Path


REQUIRED_FIELDS = (
    "author",
    "title",
    "year",
    "doi",
    "url",
    "abstract",
    "language",
    "abstractsource",
    "abstracttype",
)
DOI_PATTERN = re.compile(r"^10\.\d{4,9}/\S+$", re.IGNORECASE)


@dataclass(frozen=True)
class BibEntry:
    entry_type: str
    key: str
    fields: dict[str, str]


@dataclass(frozen=True)
class AuditResult:
    valid: bool
    entry_count: int
    chinese_count: int
    chinese_required: int
    recent_count: int
    recent_required: int
    issues: list[str]


def find_matching_delimiter(text: str, open_pos: int) -> int:
    """查找一个 BibTeX 条目的顶层结束括号。"""
    opener = text[open_pos]
    closer = "}" if opener == "{" else ")"
    depth = 0
    quoted = False
    escaped = False

    for index in range(open_pos, len(text)):
        char = text[index]
        if escaped:
            escaped = False
            continue
        if char == "\\":
            escaped = True
        elif char == '"':
            quoted = not quoted
        elif not quoted and char == opener:
            depth += 1
        elif not quoted and char == closer:
            depth -= 1
            if depth == 0:
                return index

    raise ValueError(f"BibTeX 条目存在未配对括号，位置 {open_pos}")


def split_top_level(text: str) -> list[str]:
    """仅按顶层逗号切分，保留摘要中的逗号和嵌套花括号。"""
    parts: list[str] = []
    start = 0
    depth = 0
    quoted = False
    escaped = False

    for index, char in enumerate(text):
        if escaped:
            escaped = False
            continue
        if char == "\\":
            escaped = True
        elif char == '"':
            quoted = not quoted
        elif not quoted and char in "{(":
            depth += 1
        elif not quoted and char in "})":
            depth -= 1
        elif not quoted and depth == 0 and char == ",":
            token = text[start:index].strip()
            if token:
                parts.append(token)
            start = index + 1

    token = text[start:].strip()
    if token:
        parts.append(token)
    return parts


def parse_entries(text: str) -> list[BibEntry]:
    """解析常见 BibTeX 条目，不依赖第三方包。"""
    entries: list[BibEntry] = []
    position = 0

    while True:
        at_pos = text.find("@", position)
        if at_pos < 0:
            break
        opener_match = re.search(r"[({]", text[at_pos + 1 :])
        if not opener_match:
            break
        open_pos = at_pos + 1 + opener_match.start()
        entry_type = text[at_pos + 1 : open_pos].strip().lower()
        close_pos = find_matching_delimiter(text, open_pos)
        body = text[open_pos + 1 : close_pos]
        parts = split_top_level(body)
        position = close_pos + 1

        if not parts or entry_type in {"comment", "preamble", "string"}:
            continue

        key = parts[0].strip()
        fields: dict[str, str] = {}
        for token in parts[1:]:
            if "=" not in token:
                continue
            name, value = token.split("=", 1)
            normalized_name = name.strip().lower()
            if re.fullmatch(r"[A-Za-z][A-Za-z0-9_-]*", normalized_name):
                fields[normalized_name] = value.strip()

        entries.append(BibEntry(entry_type=entry_type, key=key, fields=fields))

    return entries


def strip_value(value: str) -> str:
    """移除字段最外层成对的花括号或双引号。"""
    value = value.strip()
    while len(value) >= 2:
        if (value[0], value[-1]) in {("{", "}"), ('"', '"')}:
            value = value[1:-1].strip()
        else:
            break
    return value


def normalize_doi(value: str) -> str:
    """将 DOI 统一为小写裸 DOI。"""
    doi = strip_value(value).strip().lower()
    doi = re.sub(r"^https?://(?:dx\.)?doi\.org/", "", doi)
    doi = re.sub(r"^doi:\s*", "", doi)
    doi = re.sub(r"[\s.,;]+$", "", doi)
    return doi if DOI_PATTERN.fullmatch(doi) else ""


def is_chinese_language(value: str) -> bool:
    language = strip_value(value).lower()
    return (
        language.startswith("zh")
        or "chinese" in language
        or "中文" in language
        or "汉语" in language
    )


def duplicate_issues(values: list[str], label: str) -> list[str]:
    counts = Counter(value for value in values if value)
    return [
        f"{label}重复：{value}（{count} 次）"
        for value, count in sorted(counts.items())
        if count > 1
    ]


def audit_entries(
    entries: list[BibEntry],
    target_count: int,
    chinese_ratio: float,
    recent_ratio: float,
) -> AuditResult:
    issues: list[str] = []
    keys: list[str] = []
    dois: list[str] = []
    chinese_count = 0
    recent_count = 0
    current_year = date.today().year

    for entry in entries:
        keys.append(entry.key.strip().lower())
        for field_name in REQUIRED_FIELDS:
            if not strip_value(entry.fields.get(field_name, "")):
                issues.append(f"[{entry.key}] 缺少必填字段：{field_name}")

        doi = normalize_doi(entry.fields.get("doi", ""))
        dois.append(doi)
        if not doi:
            issues.append(f"[{entry.key}] DOI 为空或格式无效")

        if is_chinese_language(entry.fields.get("language", "")):
            chinese_count += 1

        year_match = re.search(r"\d{4}", strip_value(entry.fields.get("year", "")))
        if not year_match:
            issues.append(f"[{entry.key}] 年份无法解析")
        else:
            publication_year = int(year_match.group())
            if current_year - 4 <= publication_year <= current_year:
                recent_count += 1

        if entry.entry_type == "article":
            missing_publication_data = any(
                not strip_value(entry.fields.get(field, ""))
                for field in ("volume", "number", "pages")
            )
            note = strip_value(entry.fields.get("note", "")).lower()
            has_explanation = any(
                marker in note
                for marker in ("online first", "not assigned", "未分配")
            )
            if missing_publication_data and not has_explanation:
                issues.append(
                    f"[{entry.key}] 期刊论文缺少卷/期/页码且无未分配说明"
                )

    issues.extend(duplicate_issues(keys, "引用键"))
    issues.extend(duplicate_issues(dois, "DOI"))

    entry_count = len(entries)
    chinese_required = math.ceil(chinese_ratio * entry_count)
    recent_required = math.ceil(recent_ratio * entry_count)

    if entry_count < target_count:
        issues.append(f"目标要求至少 {target_count} 篇，当前为 {entry_count} 篇")
    if chinese_count < chinese_required:
        issues.append(
            f"中文文献不足：要求至少 {chinese_required} 篇，当前 {chinese_count} 篇"
        )
    if recent_count < recent_required:
        issues.append(
            f"近五年文献不足：要求至少 {recent_required} 篇，当前 {recent_count} 篇"
        )

    return AuditResult(
        valid=not issues,
        entry_count=entry_count,
        chinese_count=chinese_count,
        chinese_required=chinese_required,
        recent_count=recent_count,
        recent_required=recent_required,
        issues=issues,
    )


def compose_report(result: AuditResult) -> str:
    lines = [
        "BibTeX 文献审计报告",
        f"状态：{'通过' if result.valid else '失败'}",
        f"条目数：{result.entry_count}",
        f"中文文献：{result.chinese_count} / 至少 {result.chinese_required}",
        f"近五年文献：{result.recent_count} / 至少 {result.recent_required}",
        f"问题数：{len(result.issues)}",
    ]
    if result.issues:
        lines.append("问题：")
        lines.extend(f"- {issue}" for issue in result.issues)
    return "\n".join(lines) + "\n"


def ratio(value: str) -> float:
    parsed = float(value)
    if not 0 <= parsed <= 1:
        raise argparse.ArgumentTypeError("比例必须位于 0 到 1 之间")
    return parsed


def nonnegative_integer(value: str) -> int:
    parsed = int(value)
    if parsed < 0:
        raise argparse.ArgumentTypeError("数量不能为负数")
    return parsed


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description="审计 Literature Search 的 BibTeX 输出")
    parser.add_argument("bib_file", type=Path, help="待审计的 .bib 文件")
    parser.add_argument("--report", type=Path, help="可选的 UTF-8 文本报告路径")
    parser.add_argument("--json-report", type=Path, help="可选的 JSON 报告路径")
    parser.add_argument("--target-count", type=nonnegative_integer, default=101)
    parser.add_argument("--chinese-ratio", type=ratio, default=0.30)
    parser.add_argument("--recent-ratio", type=ratio, default=0.30)
    return parser


def main() -> int:
    args = build_parser().parse_args()
    try:
        raw = args.bib_file.read_text(encoding="utf-8")
        entries = parse_entries(raw)
        result = audit_entries(
            entries,
            target_count=args.target_count,
            chinese_ratio=args.chinese_ratio,
            recent_ratio=args.recent_ratio,
        )
    except (OSError, UnicodeError, ValueError) as error:
        print(f"审计程序错误：{error}", file=sys.stderr)
        return 2

    report = compose_report(result)
    print(report, end="")
    if args.report:
        args.report.write_text(report, encoding="utf-8")
    if args.json_report:
        args.json_report.write_text(
            json.dumps(asdict(result), ensure_ascii=False, indent=2) + "\n",
            encoding="utf-8",
        )
    return 0 if result.valid else 1


if __name__ == "__main__":
    raise SystemExit(main())
