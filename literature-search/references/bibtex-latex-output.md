# BibTeX and LaTeX output specification

## Deliverables

Create these English-named UTF-8 files for each completed search:

1. `literature_references.bib`: canonical machine-readable BibTeX database.
2. `literature_catalog.tex`: human-readable catalog generated from the same verified records.

Do not rename a BibTeX database to `.tex`. Keep `.bib` for interoperability and place the readable, complete record presentation in `.tex`.

Do not generate Excel, XLSX, CSV, or another spreadsheet unless the user explicitly requests that format. Render search summaries, quota audits, evidence tables, and literature details directly in `literature_catalog.tex`.

## BibTeX requirements

Choose the correct entry type, such as `@article`, `@inproceedings`, `@book`, `@incollection`, `@phdthesis`, or `@misc`. Generate a unique ASCII citation key such as `FirstAuthor2025ShortTitle`; add `a`, `b`, and so on when needed.

Every verified entry must contain:

- `author`
- `title`
- `year`
- `doi`
- `url` using `https://doi.org/<doi>`
- `abstract`
- `language`
- `keywords` when verified keywords are available

Add type-specific metadata whenever applicable:

- Journal article: `journal`, `volume`, `number`, `pages`, and publication month/date when available.
- Conference paper: `booktitle`, pages, publisher/organization, address, and event date when available.
- Book chapter: `booktitle`, editor, publisher, volume/edition, and pages when available.
- Thesis: `school`, type, and address when available.
- Preprint: repository, e-print identifier, version, and publication status.

Do not invent volume, issue, pages, keywords, or any other missing value. For a journal article published online before assignment, add `note = {Online first; volume, issue, or pages not yet assigned}` as applicable. For entry types where volume or issue is not meaningful, add a concise `note` explaining that it is not applicable.

Obtain abstracts from the publisher, Scopus, Web of Science when accessible, another approved academic index, repository, or full record. Do not fabricate an abstract. Preserve an original abstract only when access and reuse conditions permit; otherwise write an accurate concise summary based on the verified abstract and begin the field with `[Abstract summary]`. Add a custom `abstractsource` field containing the source URL and an `abstracttype` field set to `original` or `summary`.

Escape BibTeX/LaTeX special characters correctly. Preserve capitalization of proper nouns with braces. Use balanced braces, one record per work, normalized DOI values, and no duplicate citation keys.

## LaTeX catalog requirements

Use `ctex` with XeLaTeX and UTF-8 encoding. For every work, display:

- citation key and sequential number;
- title and complete author list;
- publication year/date;
- journal or proceedings title;
- volume, issue, and pages, or an explicit not-applicable/not-assigned note;
- DOI as a clickable link;
- language and document type;
- discovery and verification sources;
- relevance and quality grades;
- version relationship when applicable;
- abstract, or the clearly marked abstract summary;
- abstract source URL.

Include at the beginning the search date, databases actually searched, queries or query families, inclusion/exclusion criteria, quota audit, access limitations, and file consistency totals. Include an exclusion summary at the end.

Avoid placing mathematical expressions inside text boxes. Render any formulas as normal LaTeX. Keep long URLs breakable and prevent tables or metadata blocks from overflowing the page.

## Validation and compilation

Before delivery:

1. Count BibTeX entries and catalog records; both must equal final `N`.
2. Check required fields, unique citation keys, normalized DOI values, DOI uniqueness, balanced braces, and nonempty abstracts.
3. Verify journal articles have volume/issue/pages or an explicit authoritative not-assigned explanation.
4. Check Chinese-language and recent-publication quotas from the final records.
5. Create or reuse a project-specific Python virtual environment, then run `python scripts/audit_literature_bib.py literature_references.bib --report literature_audit.txt` and resolve all failures. When the user overrides defaults, pass options such as `--target-count 30`, `--chinese-ratio 0.4`, and `--recent-ratio 0.5`.
6. Compile `literature_catalog.tex` using XeLaTeX. Run additional passes when references or contents require them.
7. Inspect the log for errors, missing characters, undefined references, overfull layout, and truncated abstracts. Fix problems and recompile.
8. Compile to a temporary PDF as a layout and syntax check. Deliver `.bib` and `.tex` by default. Deliver the compiled `.pdf` only when the user explicitly requests PDF output. If XeLaTeX is unavailable or compilation fails, report the exact blocker and do not claim the `.tex` was compilation-verified.
