---
name: literature-search
description: Search, verify, deduplicate, grade, and export scholarly literature with DOI-level evidence, explicit coverage quotas, Scopus-first citation searching, BibTeX output, and a LaTeX catalog containing metadata and abstracts. Use when Codex is asked to find papers, build a bibliography, conduct a literature search or review, locate Chinese and international research, verify references or DOIs, or export literature to BibTeX/LaTeX. By default, return more than 100 verified works, with at least 30% Chinese-language works and at least 30% published within the most recent five-year window; do not create Excel output unless explicitly requested.
---

# Literature Search

Build an auditable bibliography from real academic databases. Never infer or invent a title, author, venue, year, DOI, database record, or verification result.

## Apply defaults

- If the user gives no target count, deliver at least 101 eligible, deduplicated works. Search for 110-130 candidates so later exclusions do not break the quota.
- If the user explicitly requests a quick search, target 20-30 works. If the user requests a systematic or comprehensive search, preserve full queries, screening decisions, and exclusion reasons. Otherwise apply the 101-work standard mode.
- Require Chinese-language works to be at least `ceil(0.30 * N)` of the final set.
- Require recent works to be at least `ceil(0.30 * N)` of the final set. A work is recent when its publication date is no earlier than five calendar years before the search date. If only a year is known, count only years `current_year - 4` through `current_year` as recent.
- Allow Chinese-language and recent subsets to overlap. Report both counts independently.
- Treat a user-specified count or ratio as overriding only that default. Preserve all verification rules unless the user explicitly relaxes them.
- Interpret “Chinese literature” as Chinese-language scholarly work, not merely work by Chinese authors. Mark the language for every record.

## Execute the search

1. Parse the topic into concepts, synonyms, abbreviations, related terms, and Chinese/English translations. Record inclusion and exclusion criteria before screening.
2. Read [references/source-verification.md](references/source-verification.md) and follow its source, DOI, and evidence rules.
3. Search multiple complementary sources. Use Google Scholar for broad discovery; Scopus as the preferred curated citation index; Crossref, Semantic Scholar, and OpenAlex for metadata and citation expansion; arXiv for preprints; IEEE Xplore, ScienceDirect, and SpringerLink for publisher records; and CNKI plus Wanfang for Chinese-language coverage. Use Web of Science only when it is accessible or the user explicitly requests it; inability to access Web of Science is not a blocker when Scopus is available. Do not claim a source was searched if access, authentication, or subscription restrictions prevented a real query.
4. Search in batches and maintain a candidate ledger containing query, source, retrieval date, record URL, title, authors, year/date, venue, language, document type, DOI, abstract source, volume, issue, pages, screening status, relevance grade, and quality grade.
5. Screen title and abstract against the stated criteria. Exclude irrelevant, duplicate, retracted, unverified, or DOI-less records from the main bibliography.
6. Normalize DOI values to lowercase bare form by removing `https://doi.org/`, `http://dx.doi.org/`, `doi:`, whitespace, and trailing punctuation. Deduplicate first by normalized DOI, then by normalized title plus first author and year. Merge preprint, conference, online-first, and final journal versions as one work unless the user needs version comparison; normally retain the final peer-reviewed version and record version relations.
7. Verify each retained item individually. Do not treat a search-result snippet, an AI-generated citation, or another paper's reference list as verification.
8. Recalculate quotas after every exclusion. Continue searching until the final eligible set—not the raw candidate set—satisfies all count and ratio requirements.

## Grade usefulness

- Assign relevance as `high`, `medium`, or `background` from the title, abstract, and inclusion criteria. Do not retain off-topic works to satisfy the target count.
- Assign evidence quality as `core`, `supplementary`, or `caution`. Consider peer-review status, publication type, venue, study design, sample size when relevant, methodological transparency, citation context, and correction/retraction signals.
- Keep these grades auditable and avoid equating citation count, Scopus indexing, or Web of Science indexing alone with scientific quality.

## Enforce DOI integrity

- Include a DOI in every main-list reference and render it as `https://doi.org/<doi>`.
- Confirm that the DOI resolves and that the resolved metadata matches the candidate title, first author or author group, venue, and publication year without material conflict.
- Prefer the DOI shown by the publisher and corroborate it with Crossref or another authoritative index. For arXiv records, use a verified journal/conference DOI; never convert an arXiv identifier into a DOI.
- Never construct a DOI from a publisher pattern. Never “correct” an unresolved DOI by guessing.
- If a relevant work has no DOI, place it in an optional “Excluded or DOI-unavailable candidates” appendix only when useful; do not count it toward `N` or either quota.

## Produce an auditable result

State the search date, databases actually searched, exact queries or query families, date range, inclusion/exclusion criteria, and access limitations. Then provide:

1. A quota summary with final `N`, required and actual Chinese-language counts and percentages, and required and actual recent counts and percentages.
2. A deduplicated evidence table with sequential ID, full citation, language, publication date, normalized DOI link, discovery source, verification source(s), record URL, relevance grade, quality grade, version relation, and verification status.
3. A formatted reference list in the user's requested style; otherwise use GB/T 7714 for Chinese-language requests and a consistent author-year style for other requests. Every entry must contain its verified DOI link.
4. A concise exclusion summary covering duplicates, DOI failures, metadata conflicts, retractions, and topic exclusions.

## Export BibTeX and LaTeX

Read [references/bibtex-latex-output.md](references/bibtex-latex-output.md) and follow it exactly whenever literature is delivered. Create these two deliverables unless the user explicitly requests fewer:

- `literature_references.bib`: valid, deduplicated BibTeX records.
- `literature_catalog.tex`: a UTF-8 `ctex` document listing every work's metadata, DOI, verification sources, grades, and abstract or clearly labeled abstract summary.

Do not create Excel, XLSX, CSV, or other spreadsheet deliverables unless the user explicitly requests them. Put the readable evidence table and literature details directly in the LaTeX document. Compile the `.tex` with XeLaTeX for validation, but deliver the PDF only when the user requests a PDF; otherwise deliver the `.bib` and `.tex` files.

Use English filenames. Validate that the number of verified BibTeX entries equals the number of literature records in the LaTeX catalog and the reported final `N`.

Run `scripts/audit_literature_bib.py` in a project-specific Python virtual environment against the final `.bib` file. Pass user overrides through `--target-count`, `--chinese-ratio`, and `--recent-ratio`. Treat any reported missing field, duplicate DOI/key, invalid year, article volume/issue/pages gap, or quota failure as blocking until corrected.

Do not present a partially verified set as complete. If database access or topic scarcity makes a requirement impossible, report the verified partial count, identify the exact unmet quota, and explain the evidence gap instead of padding the bibliography.
