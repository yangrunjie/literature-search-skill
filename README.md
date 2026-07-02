# Literature Search Skill

A Codex skill for auditable academic literature discovery, verification, deduplication, and LaTeX/BibTeX export.

## Features

- Searches Scopus first and supports Google Scholar, Crossref, Semantic Scholar, OpenAlex, arXiv, IEEE Xplore, ScienceDirect, SpringerLink, CNKI, Wanfang, and optionally Web of Science.
- Requires DOI resolution and metadata cross-checking; never pads results with invented references.
- Defaults to at least 101 verified works, at least 30% Chinese-language literature, and at least 30% literature from the most recent five-year window.
- Exports a UTF-8 BibTeX database and a `ctex`-based LaTeX literature catalog containing metadata and abstracts or labeled abstract summaries.
- Uses a MATLAB audit script to check required fields, citation-key and DOI uniqueness, publication metadata, and quota compliance.
- Does not generate Excel or CSV output unless explicitly requested.

## Installation

Copy the `literature-search` directory into your Codex skills directory:

```text
~/.codex/skills/literature-search
```

Then invoke it with:

```text
$literature-search
```

## Default outputs

- `literature_references.bib`
- `literature_catalog.tex`

The LaTeX document uses UTF-8, `ctex`, and XeLaTeX. It is compiled for validation; PDF delivery is optional.

## 中文说明

该 Skill 用于检索、核验、去重和整理中英文文献。默认检索不少于 101 篇有效文献，其中中文文献和近五年文献分别不少于 30%。每篇文献必须核验 DOI 和关键元数据，并输出包含摘要的 BibTeX 与 LaTeX 文档。默认不生成 Excel 或 CSV 文件。
