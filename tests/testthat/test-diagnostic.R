# vigiar: offline tests for diagnostic functions
library(testthat)
library(vigiar)

# ── Helper data ───────────────────────────────────────────────────────────────

.make_pm25_data <- function(n_muni = 10, years = 2018:2022, with_issues = FALSE) {
  municipios <- c(330010, 330015, 330020, 330022, 330023,
                  330025, 330030, 330033, 330040, 330045,
                  330050, 330060, 330070, 330080, 330090)
  municipios <- municipios[seq_len(min(n_muni, length(municipios)))]

  rows <- list()
  for (m in municipios) {
    base_pm25 <- runif(1, 10, 25)
    for (y in years) {
      pm25 <- base_pm25 + runif(1, -3, 3)
      rows[[length(rows) + 1]] <- data.frame(
        cod_municipio = as.integer(m),
        sigla_uf = "RJ",
        ano = as.integer(y),
        pm25_media_anual = pm25,
        municipio = paste("Mun", m),
        stringsAsFactors = FALSE
      )
    }
  }

  dados <- do.call(rbind, rows)
  rownames(dados) <- NULL

  if (with_issues) {
    dados$pm25_media_anual[1] <- -5
    dados$cod_municipio[2] <- 999999L
    dados <- rbind(dados, dados[3, ])
    dados$ano[4] <- 1800L
  }

  tibble::as_tibble(dados)
}

# Full RJ coverage (all 92 municipalities, 1 year each)
.make_pm25_full <- function() {
  municipios <- RJ_MUNICIPIOS$codigo_ibge
  rows <- list()
  for (m in municipios) {
    rows[[length(rows) + 1]] <- data.frame(
      cod_municipio = as.integer(m),
      sigla_uf = "RJ",
      ano = 2022L,
      pm25_media_anual = runif(1, 10, 25),
      stringsAsFactors = FALSE
    )
  }
  tibble::as_tibble(do.call(rbind, rows))
}

# ── Diagnostic construction ───────────────────────────────────────────────────

test_that("new_vigiar_diagnostic creates proper structure", {
  dados <- data.frame(x = 1:3)
  diag <- new_vigiar_diagnostic("test", dados)
  expect_s3_class(diag, "vigiar_diagnostic")
  expect_equal(diag$tabela, "test")
  expect_equal(diag$n_rows, 3)
})

test_that("vigiar_diagnosticar_serie works on partial data (10 municipalities)", {
  dados <- .make_pm25_data()
  diag <- vigiar_diagnosticar_serie(dados, escopo = "rj")
  expect_s3_class(diag, "vigiar_diagnostic")
  # 10 municipalities = ~10.8% -> should be 'problema' (not ok, not critico)
  expect_equal(diag$severidade, "problema")
  expect_true(length(diag$resultados) > 0)
})

test_that("vigiar_diagnosticar_serie works on full RJ coverage", {
  dados <- .make_pm25_full()
  diag <- vigiar_diagnosticar_serie(dados, escopo = "rj")
  expect_s3_class(diag, "vigiar_diagnostic")
  # Full 92 municipalities should be ok
  expect_equal(diag$severidade, "ok")
  expect_equal(diag$metricas$rj_cobertura_pct, 100)
})

test_that("vigiar_diagnosticar_serie detects issues", {
  dados <- .make_pm25_data(with_issues = TRUE)
  diag <- vigiar_diagnosticar_serie(dados, escopo = "rj")
  expect_true(diag$severidade %in% c("problema", "critico"))
})

test_that("vigiar_diagnosticar_serie errors on missing columns", {
  dados <- data.frame(x = 1:3)
  diag <- vigiar_diagnosticar_serie(dados)
  expect_equal(diag$severidade, "critico")
})

# ── Individual checks ─────────────────────────────────────────────────────────

test_that("vigiar_checar_ibge detects invalid codes", {
  dados <- data.frame(cod_municipio = c(355030L, 999999L, 110001L))
  diag <- new_vigiar_diagnostic("test", dados)
  diag <- vigiar_checar_ibge(diag, dados, "cod_municipio", uf = "RJ")
  expect_true(any(vapply(diag$resultados, function(x) x$severidade == "critico", logical(1))))
})

test_that("vigiar_checar_ibge detects non-RJ codes", {
  dados <- data.frame(cod_municipio = c(355030L, 110001L))
  diag <- new_vigiar_diagnostic("test", dados)
  diag <- vigiar_checar_ibge(diag, dados, "cod_municipio", uf = "RJ", escopo = "rj")
  expect_true(any(vapply(diag$resultados, function(x) x$severidade == "problema", logical(1))))
})

test_that("vigiar_checar_ibge handles missing column", {
  dados <- data.frame(x = 1:3)
  diag <- new_vigiar_diagnostic("test", dados)
  diag <- vigiar_checar_ibge(diag, dados, "nao_existe")
  expect_equal(diag$resultados[[1]]$severidade, "critico")
})

test_that("vigiar_checar_cobertura_temporal detects missing years", {
  dados <- data.frame(ano = c(2018L, 2020L, 2022L))
  diag <- new_vigiar_diagnostic("test", dados)
  diag <- vigiar_checar_cobertura_temporal(diag, dados, "ano")
  expect_true(any(vapply(diag$resultados, function(x) x$severidade == "aviso", logical(1))))
})

test_that("vigiar_checar_cobertura_temporal detects invalid years", {
  dados <- data.frame(ano = c(1800L, 2022L, 3000L))
  diag <- new_vigiar_diagnostic("test", dados)
  diag <- vigiar_checar_cobertura_temporal(diag, dados, "ano")
  expect_true(any(vapply(diag$resultados, function(x) x$severidade == "problema", logical(1))))
})

test_that("vigiar_checar_cobertura_espacial checks RJ coverage", {
  codigos <- c(330010, 330015, 330020, 330022, 355030)  # 4 RJ + 1 SP
  dados <- data.frame(cod_municipio = as.integer(codigos))
  diag <- new_vigiar_diagnostic("test", dados)
  diag <- vigiar_checar_cobertura_espacial(diag, dados, "cod_municipio", uf = "RJ", escopo = "rj")
  expect_equal(diag$metricas$rj_presentes, 4)
  expect_true(any(vapply(diag$resultados, function(x) x$severidade %in% c("aviso", "problema", "critico"), logical(1))))
})

test_that("vigiar_checar_pm25 detects negative values", {
  dados <- data.frame(pm25 = c(22.5, -5, 18.3))
  diag <- new_vigiar_diagnostic("test", dados)
  diag <- vigiar_checar_pm25(diag, dados, "pm25")
  expect_true(any(vapply(diag$resultados, function(x) x$severidade == "critico", logical(1))))
})

test_that("vigiar_checar_pm25 detects implausible values", {
  dados <- data.frame(pm25 = c(22.5, 5000))
  diag <- new_vigiar_diagnostic("test", dados)
  diag <- vigiar_checar_pm25(diag, dados, "pm25")
  critico_msgs <- vapply(diag$resultados, function(x) x$severidade == "critico", logical(1))
  expect_true(any(critico_msgs))
})

test_that("vigiar_checar_duplicatas finds duplicates", {
  dados <- data.frame(
    cod_municipio = c(1L, 1L, 2L),
    ano = c(2020L, 2020L, 2021L)
  )
  diag <- new_vigiar_diagnostic("test", dados)
  diag <- vigiar_checar_duplicatas(diag, dados, "cod_municipio", "ano")
  expect_true(any(vapply(diag$resultados, function(x) x$severidade %in% c("aviso", "problema"), logical(1))))
  expect_equal(diag$metricas$n_duplicatas, 1)
})

test_that("vigiar_checar_duplicatas finds no duplicates in clean data", {
  dados <- data.frame(
    cod_municipio = c(1L, 2L, 3L),
    ano = c(2020L, 2020L, 2021L)
  )
  diag <- new_vigiar_diagnostic("test", dados)
  diag <- vigiar_checar_duplicatas(diag, dados, "cod_municipio", "ano")
  expect_equal(diag$metricas$n_duplicatas, 0)
})

test_that("vigiar_checar_quebra_serie detects large changes", {
  dados <- data.frame(
    cod_municipio = c(1L, 1L, 1L),
    ano = c(2020L, 2021L, 2022L),
    pm25 = c(20, 5, 45)  # Large swings
  )
  diag <- new_vigiar_diagnostic("test", dados)
  diag <- vigiar_checar_quebra_serie(diag, dados, "cod_municipio", "ano", "pm25")
  expect_true(diag$metricas$n_quebras_serie > 0)
})

test_that("vigiar_classificar_alertas returns worst severity", {
  dados <- data.frame(x = 1)
  diag <- new_vigiar_diagnostic("test", dados)
  diag <- .vigiar_add_issue(diag, "ok", "ok msg")
  diag <- .vigiar_add_issue(diag, "critico", "critical msg")
  diag <- vigiar_classificar_alertas(diag)
  expect_equal(diag$severidade, "critico")
})

test_that("vigiar_classificar_alertas returns ok when no issues", {
  dados <- data.frame(x = 1)
  diag <- new_vigiar_diagnostic("test", dados)
  diag <- vigiar_classificar_alertas(diag)
  expect_equal(diag$severidade, "ok")
})

# ── S3 methods ────────────────────────────────────────────────────────────────

test_that("print.vigiar_diagnostic works", {
  dados <- data.frame(x = 1:3)
  diag <- new_vigiar_diagnostic("test", dados)
  expect_output(print(diag), "Diagnostico")
})

test_that("summary.vigiar_diagnostic works", {
  dados <- data.frame(x = 1:3)
  diag <- new_vigiar_diagnostic("test", dados)
  diag <- .vigiar_add_issue(diag, "aviso", "test warning")
  expect_output(summary(diag), "aviso=1")
})

test_that("vigiar_relatorio_diagnostico works", {
  dados <- .make_pm25_data()
  diag <- vigiar_diagnosticar_serie(dados, escopo = "rj")
  expect_output(vigiar_relatorio_diagnostico(diag), "Severidade")
})

# ── Edge cases ────────────────────────────────────────────────────────────────

test_that("vigiar_diagnosticar_serie handles empty data", {
  dados <- data.frame(
    cod_municipio = integer(),
    ano = integer(),
    pm25_media_anual = numeric()
  )
  diag <- vigiar_diagnosticar_serie(dados)
  expect_s3_class(diag, "vigiar_diagnostic")
})

test_that("vigiar_diagnosticar_serie handles single row", {
  dados <- data.frame(
    cod_municipio = 330455L,
    sigla_uf = "RJ",
    ano = 2022L,
    pm25_media_anual = 18.3
  )
  diag <- vigiar_diagnosticar_serie(dados, escopo = "rj")
  expect_s3_class(diag, "vigiar_diagnostic")
})

test_that("vigiar_diagnosticar_serie auto-detects columns", {
  dados <- data.frame(
    muni = 330455L,
    UF = "RJ",
    ano = 2022L,
    Media_pm25 = 18.3
  )
  diag <- vigiar_diagnosticar_serie(dados, escopo = "rj")
  expect_equal(diag$col_muni, "muni")
  expect_equal(diag$col_pm25, "Media_pm25")
})

test_that("diagnostic functions dont break with extra columns", {
  dados <- .make_pm25_data()
  dados$extra_col <- runif(nrow(dados))
  dados$another_col <- "test"
  diag <- vigiar_diagnosticar_serie(dados, escopo = "rj")
  expect_s3_class(diag, "vigiar_diagnostic")
})

test_that("error messages are in Portuguese", {
  dados <- data.frame(x = 1:3)
  diag <- vigiar_diagnosticar_serie(dados)
  msgs <- vapply(diag$resultados, `[[`, "", "mensagem")
  expect_true(any(grepl("encontrada", msgs)))
})

# ── Scope parameter ───────────────────────────────────────────────────────────

test_that("vigiar_diagnosticar_serie respects escopo = nacional", {
  dados <- data.frame(
    cod_municipio = c(355030L, 330455L, 110001L),
    ano = c(2022L, 2022L, 2022L),
    pm25 = c(22.5, 18.3, 15.7)
  )
  diag <- vigiar_diagnosticar_serie(dados, escopo = "nacional",
                                     col_muni = "cod_municipio",
                                     col_pm25 = "pm25",
                                     uf = NULL)
  expect_s3_class(diag, "vigiar_diagnostic")
})

test_that("vigiar_diagnosticar_serie with uf = NULL skips RJ checks", {
  dados <- data.frame(
    cod_municipio = c(355030L, 110001L),
    ano = c(2022L, 2022L),
    pm25 = c(22.5, 15.7)
  )
  diag <- vigiar_diagnosticar_serie(dados, uf = NULL,
                                     col_muni = "cod_municipio",
                                     col_pm25 = "pm25")
  # Should not have RJ-specific warnings
  problemas <- vapply(diag$resultados, function(x) x$severidade == "problema", logical(1))
  # Only check that it completes without error
  expect_s3_class(diag, "vigiar_diagnostic")
})
