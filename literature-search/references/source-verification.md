# Source and verification policy

## Source roles

Use at least three complementary source families when available:

- Broad discovery: Google Scholar.
- Preferred curated citation index: Scopus.
- Optional curated citation index: Web of Science, only when accessible or explicitly requested.
- Metadata and citation indexes: Crossref, Semantic Scholar, OpenAlex.
- Subject repositories: arXiv.
- Publisher or digital-library records: IEEE Xplore, Elsevier ScienceDirect, SpringerLink.
- Chinese academic databases: CNKI and Wanfang.

For a Chinese-language quota, search both CNKI and Wanfang when accessible. If either is inaccessible, state that limitation and use the accessible database plus authoritative publisher, journal, Crossref, OpenAlex, or DOI-resolution evidence. Do not describe Google Scholar result snippets as publisher verification.

## Minimum evidence for each retained work

Retain a work only when all checks pass:

1. Open a real record in at least one approved academic source.
2. Obtain DOI metadata from a publisher page, DOI resolution, Crossref, or an authoritative database record.
3. Resolve `https://doi.org/<doi>` successfully.
4. Match title, author identity, venue, and year/date across the discovery record and DOI evidence. Accept harmless differences in punctuation, transliteration, online-first versus issue year, or abbreviated venue names; flag material conflicts.
5. Check for retraction or withdrawal notices on the publisher record and, when available, Crossref metadata.

Prefer two independent evidence points: one discovery/index record and one publisher/DOI metadata record. A publisher page and DOI resolution to that same page count as one evidence family, so corroborate with Crossref, OpenAlex, Semantic Scholar, CNKI, or Wanfang when possible.

## Approved-domain guidance

Recognize legitimate regional or product domains used by the named services, but verify branding and destination before relying on them. Typical official hosts include:

- `scholar.google.com`
- `scopus.com`, `www.scopus.com`
- `webofscience.com`, `clarivate.com`
- `api.crossref.org`, `search.crossref.org`, `doi.org`
- `semanticscholar.org`
- `openalex.org`
- `arxiv.org`
- `ieeexplore.ieee.org`
- `sciencedirect.com`
- `link.springer.com`
- `cnki.net`
- `wanfangdata.com.cn`

Do not use ResearchGate, Academia.edu, blogs, commercial bibliography pages, generic web search snippets, or AI answers as the sole evidence for a retained record. They may suggest candidates only.

Use Scopus before Web of Science for curated indexing and citation searches. Record the Scopus EID and Scopus record URL when available. Treat Scopus as indexing and citation evidence, not as proof that every indexed claim is correct. If authentication or subscription prevents Scopus access, report the limitation and continue with other approved sources; never claim a Scopus search based only on a generic web result.

Use Web of Science only as an optional supplement. Record its accession number when available. If Web of Science is inaccessible but Scopus works, proceed with Scopus and state that Web of Science was not searched; do not treat this as a failed literature search.

## Record decisions

Use one of these statuses in the candidate ledger:

- `verified`: all eligibility and DOI checks pass.
- `duplicate`: DOI or work-level duplicate.
- `off-topic`: fails stated inclusion criteria.
- `doi-missing`: no DOI can be verified.
- `doi-unresolved`: supplied DOI does not resolve.
- `metadata-conflict`: DOI metadata materially disagrees with the candidate.
- `retracted-or-withdrawn`: authoritative notice found.
- `access-unverified`: access barriers prevent required checks.

Only `verified` records enter the main bibliography or quota calculations.
