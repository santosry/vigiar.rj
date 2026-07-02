# vigiar: online integration tests
#
# These tests require internet access and a working VIGIAR dashboard.
# Run with:  VIGIAR_RUN_ONLINE_TESTS=true  R CMD check
# Or:        withr::local_envvar(VIGIAR_RUN_ONLINE_TESTS = "true")
#            devtools::test()

library(testthat)
library(vigiar)

# Guard: skip all online tests unless explicitly enabled
# This runs at file-level load time, before any test_that() block
online_tests <- identical(tolower(Sys.getenv("VIGIAR_RUN_ONLINE_TESTS")), "true")
if (!online_tests) {
  skip("Online tests disabled. Set VIGIAR_RUN_ONLINE_TESTS=true to run.")
}

# If we get here, online tests are enabled

test_that("vigiar_baixar_rj downloads RJ data and computes coverage", {
  vigiar_conectar()
  withr::defer(vigiar_desconectar(), testthat::teardown_env())

  dados <- suppressWarnings(vigiar_baixar_rj("df_anual", validar_cobertura = TRUE))
  cov <- vigiar_rj_cobertura(dados)
  ausentes <- vigiar_rj_municipios_ausentes(dados)
  checksum <- vigiar_checksum(dados)
  checked_at <- format(Sys.time(), "%Y-%m-%d %H:%M:%S %Z")

  message(sprintf(
    paste(
      "RJ online check: checked_at=%s; table=df_anual; rows=%d;",
      "checksum=%s; municipios_presentes=%d; municipios_ausentes=%d"
    ),
    checked_at,
    nrow(dados),
    checksum,
    cov$n_municipios_presentes[1],
    nrow(ausentes)
  ))

  expect_s3_class(dados, "tbl_df")
  expect_true(nrow(dados) > 0)
  expect_s3_class(cov, "tbl_df")
  expect_true(cov$n_municipios_presentes > 0)
  expect_lte(cov$n_municipios_presentes, 92)
  expect_s3_class(ausentes, "tbl_df")
  expect_type(checksum, "character")
  expect_true(nchar(checksum) > 0)
  expect_true(all(dados$codigo_ibge_6 %in% vigiar_rj_municipios()$codigo_ibge_6))
})
