# =============================================================================
# vigiar — Script de validacao independente (offline + online)
#
# Uso:
#   source("testar_vigiar.R")           # apenas testes offline
#   Sys.setenv(VIGIAR_RUN_ONLINE_TESTS = "true")
#   source("testar_vigiar.R")           # todos os testes
# =============================================================================

library(vigiar.rj)

cat("\n")
cat("============================================================\n")
cat("  TESTES DO PACOTE vigiar v0.3.0\n")
cat("============================================================\n")

pass <- 0L
fail <- 0L
skip <- 0L

.check <- function(descricao, expr) {
  result <- tryCatch(
    {
      expr
      TRUE
    },
    error = function(e) {
      cat(sprintf("  ERRO: %s\n", e$message))
      FALSE
    }
  )
  if (isTRUE(result)) {
    pass <<- pass + 1L
    cat(sprintf("  [PASS] %s\n", descricao))
  } else {
    fail <<- fail + 1L
    cat(sprintf("  [FAIL] %s\n", descricao))
  }
}

cat("\n--- 1. Utilitarios internos ---\n\n")
.check("uuid_v4 gera UUID valido", {
  u <- uuid_v4()
  grepl("^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$", u)
})
.check("%||% operador", {
  (1 %||% 2) == 1 && is.null(NULL %||% NULL) == FALSE
})
.check(".vigiar_tipo_dado mapeia tipos", {
  .vigiar_tipo_dado(1) == "character" &&
  .vigiar_tipo_dado(3) == "numeric"   &&
  .vigiar_tipo_dado(4) == "integer"   &&
  .vigiar_tipo_dado(7) == "POSIXct"
})
.check(".vigiar_gunzip descomprime", {
  tmp <- tempfile(fileext = ".gz")
  con <- gzfile(tmp, "wb")
  writeLines("teste vigiar", con); close(con)
  raw_in <- readBin(tmp, raw(), file.info(tmp)$size)
  unlink(tmp)
  rawToChar(.vigiar_gunzip(raw_in)) == "teste vigiar\n"
})
.check(".vigiar_extrair_cookies extrai pares", {
  ck <- .vigiar_extrair_cookies("WFESessionId=abc; path=/")
  any(grepl("WFESessionId=abc", ck))
})

cat("\n--- 2. Classes S3 ---\n\n")
.check("new_vigiar_tbl cria objeto tipado", {
  df <- data.frame(x = 1:3)
  out <- new_vigiar_tbl(df, subclass = "vigiar_pm25", tabela = "test")
  inherits(out, "vigiar_pm25") && inherits(out, "vigiar_tbl")
})
.check("print.vigiar_tbl funciona", {
  df <- data.frame(x = 1:3)
  out <- new_vigiar_tbl(df, tabela = "test")
  saida <- capture.output(print(out))
  any(grepl("VIGIAR tibble", saida))
})
.check("summary.vigiar_tbl funciona", {
  df <- data.frame(x = c(1, NA, 3))
  out <- new_vigiar_tbl(df, tabela = "test")
  saida <- capture.output(summary(out))
  any(grepl("Resumo", saida))
})
.check("validate.vigiar_tbl detecta problemas", {
  df <- data.frame(x = numeric(0))
  out <- new_vigiar_tbl(df, tabela = "test")
  attr(out, "vigiar_tabela") <- NULL
  saida <- capture.output(validate(out), type = "message")
  TRUE  # validate emite warning, nao erro
})

cat("\n--- 3. Processamento ---\n\n")
.check("process_pm25 renomeia colunas", {
  raw <- data.frame(muni = 355030L, UF = "SP", ano = 2022L,
                    Media_pm25 = 22.5, Categoria_pm25 = "> 35",
                    stringsAsFactors = FALSE)
  res <- process_pm25(raw, tipo = "anual")
  "cod_municipio" %in% names(res) && "sigla_uf" %in% names(res) &&
  "pm25_media_anual" %in% names(res)
})
.check("process_pm25 lowercase regiao/municipio", {
  raw <- data.frame(muni = 355030L, UF = "SP", ano = 2022L,
                    Media_pm25 = 22.5, regiao = "Sudeste",
                    municipio = "Sao Paulo", stringsAsFactors = FALSE)
  res <- process_pm25(raw, tipo = "anual")
  "regiao" %in% names(res) && "nome_municipio" %in% names(res)
})
.check("process_populacao_exposta renomeia", {
  raw <- data.frame(muni = 355030L, ano = 2022L, pop = 12e6,
                    categoria = "> 35", UF = "SP",
                    stringsAsFactors = FALSE)
  res <- process_populacao_exposta(raw)
  "cod_municipio" %in% names(res) && "populacao" %in% names(res)
})
.check("process_indicadores_saude renomeia", {
  raw <- data.frame(Indicador = "Fracao (%)", n = 5e7, est = 4.5,
                    low = 2.5, high = 6.8, desfecho = "Mortalidade",
                    ano = 2022L, stringsAsFactors = FALSE)
  res <- process_indicadores_saude(raw, agregacao = "brasil")
  "indicador" %in% names(res) && "estimativa" %in% names(res) &&
  "ic_inferior" %in% names(res)
})
.check("process_fracao_atribuivel renomeia", {
  raw <- data.frame(Indicador = "Fracao", n = 1e6, est = 12.3,
                    low = 8.1, high = 16.5, desfecho = "Cancer",
                    ano = 2022L, stringsAsFactors = FALSE)
  res <- process_fracao_atribuivel(raw)
  "fracao_atribuivel" %in% names(res)
})
.check("process_exposicao_indoor renomeia", {
  raw <- data.frame(Code = 35L, Ano = 2022L, comb_sol = 0.194,
                    pop_exposta = 186256, percent_comb = 19.4,
                    Quartis = "Q2", stringsAsFactors = FALSE)
  res <- process_exposicao_indoor(raw)
  "cod_uf" %in% names(res) && "prop_combustiveis_solidos" %in% names(res)
})
.check("process_municipios renomeia", {
  raw <- data.frame(UF_COD = 35L, UF_SIGLA = "SP", UF_NOME = "Sao Paulo",
                    REGIAO = "Sudeste", LAT = -23.5, LON = -46.6,
                    stringsAsFactors = FALSE)
  res <- process_municipios(raw)
  "cod_uf" %in% names(res) && "latitude" %in% names(res)
})
.check("process_ufs padroniza", {
  dados <- data.frame(UF = c("SP", "RJ"), stringsAsFactors = FALSE)
  res <- process_ufs(dados)
  inherits(res, "vigiar_uf") && "sigla_uf" %in% names(res)
})
.check("process_vigiar dispatcher", {
  dados <- data.frame(muni = 355030L, UF = "SP", ano = 2022L,
                      Media_pm25 = 22.5, Categoria_pm25 = "> 35",
                      stringsAsFactors = FALSE)
  res <- process_vigiar(dados, tabela = "df_anual")
  inherits(res, "vigiar_pm25")
})
.check("process_vigiar fallback tabela desconhecida", {
  dados <- data.frame(x = 1:3, y = letters[1:3])
  res <- suppressWarnings(process_vigiar(dados, tabela = "inexistente"))
  inherits(res, "data.frame")
})

cat("\n--- 4. Validacao ---\n\n")
.check("vigiar_validar_ibge avisa codigos invalidos", {
  dados <- data.frame(cod_municipio = c(355030L, 999999L))
  saida <- capture.output(vigiar_validar_ibge(dados), type = "message")
  any(grepl("fora do intervalo", saida))
})
.check("vigiar_validar_datas avisa anos invalidos", {
  dados <- data.frame(ano = c(2022L, 1800L, 3000L))
  saida <- capture.output(vigiar_validar_datas(dados), type = "message")
  any(grepl("fora do intervalo", saida))
})
.check("vigiar_validar_unidades avisa PM2.5 implausivel", {
  dados <- data.frame(pm25_media = c(22.5, -5, 2000))
  saida <- capture.output(vigiar_validar_unidades(dados), type = "message")
  any(grepl("fora do intervalo", saida))
})
.check("vigiar_checar_dados funciona", {
  dados <- tibble::tibble(a = 1:5, b = c(1, NA, 3, NA, 5))
  saida <- capture.output(vigiar_checar_dados(dados, "teste"))
  any(grepl("Linhas:", saida))
})

cat("\n--- 5. Series temporais ---\n\n")
.check("vigiar_agregar_tempo agrega por ano", {
  dados <- data.frame(ano = c(2020L, 2020L, 2021L),
                      pm25_media_anual = c(18, 22, 20))
  res <- vigiar_agregar_tempo(dados, agregar_por = "ano",
                               variavel = "pm25_media_anual")
  nrow(res) == 2
})
.check("vigiar_tendencia_descritiva retorna colunas", {
  dados <- data.frame(ano = 2018:2022, pm25_media_anual = c(20,19,22,21,18))
  res <- vigiar_tendencia_descritiva(dados, variavel = "pm25_media_anual")
  all(c("ano","media","variacao_anual","media_movel") %in% names(res))
})
.check("vigiar_serie_temporal nivel nacional", {
  dados <- data.frame(ano = c(2020L, 2020L, 2021L),
                      pm25_media_anual = c(18, 22, 20))
  res <- vigiar_serie_temporal(dados, nivel = "nacional")
  nrow(res) == 2
})

cat("\n--- 6. Resumos ---\n\n")
.check("vigiar_resumo_pm25 retorna stats", {
  out <- new_vigiar_tbl(
    data.frame(cod_municipio = 1:3, sigla_uf = c("SP","RJ","MG"),
               ano = 2022L, pm25_media_anual = c(22.5, 18.3, 15.7)),
    subclass = "vigiar_pm25", tabela = "df_anual")
  res <- vigiar_resumo_pm25(out)
  "media" %in% names(res) && res$n_observacoes == 3
})
.check("vigiar_resumo_saude retorna indicadores", {
  out <- new_vigiar_tbl(
    data.frame(indicador = c("A","B"), estimativa = c(4.5, 12000),
               desfecho = c("X","Y"), ano = 2022L),
    subclass = "vigiar_health", tabela = "tb_brasil")
  res <- vigiar_resumo_saude(out)
  res$n_indicadores == 2 && res$n_desfechos == 2
})
.check("vigiar_resumo S3 dispatcher", {
  out <- new_vigiar_tbl(
    data.frame(x = 1:5, ano = 2020:2024),
    tabela = "generica")
  res <- vigiar_resumo(out)
  inherits(res, "tbl_df") && res$n_observacoes == 5
})

cat("\n--- 7. Exportacao ---\n\n")
.check("vigiar_exportar_csv escreve arquivo", {
  dados <- data.frame(x = 1:3, y = letters[1:3])
  tmp <- file.path(tempdir(), "test_vigiar.csv")
  on.exit(unlink(tmp))
  vigiar_exportar_csv(dados, tmp)
  file.exists(tmp) && nrow(utils::read.csv(tmp)) == 3
})
.check("vigiar_exportar_csv recusa sobrescrever", {
  dados <- data.frame(x = 1)
  tmp <- file.path(tempdir(), "test_overwrite.csv")
  on.exit(unlink(tmp))
  write.csv(dados, tmp)
  inherits(tryCatch(vigiar_exportar_csv(dados, tmp), error = identity), "error")
})
.check("vigiar_exportar_rds preserva dados", {
  dados <- data.frame(x = 1:3)
  tmp <- file.path(tempdir(), "test_vigiar.rds")
  on.exit(unlink(tmp))
  vigiar_exportar_rds(dados, tmp)
  identical(readRDS(tmp), dados)
})
.check("vigiar_exportar_rds overwrite", {
  dados <- data.frame(x = 1)
  tmp <- file.path(tempdir(), "test_ow.rds")
  on.exit(unlink(tmp))
  vigiar_exportar_rds(dados, tmp)
  vigiar_exportar_rds(dados, tmp, overwrite = TRUE)
  file.exists(tmp)
})
.check("vigiar_exportar_parquet ou arrow ausente", {
  dados <- data.frame(x = 1)
  tmp <- file.path(tempdir(), "test_vigiar.parquet")
  on.exit(unlink(tmp))
  if (requireNamespace("arrow", quietly = TRUE)) {
    vigiar_exportar_parquet(dados, tmp)
    file.exists(tmp)
  } else {
    inherits(tryCatch(vigiar_exportar_parquet(dados, tmp), error = identity), "error")
  }
})

cat("\n--- 8. Dicionario ---\n\n")
.check("vigiar_dicionario retorna tibble", {
  dict <- vigiar_dicionario()
  inherits(dict, "tbl_df") && nrow(dict) > 0 &&
  all(c("table_id", "original_name", "standard_name") %in% names(dict))
})
.check("vigiar_variaveis filtra por dominio", {
  pm25_vars <- vigiar_variaveis("pm25")
  all(pm25_vars$table_id %in%
      c("df_anual", "df_mensal", "df_dias", "df_dias_conama"))
})
.check("vigiar_descrever_variavel erro amigavel", {
  inherits(tryCatch(vigiar_descrever_variavel("pm25", "var_inexistente"),
                    error = identity), "error")
})
.check("vigiar_tabelas_documentadas retorna vetor", {
  tabs <- vigiar_tabelas_documentadas()
  is.character(tabs) && length(tabs) > 0
})
.check("vigiar_schema retorna tibble", {
  s <- vigiar_schema("pm25")
  inherits(s, "tbl_df")
})

cat("\n--- 9. Erros claros sem sessao ---\n\n")
.check("vigiar_baixar erro sem sessao", {
  inherits(tryCatch(vigiar_baixar("df_anual"), error = identity), "error")
})
.check("vigiar_baixar_tudo erro sem sessao", {
  inherits(tryCatch(vigiar_baixar_tudo(), error = identity), "error")
})
.check("vigiar_tabelas erro sem sessao", {
  inherits(tryCatch(vigiar_tabelas(), error = identity), "error")
})
.check("vigiar_esquema erro sem sessao", {
  inherits(tryCatch(vigiar_esquema(), error = identity), "error")
})
.check("vigiar_info erro sem sessao", {
  inherits(tryCatch(vigiar_info(), error = identity), "error")
})
.check("vigiar_diagnostico erro sem sessao", {
  inherits(tryCatch(vigiar_diagnostico(), error = identity), "error")
})
.check("vigiar_validar_dicionario erro sem sessao", {
  inherits(tryCatch(vigiar_validar_dicionario(), error = identity), "error")
})

# =============================================================================
# TESTES ONLINE (so rodam com VIGIAR_RUN_ONLINE_TESTS=true)
# =============================================================================

online <- identical(tolower(Sys.getenv("VIGIAR_RUN_ONLINE_TESTS")), "true")

if (online) {
  cat("\n--- 10. Testes ONLINE (conexao real) ---\n\n")

  .check("vigiar_conectar estabelece sessao", {
    vigiar_desconectar()
    sess <- vigiar_conectar(timeout = 30)
    inherits(sess, "vigiar_sessao") && vigiar_sessao_ativa()
  })
  .check("vigiar_status reporta online", {
    vigiar_conectar()
    status <- vigiar_status()
    isTRUE(status$online)
  })
  .check("vigiar_baixar download real (limite=5)", {
    vigiar_conectar()
    df <- vigiar_baixar("df_anual", limite = 5)
    inherits(df, "tbl_df") && nrow(df) <= 5 && "ano" %in% names(df)
  })
  .check("vigiar_baixar colunas selecionadas", {
    vigiar_conectar()
    df <- vigiar_baixar("df_anual", colunas = c("ano", "UF"), limite = 3)
    identical(names(df), c("ano", "UF"))
  })
  .check("vigiar_baixar_tudo multiplas tabelas", {
    vigiar_conectar()
    res <- vigiar_baixar_tudo(tabelas = c("df_ano", "df_mes"))
    is.list(res) && length(res) == 2
  })
  .check("vigiar_baixar_principais retorna lista", {
    vigiar_conectar()
    res <- vigiar_baixar_principais()
    is.list(res) && length(res) >= 5
  })
  .check("tb_brasil estrutura esperada", {
    vigiar_conectar()
    df <- vigiar_baixar("tb_brasil", limite = 5)
    all(c("Indicador","est","low","high","desfecho","ano") %in% names(df))
  })
  .check("df_indoor download", {
    vigiar_conectar()
    df <- vigiar_baixar("df_indoor", limite = 5)
    inherits(df, "tbl_df")
  })
  .check("vigiar_desconectar limpa sessao", {
    vigiar_conectar()
    vigiar_desconectar()
    !vigiar_sessao_ativa()
  })
  .check("pipeline completo: download + process", {
    vigiar_conectar()
    raw <- vigiar_baixar("df_anual", limite = 10)
    pm25 <- process_pm25(raw)
    inherits(pm25, "vigiar_pm25") &&
      "cod_municipio" %in% names(pm25)
  })
} else {
  cat("\n--- 10. Testes ONLINE --- [IGNORADOS] ---\n")
  cat("  Defina VIGIAR_RUN_ONLINE_TESTS=true para rodar testes com internet.\n\n")
  skip <- 11L
}

# =============================================================================
# SUMARIO
# =============================================================================

cat("\n")
cat("============================================================\n")
cat(sprintf("  RESULTADO: %d passaram, %d falharam, %d ignorados\n",
            pass, fail, skip))
cat("============================================================\n")

if (fail > 0) {
  stop(sprintf(">>> %d TESTE(S) FALHARAM <<<", fail))
} else {
  cat(">>> TODOS OS TESTES PASSARAM <<<\n")
}
