# vigiar: offline tests for critical schema locks

library(testthat)
library(vigiar)

.with_schema <- function(schema, code) {
  old_schema <- .vigiar_env$esquema
  on.exit({
    .vigiar_env$esquema <- old_schema
  }, add = TRUE)
  .vigiar_env$esquema <- schema
  force(code)
}

.critical_schema <- function() {
  list(
    df_anual = list(
      muni = list(tipo = "integer"),
      UF = list(tipo = "character"),
      ano = list(tipo = "integer"),
      Media_pm25 = list(tipo = "numeric")
    ),
    df_mensal = list(
      muni = list(tipo = "integer"),
      UF = list(tipo = "character"),
      ano = list(tipo = "integer"),
      mes = list(tipo = "integer"),
      pm25 = list(tipo = "numeric"),
      LAT = list(tipo = "numeric"),
      LON = list(tipo = "numeric")
    ),
    df_dias = list(
      ID_MUNI = list(tipo = "integer"),
      ano = list(tipo = "integer"),
      mes = list(tipo = "integer"),
      t_dias = list(tipo = "numeric"),
      n_dias = list(tipo = "integer")
    ),
    pop = list(
      muni = list(tipo = "integer"),
      ano = list(tipo = "integer"),
      pop = list(tipo = "numeric"),
      categoria = list(tipo = "character"),
      UF = list(tipo = "character")
    ),
    df_muni = list(
      MUN_COD = list(tipo = "integer"),
      MUN_NOME = list(tipo = "character"),
      UF_SIGLA = list(tipo = "character"),
      LAT = list(tipo = "numeric"),
      LON = list(tipo = "numeric")
    )
  )
}

.critical_lock <- function(schema = .critical_schema()) {
  structure(
    list(
      locked_at = "2026-07-02",
      tabelas = names(schema),
      esquema = schema
    ),
    class = "vigiar_schema_lock"
  )
}

test_that("critical schema verification passes for matching columns and types", {
  schema <- .critical_schema()
  .with_schema(schema, {
    diffs <- vigiar_esquema_verificar_critico(.critical_lock(schema), error = TRUE)
    expect_equal(length(diffs), 0)
  })
})

test_that("critical schema verification fails on missing columns", {
  schema <- .critical_schema()
  schema$df_mensal$pm25 <- NULL

  .with_schema(schema, {
    expect_error(
      vigiar_esquema_verificar_critico(.critical_lock(), error = TRUE),
      "Critical schema changed"
    )
    diffs <- vigiar_esquema_verificar_critico(.critical_lock(), error = FALSE)
    expect_true("missing_columns" %in% names(diffs))
    expect_true("pm25" %in% diffs$missing_columns$df_mensal)
  })
})

test_that("schema lock verification detects critical type changes", {
  schema <- .critical_schema()
  schema$df_anual$Media_pm25$tipo <- "character"

  .with_schema(schema, {
    expect_error(
      vigiar_esquema_verificar_critico(.critical_lock(), error = TRUE),
      "Critical schema changed"
    )
    diffs <- vigiar_esquema_verificar_critico(.critical_lock(), error = FALSE)
    expect_true("type_changes" %in% names(diffs))

    full_diffs <- vigiar_esquema_verificar(.critical_lock(), error = FALSE)
    expect_true("type_changes" %in% names(full_diffs))
  })
})
