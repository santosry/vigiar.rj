# AI Use Declaration

## Summary

This package received support from generative AI tools for code review,
refactoring, documentation, test authoring, and reproducibility auditing.
All technical, scientific, and editorial decisions were critically reviewed
by the responsible human author. AI was not used as a primary data source,
did not replace independent technical validation, and did not perform
autonomous scientific interpretation of VIGIAR data.

## Tools Used

| Tool | Version / Model | Tasks |
|------|----------------|-------|
| DeepSeek | v4 Pro (via API) | Code architecture review, DSR format reverse-engineering, retry logic design, test plan generation |
| ChatGPT | GPT‑5.5 (via interface) | Documentation drafting (README, vignettes, help pages), compliance checklist generation, SPDX/CFF/codemeta authoring |

## Tasks Where AI Was Used

- **Code review**: Identifying fragile patterns, missing error handling,
  and portability issues.
- **DSR parser reverse‑engineering**: Analysing the Power BI Data Shape
  Response format from captured HTTP responses.
- **Refactoring**: Splitting monolithic files into modular components,
  adding retry logic with exponential backoff.
- **Documentation**: Drafting README, vignettes, CONTRIBUTING,
  CODE_OF_CONDUCT, SECURITY, CITATION.cff, and codemeta.json.
- **Test design**: Generating test cases for the DSR parser, edge cases,
  and online/offline test separation.
- **CI/CD workflows**: GitHub Actions YAML for R‑CMD‑check, coverage,
  lint, and pkgdown.

## Tasks Where AI Was NOT Used

- **Data validation**: All data quality checks (`vigiar_checar_dados`,
  `vigiar_diagnostico`) were manually verified against the actual
  dashboard schema.
- **API authentication flow**: The Power BI anonymous session protocol
  was discovered and validated through manual HTTP debugging.
- **Statistical interpretation**: No AI-generated epidemiological
  conclusions.
- **Licensing and compliance**: Human‑verified against CRAN and rOpenSci
  policies.

## Human Responsibility

- All source code changes were reviewed and approved by the package
  author before commit.
- All documentation claims about data content were verified against
  the live dashboard.
- All test expectations were manually validated.

## Limitations

- AI-suggested code may contain subtle errors in edge cases not covered
  by tests.  The DSR parser, in particular, should be monitored when
  the Power BI dashboard schema changes.
- AI-generated documentation may occasionally introduce phrasing that
  reflects the model's training data rather than this specific package.

## Traceability

All changes can be traced through the Git history at:
https://github.com/santosry/vigiar-download

The following commits include AI‑assisted changes:

- Initial package structure and session management
- DSR parser redesign and ValueDicts resolution
- Retry logic and error handling
- Comprehensive README and vignette
- CI/CD workflows and compliance documentation

---
*Last updated: 2026‑06‑20*
