# vigiar 0.1.0

## New features

* `vigiar_conectar()`: anonymous Power BI session with retry logic.
* `vigiar_baixar()`: download a single table → tibble.
* `vigiar_baixar_tudo()`: download all 32 tables.
* `vigiar_baixar_principais()`: shortcut for 14 key tables.
* `vigiar_info()`: table catalogue with descriptions and categories.
* `vigiar_esquema()`: column names and R types.
* `vigiar_tabelas()`: list available tables.
* `vigiar_status()`: dashboard availability check.
* `vigiar_checar_dados()`: data quality diagnostics (NAs, duplicates).
* `vigiar_diagnostico()`: sample + diagnose all tables.
* `vigiar_desconectar()` / `vigiar_sessao_ativa()`: session lifecycle.

## Technical

* Full DSR (Data Shape Response) parser: DM0 array, ValueDicts,
  R‑based row compression, gzip streaming decompression.
* Retry with exponential backoff for transient HTTP failures.
* Cookie extraction robust to multi‑header `set-cookie`.
* Internal `%||%` and `uuid_v4()` utilities.
* Online tests guarded by `VIGIAR_RUN_ONLINE_TESTS` env var.
* CI/CD: GitHub Actions for R‑CMD‑check, coverage, and lint.

## Documentation

* Comprehensive README with table catalogue.
* Vignette with examples per data category.
* CONTRIBUTING.md, CODE_OF_CONDUCT.md, SECURITY.md.
* CITATION.cff, codemeta.json.
* AI_USE_DECLARATION.md.

## Dependencies

* R ≥ 4.0.0
* httr2, jsonlite, tibble
* Suggests: testthat, dplyr, ggplot2, sf, knitr, rmarkdown, withr, cli
