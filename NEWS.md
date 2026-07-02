# vigiar 0.7.1.9000

## Rio de Janeiro completeness hardening

* Added `vigiar_baixar_rj()` with RJ registry filtering, 92-municipality
  coverage metadata, optional cache, optional snapshots, and explicit failure
  when full RJ coverage is required but not present.
* Added `vigiar_rj_cobertura()` and `vigiar_rj_municipios_ausentes()` for
  coverage checks overall, by year, by month, by year-month, by health
  macro-region, and by health region.
* Added `vigiar_rj_completude_tabela()` for table-aware RJ completeness checks,
  including municipality x year for annual tables and municipality x year x
  month for monthly tables.
* Added `vigiar_baixar_municipio()` for code-based municipality downloads with
  metadata, coverage status, and truncation alerts. Campos dos Goytacazes is
  covered by a sentinel test using `330100` and `3301009`.
* Added safe municipality code normalization for 6-digit and 7-digit IBGE
  codes. The package standard remains the 6-digit IBGE municipality code, with
  7-digit RJ codes stored in the internal registry for interoperability.
* Added an IBGE reference fixture for the 92 RJ municipality codes and sentinel
  tests for Campos dos Goytacazes, Sao Francisco de Itabapoana, Sao Joao da
  Barra, and all 9 health macro-regions.
* Added `vigiar_baixar_rj_completo()` as an honest preparatory interface for
  partitioned downloads. It does not claim completeness when validated
  server-side filters are unavailable.
* Added `vigiar_esquema_verificar_critico()` and a critical schema lock fixture
  for RJ PM2.5, municipality, coordinate, and population workflows.
* Added `vigiar_plot_pm25_rj()` for optional exploratory PM2.5 plots when
  `ggplot2` is installed.
* Integrated RJ coverage and possible API truncation into
  `vigiar_diagnosticar_serie(..., escopo = "rj")`.
* Strengthened PM2.5 diagnostics for negative values, suspicious zeros,
  implausible extremes, long missing blocks, and abrupt series changes.
* Added offline RJ completeness tests, an optional online RJ download test, and
  `data-raw/check-rj-download-completeness.R` for manual source validation.
* Updated README, pkgdown reference, and vignettes with offline-safe RJ
  examples and scientific caveats about aggregate data, source availability,
  truncation, ecological inference, and the package boundary around causal
  modelling, GAM, DLNM, relative-risk, and machine-learning analyses.

# vigiar 0.7.0

## New: Benchmark & Performance

* `vigiar_benchmark()`: compare download strategies (direct, year_asc_desc,
  minimal_columns) with timing, row counts, and success rates.
* `vigiar_benchmark_tabelas()`: multi-table benchmark for API health monitoring.
* `vigiar_health_check()`: comprehensive health check (connection, schema,
  benchmark, compliance) returning a structured report.

## New: Compliance & Auditing

* `vigiar_auditar()`: full data audit covering schema, IBGE codes, temporal
  consistency, units, coverage, and checksums. Returns structured `vigiar_audit`
  object with S3 print method.
* `vigiar_auditar_tudo()`: batch audit across multiple tables.
* `vigiar_compliance_check()`: multi-profile compliance (basico, rigoroso, rj,
  corrupcao) with outlier detection and integrity checks.
* `vigiar_checksum()`: deterministic SHA256 checksum for any data frame.
* `vigiar_exportar_auditoria()`: export audit report as JSON for archiving.
* S3 classes: `vigiar_audit`, `vigiar_audit_list`, `vigiar_compliance` with
  print methods.

## New: Structured Logging

* `.vigiar_log()`: internal structured logger with INFO/WARN/ERROR/DEBUG levels.
* `vigiar_log()`: retrieve complete operation log as tibble.
* `vigiar_limpar_log()`: clear operation log.
* `vigiar_exportar_log()`: export log to CSV or JSON.
* `vigiar_resumo_log()`: summary statistics by level and table.
* `vigiar_historico_downloads()`: download history with timestamps and row counts.
* `vigiar_resumo_downloads()`: summary of all downloads in session.
* Automatic logging integrated into `vigiar_baixar()` via `.vigiar_registrar_download()`.

## New: Reproducibility & Snapshots

* `vigiar_snapshot()`: create data snapshots with SHA256 checksums, session info,
  and parameter provenance.
* `vigiar_verificar_snapshot()`: verify snapshot integrity.
* `vigiar_salvar_snapshot()` / `vigiar_carregar_snapshot()`: save/load snapshots.
* `vigiar_comparar_snapshots()`: diff two snapshots (dimensions, columns, checksums).

## New: Local Cache

* `vigiar_cache_dir()`: configure cache directory (defaults to platform-appropriate
  location).
* `vigiar_baixar_com_cache()`: download with automatic caching and TTL.
* `vigiar_cache_info()`: list cached tables with age and checksums.
* `vigiar_limpar_cache()`: clear cache by table or age.

## New: Schema Version Locking

* `vigiar_esquema_lock()`: freeze current schema to JSON for reproducibility.
* `vigiar_esquema_carregar_lock()`: load a schema lock file.
* `vigiar_esquema_verificar()`: compare live schema against a lock, detect changes.

## Changed

* `vigiar_baixar()` UF filter now tries multiple column names (UF, sigla_uf,
  UF_SIGLA, uf, cod_uf) and falls back to IBGE code range for RJ.
* `vigiar_baixar()` now uses `cli` for messages and integrates with logging.
* DESCRIPTION: added `cli`, `openssl`, `tools` to Imports. Bumped version to 0.7.0.
* NAMESPACE: added 30+ new exports for benchmark, audit, logging, cache, snapshots.
* Removed `stats::filter` import to avoid masking `dplyr::filter`.
* Fixed man page for `vigiar_baixar.Rd` to match `uf = "RJ"` default.
* Fixed non-ASCII characters in documentation files.

## Tests

* Added comprehensive offline tests for all new features (test-new-features.R).
* Added `tests/testthat.R` for proper testthat integration.

# vigiar 0.6.0
...
