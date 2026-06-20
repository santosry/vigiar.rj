# Package: vigiar
# User-facing download and inspection functions

#' List available tables
#'
#' @return Character vector of table names.
#' @export
vigiar_tabelas <- function() {
  if (is.null(.vigiar_env$esquema)) {
    stop("Nenhuma sessao ativa. Execute vigiar_conectar() primeiro.")
  }
  names(.vigiar_env$esquema)
}

#' Display table schema
#'
#' Shows column names and R types for one or all tables.
#'
#' @param tabela Table name (optional). If `NULL`, lists all tables.
#' @return Invisibly, the schema list.
#' @export
vigiar_esquema <- function(tabela = NULL) {
  if (is.null(.vigiar_env$esquema)) {
    stop("Nenhuma sessao ativa. Execute vigiar_conectar() primeiro.")
  }

  if (!is.null(tabela)) {
    .vigiar_check_tabela(tabela)
    cat(sprintf("\n=== Tabela: %s ===\n", tabela))
    col_info <- .vigiar_env$esquema[[tabela]]
    df <- data.frame(
      coluna = names(col_info),
      tipo   = vapply(col_info, `[[`, "", "tipo", USE.NAMES = FALSE),
      stringsAsFactors = FALSE
    )
    print(df, row.names = FALSE)
    return(invisible(col_info))
  }

  for (tab in names(.vigiar_env$esquema)) {
    n <- length(.vigiar_env$esquema[[tab]])
    cat(sprintf("%-42s %3d colunas\n", tab, n))
  }
  invisible(.vigiar_env$esquema)
}

#' Download data from a single table
#'
#' @param tabela Table name (use `vigiar_tabelas()` to list).
#' @param colunas Optional character vector of column names. `NULL` = all.
#' @param ordenar_por Column to sort by (optional).
#' @param limite Maximum number of rows (optional).
#' @param timeout Timeout in seconds for the HTTP request.
#' @return A [tibble::tibble()] with the downloaded data.
#' @export
vigiar_baixar <- function(tabela, colunas = NULL, ordenar_por = NULL,
                           limite = NULL, timeout = 120, uf = NULL) {
  if (is.null(.vigiar_env$sessao)) {
    stop("Nenhuma sessao ativa. Execute vigiar_conectar() primeiro.")
  }
  .vigiar_check_tabela(tabela)

  message(sprintf("Baixando tabela '%s'...", tabela))

  query <- .vigiar_construir_query(
    tabela      = tabela,
    colunas     = colunas,
    ordenar_por = ordenar_por,
    limite      = limite,
    modelo_id   = .vigiar_env$sessao$model_id
  )

  resposta <- .vigiar_executar_query(
    .vigiar_env$sessao, query, timeout = timeout
  )
  dados <- .vigiar_parse_dados(resposta, tabela)

  # Client-side UF filter
  if (!is.null(uf)) {
    col_uf <- intersect(c("UF", "sigla_uf", "UF_SIGLA"), names(dados))[1]
    if (!is.na(col_uf)) {
      dados <- dados[dados[[col_uf]] == uf, ]
      message(sprintf("  Filtrado para UF='%s': %d linhas.", uf, nrow(dados)))
    }
  }

  # Warn if data might be truncated by API limit
  if (is.null(limite) && nrow(dados) >= 29000) {
    warning(
      "A API do Power BI limitou a resposta a ", nrow(dados), " linhas. ",
      "Para tabelas grandes (df_anual, df_mensal), os dados podem estar ",
      "incompletos."
    )
  }

  message(sprintf(
    "Tabela '%s' baixada: %d linhas x %d colunas.",
    tabela, nrow(dados), ncol(dados)
  ))

  tibble::as_tibble(dados)
}

#' Download multiple tables
#'
#' @param tabelas Character vector of table names. `NULL` = all.
#' @param progress Show progress messages.
#' @param delay Seconds to wait between downloads (rate limiting). Default 0.5.
#' @return Named list of tibbles.
#' @export
vigiar_baixar_tudo <- function(tabelas = NULL, progress = TRUE, delay = 0.5) {
  if (is.null(.vigiar_env$sessao)) {
    stop("Nenhuma sessao ativa. Execute vigiar_conectar() primeiro.")
  }

  if (is.null(tabelas)) {
    tabelas <- names(.vigiar_env$esquema)
  } else {
    invalidas <- setdiff(tabelas, names(.vigiar_env$esquema))
    if (length(invalidas) > 0) {
      warning(
        "Tabelas nao encontradas: ",
        paste(invalidas, collapse = ", ")
      )
      tabelas <- intersect(tabelas, names(.vigiar_env$esquema))
    }
  }

  resultado <- vector("list", length(tabelas))
  names(resultado) <- tabelas

  for (i in seq_along(tabelas)) {
    tab <- tabelas[[i]]
    if (progress) {
      message(sprintf("[%d/%d] Baixando '%s'...", i, length(tabelas), tab))
    }
    resultado[[tab]] <- tryCatch(
      vigiar_baixar(tab),
      error = function(e) {
        warning(sprintf("Erro ao baixar '%s': %s", tab, e$message))
        NULL
      }
    )
    if (delay > 0 && i < length(tabelas)) Sys.sleep(delay)
  }

  n_ok <- sum(!vapply(resultado, is.null, logical(1)))
  message(sprintf(
    "Download concluido: %d/%d tabelas baixadas com sucesso.",
    n_ok, length(tabelas)
  ))

  resultado
}

#' Download main tables (convenience shortcut)
#'
#' Downloads 14 key tables covering all data categories.
#'
#' @return Named list of tibbles.
#' @export
vigiar_baixar_principais <- function() {
  principais <- c(
    "df_anual", "df_mensal", "df_muni", "pop",
    "tb_brasil", "tb_uf", "tb_muni",
    "df_indoor", "df_indoor_desfecho",
    "df_dias", "df_dias_conama",
    "tb_fracao", "tb_quartis", "medidas"
  )
  disponiveis <- intersect(principais, names(.vigiar_env$esquema))
  vigiar_baixar_tudo(disponiveis, progress = TRUE)
}

#' Table catalogue with descriptions
#'
#' Returns a tibble with all tables, column counts, descriptions,
#' and thematic categories.
#'
#' @return A tibble with columns: `tabela`, `colunas`, `descricao`, `categoria`.
#' @export
vigiar_info <- function() {
  if (is.null(.vigiar_env$esquema)) {
    stop("Nenhuma sessao ativa. Execute vigiar_conectar() primeiro.")
  }

  catalogo <- .vigiar_catalogo()
  tabelas  <- names(.vigiar_env$esquema)
  n_cols   <- vapply(.vigiar_env$esquema, length, integer(1))

  result <- data.frame(
    tabela  = tabelas,
    colunas = n_cols,
    stringsAsFactors = FALSE
  )

  idx <- match(tabelas, catalogo$tabela)
  result$descricao <- catalogo$descricao[idx]
  result$categoria <- catalogo$categoria[idx]

  result$descricao[is.na(result$descricao)] <- "Tabela auxiliar do dashboard"
  result$categoria[is.na(result$categoria)] <- "Auxiliar"

  tibble::as_tibble(result)[
    order(result$categoria, result$tabela),
  ]
}

#' Validate downloaded data
#'
#' Performs basic sanity checks on a downloaded table:
#' reports missing values, duplicate rows, and type consistency.
#'
#' @param dados A data frame (or tibble) returned by `vigiar_baixar()`.
#' @param tabela Table name (for messages).
#' @return Invisibly, a list of diagnostics.
#' @export
vigiar_checar_dados <- function(dados, tabela = NULL) {
  checks <- list()

  checks$n_rows <- nrow(dados)
  checks$n_cols <- ncol(dados)
  checks$col_names <- names(dados)

  # Missing values
  na_count <- vapply(dados, function(x) sum(is.na(x)), integer(1))
  checks$na_per_column <- na_count

  # Duplicate rows
  checks$duplicated_rows <- sum(duplicated(dados))

  # Empty
  checks$is_empty <- nrow(dados) == 0

  if (!is.null(tabela)) {
    cat(sprintf("\nDiagnostico: %s\n", tabela))
    cat(strrep("-", 40), "\n")
  }
  cat(sprintf("Linhas:  %d\n", checks$n_rows))
  cat(sprintf("Colunas: %d\n", checks$n_cols))
  cat(sprintf("Linhas duplicadas: %d\n", checks$duplicated_rows))

  if (any(na_count > 0)) {
    cat("\nValores ausentes por coluna:\n")
    na_info <- na_count[na_count > 0]
    for (nm in names(na_info)) {
      cat(sprintf("  %-30s %d (%.1f%%)\n",
                  nm, na_info[[nm]],
                  100 * na_info[[nm]] / checks$n_rows))
    }
  } else {
    cat("Valores ausentes: 0\n")
  }

  invisible(checks)
}

#' Diagnostic summary of all downloaded tables
#'
#' Downloads a small sample from every table and reports basic
#' diagnostics to detect schema changes or data issues.
#'
#' @param amostra Number of rows to sample per table.
#' @return Invisibly, a list of diagnostics per table.
#' @export
vigiar_diagnostico <- function(amostra = 100) {
  if (is.null(.vigiar_env$sessao)) {
    stop("Nenhuma sessao ativa. Execute vigiar_conectar() primeiro.")
  }

  tabelas <- names(.vigiar_env$esquema)
  resultados <- vector("list", length(tabelas))
  names(resultados) <- tabelas

  for (tab in tabelas) {
    message(sprintf("Amostrando '%s' (%d linhas)...", tab, amostra))
    resultados[[tab]] <- tryCatch({
      dados <- vigiar_baixar(tab, limite = amostra)
      vigiar_checar_dados(dados, tabela = tab)
    }, error = function(e) {
      warning(sprintf("Falha em '%s': %s", tab, e$message))
      list(error = e$message)
    })
  }

  invisible(resultados)
}

# -- Internal helpers ----------------------------------------------------------

.vigiar_check_tabela <- function(tabela) {
  if (!tabela %in% names(.vigiar_env$esquema)) {
    stop(
      sprintf("Tabela '%s' nao encontrada.", tabela),
      " Use vigiar_tabelas() para ver as disponiveis."
    )
  }
}

.vigiar_catalogo <- function() {
  data.frame(
    tabela = c(
      "df_anual", "df_mensal", "df_dias", "df_dias_conama",
      "pop", "df_muni", "df_mes", "df_ano",
      "tb_brasil", "tb_uf", "tb_muni", "tb_fracao", "tb_quartis",
      "df_indoor", "df_indoor_desfecho",
      "medidas",
      "legenda", "legenda_conama", "legenda_quartis", "legenda_indoor",
      "Ano", "Selecao", "referencia", "referencia_conama",
      "seletor_indicador",
      "aux_uf", "dados_ate", "last_update", "att_em"
    ),
    descricao = c(
      "Medias anuais PM2.5 por municipio",
      "Medias mensais PM2.5 por municipio (com LAT/LON)",
      "Dias acima do limite OMS (PM2.5 > 15 ug/m3)",
      "Dias acima do limite CONAMA (PM2.5 > 50 ug/m3)",
      "Populacao residente por municipio, ano e categoria de exposicao",
      "Cadastro de municipios: regiao, UF, coordenadas, nomes",
      "Tabela auxiliar: meses (numero -> nome)",
      "Anos disponiveis na base",
      "Indicadores de saude agregados -- BRASIL",
      "Indicadores de saude agregados -- UF",
      "Indicadores de saude por MUNICIPIO (com codigo IBGE, lat, long)",
      "Fracao atribuivel por indicador e desfecho",
      "Quartis dos indicadores (q1, q2, q3)",
      "Exposicao a combustiveis solidos em domicilios (indoor)",
      "Desfechos de saude associados a poluicao indoor",
      "Medidas calculadas: rankings, medias, alertas, proporcoes (61 colunas)",
      "Legenda de cores PM2.5 (OMS)",
      "Legenda de cores PM2.5 (CONAMA)",
      "Legenda de cores para quartis",
      "Legenda de cores para exposicao indoor",
      "Seletor de ano (filtro do dashboard)",
      "Seletor de categoria (filtro do dashboard)",
      "Valores de referencia OMS",
      "Valores de referencia CONAMA",
      "Seletor de indicador de saude",
      "Codigo UF -> nome",
      "Data dos ultimos dados disponiveis",
      "Ultima atualizacao do banco",
      "Timestamp de atualizacao"
    ),
    categoria = c(
      "Qualidade do Ar", "Qualidade do Ar", "Qualidade do Ar", "Qualidade do Ar",
      "Populacao", "Cadastro", "Auxiliar", "Auxiliar",
      "Indicadores de Saude", "Indicadores de Saude", "Indicadores de Saude",
      "Indicadores de Saude", "Indicadores de Saude",
      "Exposicao Indoor", "Exposicao Indoor",
      "Medidas",
      "Auxiliar", "Auxiliar", "Auxiliar", "Auxiliar",
      "Filtros", "Filtros", "Filtros", "Filtros", "Filtros",
      "Auxiliar", "Metadados", "Metadados", "Metadados"
    ),
    stringsAsFactors = FALSE
  )
}
