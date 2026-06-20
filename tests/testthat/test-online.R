# vigiar: online integration tests
#
# These tests require internet access and a working VIGIAR dashboard.
# Run with:  VIGIAR_RUN_ONLINE_TESTS=true  R CMD check
# Or:        withr::local_envvar(VIGIAR_RUN_ONLINE_TESTS = "true")
#            devtools::test()

library(testthat)
library(vigiar.rj)

# Guard — skip all online tests unless explicitly enabled
online_tests <- identical(tolower(Sys.getenv("VIGIAR_RUN_ONLINE_TESTS")), "true")
if (!online_tests) {
  skip_all("VIGIAR_RUN_ONLINE_TESTS != 'true' — skipping online tests.")
}

# ── Connection ────────────────────────────────────────────────────────────────

test_that("vigiar_conectar establishes a session", {
  skip_if_offline()
  vigiar_desconectar()
  sess <- vigiar_conectar(timeout = 30)
  expect_s3_class(sess, "vigiar_sessao")
  expect_true(vigiar_sessao_ativa())
})

test_that("vigiar_conectar caches the session", {
  skip_if_offline()
  vigiar_desconectar()
  vigiar_conectar()
  expect_message(
    vigiar_conectar(),
    "já está ativa"
  )
})

test_that("vigiar_conectar refresh forces reconnection", {
  skip_if_offline()
  vigiar_conectar()
  expect_message(
    vigiar_conectar(refresh = TRUE),
    "Sessão VIGIAR estabelecida"
  )
})

# ── Schema inspection ─────────────────────────────────────────────────────────

test_that("vigiar_tabelas returns character vector", {
  skip_if_offline()
  vigiar_conectar()
  tabs <- vigiar_tabelas()
  expect_type(tabs, "character")
  expect_true(length(tabs) >= 25)  # VIGIAR has ~32 tables
  expect_true("df_anual" %in% tabs)
})

test_that("vigiar_esquema shows table info", {
  skip_if_offline()
  vigiar_conectar()
  expect_output(vigiar_esquema(), "colunas")
  expect_output(vigiar_esquema("df_anual"), "Tabela: df_anual")
})

test_that("vigiar_info returns tibble with categories", {
  skip_if_offline()
  vigiar_conectar()
  info <- vigiar_info()
  expect_s3_class(info, "tbl_df")
  expect_true("categoria" %in% names(info))
  expect_true("Qualidade do Ar" %in% info$categoria)
})

# ── Data download ─────────────────────────────────────────────────────────────

test_that("vigiar_baixar downloads a table", {
  skip_if_offline()
  vigiar_conectar()
  df <- vigiar_baixar("df_anual", limite = 5)
  expect_s3_class(df, "tbl_df")
  expect_true(nrow(df) <= 5)
  expect_true("ano" %in% names(df))
})

test_that("vigiar_baixar downloads with selected columns", {
  skip_if_offline()
  vigiar_conectar()
  df <- vigiar_baixar("df_anual", colunas = c("ano", "UF"),
                       limite = 3)
  expect_equal(names(df), c("ano", "UF"))
})

test_that("vigiar_baixar errors on invalid table", {
  skip_if_offline()
  vigiar_conectar()
  expect_error(
    vigiar_baixar("tabela_inexistente"),
    "não encontrada"
  )
})

test_that("vigiar_baixar_tudo downloads multiple tables", {
  skip_if_offline()
  vigiar_conectar()
  result <- vigiar_baixar_tudo(
    tabelas = c("df_ano", "df_mes")
  )
  expect_type(result, "list")
  expect_length(result, 2)
  expect_true("df_ano" %in% names(result))
})

test_that("vigiar_baixar_principais returns a list", {
  skip_if_offline()
  vigiar_conectar()
  result <- vigiar_baixar_principais()
  expect_type(result, "list")
  expect_true(length(result) >= 5)
})

# ── Health indicators tables ──────────────────────────────────────────────────

test_that("tb_brasil has expected structure", {
  skip_if_offline()
  vigiar_conectar()
  df <- vigiar_baixar("tb_brasil", limite = 5)
  expected_cols <- c("Indicador", "n", "est", "low", "high", "desfecho", "ano")
  for (col in expected_cols) {
    expect_true(col %in% names(df))
  }
})

test_that("df_indoor downloads correctly", {
  skip_if_offline()
  vigiar_conectar()
  df <- vigiar_baixar("df_indoor", limite = 5)
  expect_s3_class(df, "tbl_df")
  expect_true("Ano" %in% names(df) || "Code" %in% names(df))
})

# ── Data validation ───────────────────────────────────────────────────────────

test_that("vigiar_checar_dados runs diagnostics", {
  skip_if_offline()
  vigiar_conectar()
  df <- vigiar_baixar("df_ano", limite = 10)
  expect_output(
    vigiar_checar_dados(df, tabela = "df_ano"),
    "Linhas:"
  )
})

# ── Status check ──────────────────────────────────────────────────────────────

test_that("vigiar_status reports online when connected", {
  skip_if_offline()
  vigiar_conectar()
  status <- vigiar_status()
  expect_true(status$online)
})

# ── Disconnect ────────────────────────────────────────────────────────────────

test_that("vigiar_desconectar clears session", {
  skip_if_offline()
  vigiar_conectar()
  vigiar_desconectar()
  expect_false(vigiar_sessao_ativa())
})
