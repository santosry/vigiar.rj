# vigiar: offline tests for new features (v0.7.0)
# Benchmark, compliance, logging, cache, snapshots

library(testthat)
library(vigiar)

# -- Benchmark -----------------------------------------------------------------

test_that("vigiar_benchmark errors without session", {
  expect_error(vigiar_benchmark("df_anual"), "Nenhuma sessao")
})

test_that("vigiar_benchmark_tabelas errors without session", {
  expect_error(vigiar_benchmark_tabelas(), "Nenhuma sessao")
})

test_that("vigiar_health_check errors gracefully without connection", {
  # Error is expected since there's no active connection
  result <- tryCatch(
    vigiar_health_check(timeout = 5),
    error = function(e) e
  )
  expect_s3_class(result, "error")
})

# -- Compliance & Audit --------------------------------------------------------

test_that("vigiar_auditar runs on a simple data frame", {
  dados <- data.frame(
    cod_municipio = c(355030L, 330455L, 110001L),
    sigla_uf = c("SP", "RJ", "RO"),
    ano = c(2022L, 2022L, 2022L),
    pm25_media_anual = c(22.5, 18.3, 15.7),
    stringsAsFactors = FALSE
  )
  audit <- vigiar_auditar(dados, tabela = "test", verbose = FALSE)
  expect_s3_class(audit, "vigiar_audit")
  expect_true("schema" %in% names(audit))
  expect_true("ibge" %in% names(audit))
  expect_true("temporal" %in% names(audit))
  expect_true("units" %in% names(audit))
  expect_true("coverage" %in% names(audit))
  expect_true("checksums" %in% names(audit))
})

test_that("vigiar_auditar detects IBGE issues", {
  dados <- data.frame(
    cod_municipio = c(999999L, 100000L),
    sigla_uf = c("XX", "YY"),
    ano = c(2022L, 2022L),
    stringsAsFactors = FALSE
  )
  audit <- vigiar_auditar(dados, tabela = "test", verbose = FALSE)
  expect_false(audit$ibge$ok)
  expect_equal(audit$ibge$n_invalidos, 2)
})

test_that("vigiar_auditar detects temporal issues", {
  dados <- data.frame(
    cod_municipio = c(355030L),
    sigla_uf = c("SP"),
    ano = c(1800L, 3000L),
    stringsAsFactors = FALSE
  )
  audit <- vigiar_auditar(dados, tabela = "test", verbose = FALSE)
  expect_false(audit$temporal$ok)
})

test_that("vigiar_auditar detects unit issues in PM2.5", {
  dados <- data.frame(
    cod_municipio = c(355030L),
    sigla_uf = c("SP"),
    ano = c(2022L),
    pm25_media = c(-50, 2000),
    stringsAsFactors = FALSE
  )
  audit <- vigiar_auditar(dados, tabela = "test", verbose = FALSE)
  expect_false(audit$units$ok)
})

test_that("vigiar_auditar_tudo runs on named list", {
  df1 <- data.frame(cod_municipio = 355030L, ano = 2022L, stringsAsFactors = FALSE)
  df2 <- data.frame(cod_municipio = 330455L, ano = 2022L, stringsAsFactors = FALSE)
  result <- vigiar_auditar_tudo(list(df_anual = df1, df_mensal = df2), verbose = FALSE)
  expect_s3_class(result, "vigiar_audit_list")
  expect_length(result, 2)
  expect_true("df_anual" %in% names(result))
})

test_that("print.vigiar_audit works", {
  dados <- data.frame(cod_municipio = 355030L, ano = 2022L)
  audit <- vigiar_auditar(dados, tabela = "test", verbose = FALSE)
  expect_message(print(audit), "Auditoria")
})

test_that("print.vigiar_audit_list works", {
  df1 <- data.frame(cod_municipio = 355030L, ano = 2022L)
  result <- vigiar_auditar_tudo(list(t1 = df1), verbose = FALSE)
  expect_message(print(result), "Multi-Tabela")
})

test_that("vigiar_compliance_check runs all profiles", {
  dados <- data.frame(
    cod_municipio = c(355030L, 330455L),
    sigla_uf = c("SP", "RJ"),
    ano = c(2022L, 2022L),
    stringsAsFactors = FALSE
  )
  result <- vigiar_compliance_check(dados, tabela = "test",
                                     profiles = c("basico", "rigoroso", "rj", "corrupcao"),
                                     verbose = FALSE)
  expect_s3_class(result, "vigiar_compliance")
  expect_equal(names(result), c("basico", "rigoroso", "rj", "corrupcao"))
})

test_that("print.vigiar_compliance works", {
  dados <- data.frame(cod_municipio = 355030L, ano = 2022L)
  result <- vigiar_compliance_check(dados, tabela = "test", profiles = "basico",
                                     verbose = FALSE)
  expect_message(print(result), "Compliance")
})

test_that("vigiar_checksum returns consistent hash", {
  dados <- data.frame(x = 1:3, y = letters[1:3])
  h1 <- vigiar_checksum(dados)
  h2 <- vigiar_checksum(dados)
  expect_equal(h1, h2)
  expect_type(h1, "character")
  expect_true(nchar(h1) > 32)
})

test_that("vigiar_exportar_auditoria writes JSON", {
  dados <- data.frame(cod_municipio = 355030L, ano = 2022L)
  audit <- vigiar_auditar(dados, tabela = "test", verbose = FALSE)
  tmp <- file.path(tempdir(), "audit.json")
  on.exit(unlink(tmp))
  vigiar_exportar_auditoria(audit, tmp)
  expect_true(file.exists(tmp))
})

# -- Logging -------------------------------------------------------------------

test_that("vigiar_log returns empty tibble initially", {
  # Clear log first
  .vigiar_env$log <- list()
  df <- vigiar_log()
  expect_s3_class(df, "tbl_df")
  expect_equal(nrow(df), 0)
})

test_that(".vigiar_log adds entries", {
  .vigiar_env$log <- list()
  .vigiar_log("INFO", "Test message", table = "test")
  .vigiar_log("ERROR", "Error message", table = "test")
  df <- vigiar_log()
  expect_equal(nrow(df), 2)
  expect_true(df$level[1] == "INFO")
  expect_true(df$level[2] == "ERROR")
})

test_that("vigiar_limpar_log clears entries", {
  .vigiar_env$log <- list()
  .vigiar_log("INFO", "msg")
  vigiar_limpar_log()
  df <- vigiar_log()
  expect_equal(nrow(df), 0)
})

test_that("vigiar_exportar_log writes CSV", {
  .vigiar_env$log <- list()
  .vigiar_log("INFO", "Test", table = "test")
  tmp <- file.path(tempdir(), "log.csv")
  on.exit(unlink(tmp))
  vigiar_exportar_log(tmp)
  expect_true(file.exists(tmp))
})

test_that("vigiar_exportar_log writes JSON", {
  .vigiar_env$log <- list()
  .vigiar_log("INFO", "Test JSON", table = "test")
  tmp <- file.path(tempdir(), "log.json")
  on.exit(unlink(tmp))
  vigiar_exportar_log(tmp)
  expect_true(file.exists(tmp))
})

test_that("vigiar_resumo_log works", {
  .vigiar_env$log <- list()
  .vigiar_log("INFO", "msg1")
  .vigiar_log("WARN", "msg2")
  expect_message(vigiar_resumo_log(), "Resumo do Log")
})

test_that("vigiar_historico_downloads returns empty initially", {
  .vigiar_env$download_history <- list()
  df <- vigiar_historico_downloads()
  expect_equal(nrow(df), 0)
})

test_that(".vigiar_registrar_download adds entries", {
  .vigiar_env$download_history <- list()
  .vigiar_registrar_download("test", 100L, 5L, 1.5, "https://example.com")
  df <- vigiar_historico_downloads()
  expect_equal(nrow(df), 1)
  expect_equal(df$tabela[1], "test")
  expect_equal(df$n_rows[1], 100)
})

test_that("vigiar_resumo_downloads works", {
  .vigiar_env$download_history <- list()
  .vigiar_registrar_download("t1", 100L, 5L, 1.0, "url")
  .vigiar_registrar_download("t2", 200L, 3L, 2.0, "url")
  expect_message(vigiar_resumo_downloads(), "Downloads")
})

# -- Snapshot ------------------------------------------------------------------

test_that("vigiar_snapshot creates object from data frame", {
  dados <- data.frame(x = 1:3, y = letters[1:3])
  snap <- vigiar_snapshot(dados = dados, tabela = "test")
  expect_s3_class(snap, "vigiar_snapshot")
  expect_equal(snap$n_rows, 3)
  expect_equal(snap$n_cols, 2)
  expect_true(nchar(snap$checksum_sha256) > 32)
})

test_that("vigiar_snapshot errors without data", {
  expect_error(vigiar_snapshot(), "Forneca")
})

test_that("vigiar_verificar_snapshot confirms integrity", {
  dados <- data.frame(x = 1:3)
  snap <- vigiar_snapshot(dados = dados, tabela = "test")
  expect_true(vigiar_verificar_snapshot(snap))
})

test_that("vigiar_verificar_snapshot detects corruption", {
  dados <- data.frame(x = 1:3)
  snap <- vigiar_snapshot(dados = dados, tabela = "test")
  snap$dados$x[1] <- 999  # corrupt
  expect_false(vigiar_verificar_snapshot(snap))
})

test_that("vigiar_salvar_snapshot and vigiar_carregar_snapshot roundtrip", {
  dados <- data.frame(x = 1:3, y = letters[1:3])
  snap <- vigiar_snapshot(dados = dados, tabela = "test")
  tmp <- file.path(tempdir(), "test_snap.rds")
  on.exit(unlink(tmp))
  vigiar_salvar_snapshot(snap, tmp)
  loaded <- vigiar_carregar_snapshot(tmp)
  expect_s3_class(loaded, "vigiar_snapshot")
  expect_equal(loaded$checksum_sha256, snap$checksum_sha256)
})

test_that("print.vigiar_snapshot works", {
  dados <- data.frame(x = 1:3)
  snap <- vigiar_snapshot(dados = dados, tabela = "test")
  expect_message(print(snap), "VIGIAR Snapshot")
})

test_that("vigiar_comparar_snapshots detects differences", {
  d1 <- data.frame(x = 1:3)
  d2 <- data.frame(x = 4:6)
  s1 <- vigiar_snapshot(dados = d1, tabela = "test")
  s2 <- vigiar_snapshot(dados = d2, tabela = "test")
  diffs <- vigiar_comparar_snapshots(s1, s2)
  expect_true(diffs$checksum_changed)
})

test_that("vigiar_comparar_snapshots detects column changes", {
  d1 <- data.frame(x = 1:3, y = 4:6)
  d2 <- data.frame(x = 1:3, z = 7:9)
  s1 <- vigiar_snapshot(dados = d1, tabela = "test")
  s2 <- vigiar_snapshot(dados = d2, tabela = "test")
  diffs <- vigiar_comparar_snapshots(s1, s2)
  expect_true("cols_added" %in% names(diffs) || "cols_removed" %in% names(diffs))
})

# -- Cache ---------------------------------------------------------------------

test_that("vigiar_cache_dir sets and gets directory", {
  old_cache <- .vigiar_env$cache_dir
  on.exit({ .vigiar_env$cache_dir <- old_cache })

  tmp <- file.path(tempdir(), "vigiar_test_cache")
  on.exit(unlink(tmp, recursive = TRUE), add = TRUE)

  vigiar_cache_dir(tmp)
  expect_equal(.vigiar_env$cache_dir, tmp)
  expect_true(dir.exists(tmp))

  # Get current
  cur <- vigiar_cache_dir()
  expect_equal(cur, tmp)
})

test_that("vigiar_cache_info returns tibble when empty", {
  old_cache <- .vigiar_env$cache_dir
  on.exit({ .vigiar_env$cache_dir <- old_cache })

  tmp <- file.path(tempdir(), "vigiar_empty_cache")
  dir.create(tmp, showWarnings = FALSE)
  on.exit(unlink(tmp, recursive = TRUE), add = TRUE)

  vigiar_cache_dir(tmp)
  info <- vigiar_cache_info()
  expect_s3_class(info, "tbl_df")
  expect_equal(nrow(info), 0)
})

test_that("vigiar_limpar_cache handles empty cache", {
  old_cache <- .vigiar_env$cache_dir
  on.exit({ .vigiar_env$cache_dir <- old_cache })

  tmp <- file.path(tempdir(), "vigiar_clear_cache")
  dir.create(tmp, showWarnings = FALSE)
  on.exit(unlink(tmp, recursive = TRUE), add = TRUE)

  vigiar_cache_dir(tmp)
  vigiar_limpar_cache()
  # Should not error
  expect_true(TRUE)
})

test_that("vigiar_baixar_com_cache errors without session", {
  expect_error(vigiar_baixar_com_cache("df_anual"), "Nenhuma sessao")
})

# -- Schema Lock ---------------------------------------------------------------

test_that("vigiar_esquema_lock errors without session", {
  expect_error(vigiar_esquema_lock(), "Nenhuma sessao")
})

test_that("vigiar_esquema_carregar_lock errors on missing file", {
  tmp <- file.path(tempdir(), "nonexistent_lock.json")
  expect_error(vigiar_esquema_carregar_lock(tmp), "nao encontrado")
})

test_that("vigiar_esquema_carregar_lock loads valid lock", {
  tmp <- file.path(tempdir(), "test_lock.json")
  on.exit(unlink(tmp))

  lock <- list(
    locked_at = "2026-01-01",
    vigiar_version = "0.7.0",
    n_tables = 2,
    tabelas = c("t1", "t2"),
    esquema = list(
      t1 = list(col1 = list(nome = "col1", tipo = "numeric")),
      t2 = list(col1 = list(nome = "x", tipo = "character"))
    )
  )
  jsonlite::write_json(lock, tmp, auto_unbox = TRUE, null = "null")
  loaded <- vigiar_esquema_carregar_lock(tmp)
  expect_equal(loaded$n_tables, 2)
  expect_equal(loaded$tabelas, c("t1", "t2"))
})

test_that("vigiar_esquema_verificar errors without session", {
  expect_error(vigiar_esquema_verificar(), "Nenhuma sessao")
})

# -- Export edge cases ---------------------------------------------------------

test_that("vigiar_exportar_log refuses to overwrite", {
  .vigiar_env$log <- list()
  .vigiar_log("INFO", "msg")
  tmp <- file.path(tempdir(), "log_ow.csv")
  on.exit(unlink(tmp))
  vigiar_exportar_log(tmp)
  expect_error(vigiar_exportar_log(tmp), "ja existe")
})

test_that("vigiar_salvar_snapshot refuses to overwrite", {
  dados <- data.frame(x = 1)
  snap <- vigiar_snapshot(dados = dados, tabela = "test")
  tmp <- file.path(tempdir(), "snap_ow.rds")
  on.exit(unlink(tmp))
  vigiar_salvar_snapshot(snap, tmp)
  expect_error(vigiar_salvar_snapshot(snap, tmp), "ja existe")
})

test_that("vigiar_salvar_snapshot adds .rds extension", {
  dados <- data.frame(x = 1)
  snap <- vigiar_snapshot(dados = dados, tabela = "test")
  tmp_noext <- file.path(tempdir(), "snap_noext")
  tmp_with <- paste0(tmp_noext, ".rds")
  on.exit(unlink(tmp_with))
  vigiar_salvar_snapshot(snap, tmp_noext)
  expect_true(file.exists(tmp_with))
})

test_that("vigiar_checksum is deterministic across calls", {
  set.seed(42)
  d1 <- data.frame(x = runif(100), y = sample(letters, 100, replace = TRUE))
  h1 <- vigiar_checksum(d1)
  h2 <- vigiar_checksum(d1)
  expect_equal(h1, h2)
})

# -- Edge cases: empty data ----------------------------------------------------

test_that("vigiar_auditar handles empty data frame", {
  dados <- data.frame(
    cod_municipio = integer(),
    sigla_uf = character(),
    ano = integer(),
    stringsAsFactors = FALSE
  )
  audit <- vigiar_auditar(dados, tabela = "test", verbose = FALSE)
  expect_s3_class(audit, "vigiar_audit")
})

test_that("vigiar_snapshot handles single row", {
  dados <- data.frame(x = 1)
  snap <- vigiar_snapshot(dados = dados, tabela = "test")
  expect_equal(snap$n_rows, 1)
})

test_that("vigiar_snapshot handles many columns", {
  n <- 50
  dados <- as.data.frame(matrix(1:(3 * n), nrow = 3))
  names(dados) <- paste0("col", seq_len(n))
  snap <- vigiar_snapshot(dados = dados, tabela = "test")
  expect_equal(snap$n_cols, n)
})

# -- Profile-specific compliance -----------------------------------------------

test_that("vigiar_compliance_check profile 'basico' works", {
  dados <- data.frame(cod_municipio = 355030L, ano = 2022L)
  result <- vigiar_compliance_check(dados, tabela = "test", profiles = "basico",
                                     verbose = FALSE)
  expect_true(isTRUE(result$basico$ok))
})

test_that("vigiar_compliance_check 'all' runs everything", {
  dados <- data.frame(cod_municipio = 355030L, sigla_uf = "SP", ano = 2022L)
  result <- vigiar_compliance_check(dados, tabela = "test", profiles = "all",
                                     verbose = FALSE)
  expect_true("basico" %in% names(result))
  expect_true("rigoroso" %in% names(result))
  expect_true("rj" %in% names(result))
  expect_true("corrupcao" %in% names(result))
})

test_that("vigiar_compliance_check invalid profile errors", {
  dados <- data.frame(x = 1)
  expect_error(
    vigiar_compliance_check(dados, tabela = "test", profiles = "invalido"),
    "arg"
  )
})

# -- Log metadata round-trip ---------------------------------------------------

test_that(".vigiar_log metadata is preserved in log", {
  .vigiar_env$log <- list()
  .vigiar_log("INFO", "Test with meta", table = "test",
              metadata = list(key1 = "val1", key2 = 42))
  df <- vigiar_log()
  expect_equal(nrow(df), 1)
  meta_json <- df$metadata_json[1]
  meta <- jsonlite::fromJSON(meta_json)
  expect_equal(meta$key1, "val1")
  expect_equal(meta$key2, 42)
})
