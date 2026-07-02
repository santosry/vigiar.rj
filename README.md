
# vigiar

<!-- badges: start -->

[![R-CMD-check](https://github.com/santosry/vigiar/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/santosry/vigiar/actions/workflows/R-CMD-check.yaml)
[![lint](https://github.com/santosry/vigiar/actions/workflows/lint.yaml/badge.svg)](https://github.com/santosry/vigiar/actions/workflows/lint.yaml)
[![pkgdown](https://github.com/santosry/vigiar/actions/workflows/pkgdown.yaml/badge.svg)](https://github.com/santosry/vigiar/actions/workflows/pkgdown.yaml)
[![License:
MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![R \>=
4.1.0](https://img.shields.io/badge/R-%3E%3D%204.1.0-blue.svg)](https://www.r-project.org/)
<!-- badges: end -->

`vigiar` is an R package for downloading, processing, validating,
auditing, and documenting public data from Brazil's VIGIAR environmental
health surveillance dashboard. The first robust workflow targets PM2.5
and the 92 municipalities of Rio de Janeiro state.

The package is deliberately conservative: it does not merely filter rows
for RJ. It measures whether the RJ download is complete, identifies
missing municipalities, warns about possible API truncation, and keeps
reproducibility metadata on the returned data.

## Installation

``` r
# install.packages("remotes")
remotes::install_github("santosry/vigiar")
```

Core dependencies are `httr2`, `jsonlite`, `tibble`, `dplyr`, `cli`, and
`openssl`. Vignettes use `knitr` and `rmarkdown`. The exploratory RJ
plot uses `ggplot2` only when it is installed.

## Quick Start

``` r
library(vigiar)

vigiar_conectar()

pm25_rj <- vigiar_baixar_rj("df_anual", validar_cobertura = TRUE)
cobertura <- vigiar_rj_cobertura(pm25_rj)
print(cobertura)

pm25_rj <- process_pm25(pm25_rj, tipo = "anual")
diag <- vigiar_diagnosticar_serie(pm25_rj, escopo = "rj")
vigiar_relatorio_diagnostico(diag)

snap <- vigiar_snapshot(dados = pm25_rj, tabela = "df_anual")
vigiar_salvar_snapshot(snap, "pm25_rj_snapshot.rds")

vigiar_desconectar()
```

## Downloading Rio de Janeiro Municipality Data

Use `vigiar_baixar_rj()` when the analysis scope is Rio de Janeiro. It
downloads the requested VIGIAR table, filters against the internal
registry of the 92 RJ municipalities, normalizes 6- and 7-digit IBGE
municipality codes to the package standard, and attaches coverage
metadata.

``` r
library(vigiar)

vigiar_conectar()

pm25_rj <- vigiar_baixar_rj("df_anual", validar_cobertura = TRUE)

cobertura <- vigiar_rj_cobertura(pm25_rj)
print(cobertura)

ausentes <- vigiar_rj_municipios_ausentes(pm25_rj)
print(ausentes)

pm25_rj <- process_pm25(pm25_rj, tipo = "anual")

diag <- vigiar_diagnosticar_serie(pm25_rj, escopo = "rj")
vigiar_relatorio_diagnostico(diag)

vigiar_desconectar()
```

When the research question requires all 92 municipalities, set
`exigir_completo = TRUE` or `require_complete = TRUE`. The function
stops with a clear error if any expected RJ municipality is absent or if
possible API truncation prevents the package from guaranteeing
completeness.

``` r
pm25_rj <- vigiar_baixar_rj(
  "df_anual",
  validar_cobertura = TRUE,
  require_complete = TRUE
)
```

Some VIGIAR tables may naturally contain fewer than 92 municipalities
for a given table, year, or month. A missing municipality can indicate
limited source availability, a schema change, an inappropriate filter,
API truncation, or a true absence from the source table. The package
reports this honestly, but the researcher must decide whether the
resulting data are epidemiologically fit for the intended analysis.

Useful RJ metadata are stored as attributes:

``` r
attr(pm25_rj, "vigiar_uf")
attr(pm25_rj, "vigiar_rj_n_municipios")
attr(pm25_rj, "vigiar_rj_n_esperado")
attr(pm25_rj, "vigiar_rj_cobertura_pct")
attr(pm25_rj, "vigiar_rj_municipios_ausentes")
attr(pm25_rj, "vigiar_possivel_truncamento")
```

## Municipality Code Standard

`vigiar` uses the 6-digit IBGE municipality code internally. The RJ
registry also includes `codigo_ibge_7`, because some public sources use
the official 7-digit code with a check digit.

``` r
vigiar_rj_municipios()
```

The internal normalizer accepts integer, numeric, and character inputs
such as `330455`, `3304557`, `"330455"`, and `" 330455 "`. Values that
cannot be safely normalized return `NA`.

For municipality-specific work, prefer code-based downloads instead of
filtering by municipality name. This avoids fragile joins caused by
spelling, accents, or source-specific name variants.

``` r
campos <- vigiar_baixar_municipio("df_anual", codigo_ibge = 330100)

attr(campos, "vigiar_codigo_ibge_6")
attr(campos, "vigiar_codigo_ibge_7")
attr(campos, "vigiar_municipio")
attr(campos, "vigiar_macrorregiao_saude")
```

## Coverage Diagnostics

`vigiar_rj_cobertura()` returns a tibble with:

- expected municipality count (`n_municipios_esperados = 92`);
- observed municipality count;
- coverage percentage;
- absent municipality names;
- incomplete health macro-regions;
- a completeness flag;
- a possible truncation flag.

Coverage can be calculated overall or by time unit:

``` r
vigiar_rj_cobertura(pm25_rj)
vigiar_rj_cobertura(pm25_rj, por = "ano")
vigiar_rj_cobertura(pm25_rj, por = "mes")
vigiar_rj_cobertura(pm25_rj, por = "ano_mes")
vigiar_rj_cobertura(pm25_rj, por = "macrorregiao")
vigiar_rj_cobertura(pm25_rj, por = "regiao_saude")
```

For table-aware completeness, use `vigiar_rj_completude_tabela()`. It
applies the expected grid for common VIGIAR tables: municipality x year
for annual tables, municipality x year x month for monthly PM2.5 tables,
and the best available municipal time grid for daily-reference tables.

``` r
vigiar_rj_completude_tabela(pm25_rj, tabela = "df_anual")

vigiar_rj_completude_tabela(
  pm25_rj,
  tabela = "df_anual",
  require_complete = TRUE
)
```

`vigiar_diagnosticar_serie(..., escopo = "rj")` uses these coverage
checks and adds clear messages such as complete RJ coverage, partial RJ
coverage, low coverage in a specific year, no valid RJ municipality
code, or possible API truncation.

## Processing

``` r
pm25 <- vigiar_baixar_rj("df_anual") |>
  process_pm25(tipo = "anual")

population <- vigiar_baixar_rj("pop") |>
  process_populacao_exposta()

health <- vigiar_baixar_rj("tb_muni") |>
  process_indicadores_saude(agregacao = "municipio")
```

Processed tibbles keep package metadata and S3 classes such as
`vigiar_pm25`, `vigiar_health`, and `vigiar_population`.

## Snapshots, Cache, and Audit

``` r
vigiar_cache_dir("~/.cache/vigiar")
pm25 <- vigiar_baixar_rj("df_anual", usar_cache = TRUE)

snapshot <- vigiar_snapshot(dados = pm25, tabela = "df_anual")
vigiar_verificar_snapshot(snapshot)

audit <- vigiar_auditar(pm25, tabela = "df_anual")
vigiar_exportar_auditoria(audit, "audit-pm25-rj.json")
```

Snapshots preserve RJ metadata, including coverage and truncation
attributes.

Schema locks can be used to detect dashboard changes before an analysis
is reused. `vigiar_esquema_verificar_critico()` checks the locked
critical columns used by the RJ PM2.5, municipality, coordinate, and
population workflows.

``` r
vigiar_esquema_lock("vigiar_schema_lock.json")
vigiar_esquema_verificar("vigiar_schema_lock.json", error = TRUE)
vigiar_esquema_verificar_critico(error = TRUE)
```

The manual validation script `data-raw/check-rj-download-completeness.R`
writes timestamped reports, checksums, coverage tables, and
missing-municipality lists under
`data-raw/rj-download-completeness-output/`. These generated files are
intended to be archived with a release or local validation record, not
committed as package data.

## Exploratory Plot

``` r
pm25 <- vigiar_baixar_rj("df_anual", processar = TRUE, tipo = "anual")

vigiar_plot_pm25_rj(pm25, por = "ano")
vigiar_plot_pm25_rj(pm25, por = "macrorregiao")
```

This plot is exploratory. It does not download, process, or repair data
silently.

## Tables

| Table                | Main content                             |
|----------------------|------------------------------------------|
| `df_anual`           | Annual PM2.5 by municipality             |
| `df_mensal`          | Monthly PM2.5 by municipality            |
| `df_dias`            | Days above the WHO daily PM2.5 reference |
| `df_dias_conama`     | Days above the CONAMA PM2.5 reference    |
| `pop`                | Population exposure                      |
| `df_muni`            | Municipality registry                    |
| `tb_brasil`          | Brazil-level health indicators           |
| `tb_uf`              | UF-level health indicators               |
| `tb_muni`            | Municipality-level health indicators     |
| `tb_fracao`          | Attributable fraction estimates          |
| `tb_quartis`         | Indicator quartiles                      |
| `df_indoor`          | Indoor solid-fuel exposure               |
| `df_indoor_desfecho` | Indoor exposure health outcomes          |
| `medidas`            | Calculated dashboard measures            |

Run `vigiar_info()` for the live table catalogue after connecting.

## Scientific Cautions

- VIGIAR data are public, aggregated surveillance data.
- PM2.5 may be estimated or modelled, not measured at every ground
  location.
- A dataset can be available and still be incomplete for RJ.
- Spatial coverage must be checked before municipality or macro-region
  claims.
- The Power BI API may truncate large responses.
- Tables without municipality codes cannot prove 92/92 RJ coverage.
- Short time series and missing months limit trend interpretation.
- Ecological associations do not establish individual-level causality.
- This package prepares and audits data. It does not implement or
  validate causal inference, GAM, DLNM, relative-risk, or
  machine-learning models.

## Citation

> Santos, R. (2026). vigiar: VIGIAR Environmental Health Data for Rio de
> Janeiro. R package version 0.7.1.9000.
> <https://github.com/santosry/vigiar>

## License

MIT. Downloaded public data remain under the responsibility and terms of
the Brazilian Ministry of Health / VIGIAR source.
