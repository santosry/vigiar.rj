# Package: vigiar
# User‑facing download and inspection functions

#' List available tables
#'
#' @return Character vector of table names.
#' @export
vigiar_tabelas <- function() {
  if (is.null(.vigiar_env$esquema)) {
    stop("Nenhuma sessão ativa. Execute vigiar_conectar() primeiro.")
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
    stop("Nenhuma sessão ativa. Execute vigiar_conectar() primeiro.")
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
                           limite = NULL, timeout = 120) {
  if (is.null(.vigiar_env$sessao)) {
    stop("Nenhuma sessão ativa. Execute vigiar_conectar() primeiro.")
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
#' @return Named list of tibbles.
#' @export
vigiar_baixar_tudo <- function(tabelas = NULL, progress = TRUE) {
  if (is.null(.vigiar_env$sessao)) {
    stop("Nenhuma sessão ativa. Execute vigiar_conectar() primeiro.")
  }

  if (is.null(tabelas)) {
    tabelas <- names(.vigiar_env$esquema)
  } else {
    invalidas <- setdiff(tabelas, names(.vigiar_env$esquema))
    if (length(invalidas) > 0) {
      warning(
        "Tabelas não encontradas: ",
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
  }

  n_ok <- sum(!vapply(resultado, is.null, logical(1)))
  message(sprintf(
    "Download concluído: %d/%d tabelas baixadas com sucesso.",
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
    stop("Nenhuma sessão ativa. Execute vigiar_conectar() primeiro.")
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
    cat(sprintf("\nDiagnóstico: %s\n", tabela))
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
    stop("Nenhuma sessão ativa. Execute vigiar_conectar() primeiro.")
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

# ── Internal helpers ──────────────────────────────────────────────────────────

.vigiar_check_tabela <- function(tabela) {
  if (!tabela %in% names(.vigiar_env$esquema)) {
    stop(
      sprintf("Tabela '%s' não encontrada.", tabela),
      " Use vigiar_tabelas() para ver as disponíveis."
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
      "Médias anuais PM2.5 por município",
      "Médias mensais PM2.5 por município (com LAT/LON)",
      "Dias acima do limite OMS (PM2.5 > 15 µg/m³)",
      "Dias acima do limite CONAMA (PM2.5 > 50 µg/m³)",
      "População residente por município, ano e categoria de exposição",
      "Cadastro de municípios: região, UF, coordenadas, nomes",
      "Tabela auxiliar: meses (número → nome)",
      "Anos disponíveis na base",
      "Indicadores de saúde agregados — BRASIL",
      "Indicadores de saúde agregados — UF",
      "Indicadores de saúde por MUNICÍPIO (com código IBGE, lat, long)",
      "Fração atribuível por indicador e desfecho",
      "Quartis dos indicadores (q1, q2, q3)",
      "Exposição a combustíveis sólidos em domicílios (indoor)",
      "Desfechos de saúde associados à poluição indoor",
      "Medidas calculadas: rankings, médias, alertas, proporções (61 colunas)",
      "Legenda de cores PM2.5 (OMS)",
      "Legenda de cores PM2.5 (CONAMA)",
      "Legenda de cores para quartis",
      "Legenda de cores para exposição indoor",
      "Seletor de ano (filtro do dashboard)",
      "Seletor de categoria (filtro do dashboard)",
      "Valores de referência OMS",
      "Valores de referência CONAMA",
      "Seletor de indicador de saúde",
      "Código UF → nome",
      "Data dos últimos dados disponíveis",
      "Última atualização do banco",
      "Timestamp de atualização"
    ),
    categoria = c(
      "Qualidade do Ar", "Qualidade do Ar", "Qualidade do Ar", "Qualidade do Ar",
      "População", "Cadastro", "Auxiliar", "Auxiliar",
      "Indicadores de Saúde", "Indicadores de Saúde", "Indicadores de Saúde",
      "Indicadores de Saúde", "Indicadores de Saúde",
      "Exposição Indoor", "Exposição Indoor",
      "Medidas",
      "Auxiliar", "Auxiliar", "Auxiliar", "Auxiliar",
      "Filtros", "Filtros", "Filtros", "Filtros", "Filtros",
      "Auxiliar", "Metadados", "Metadados", "Metadados"
    ),
    stringsAsFactors = FALSE
  )
}
