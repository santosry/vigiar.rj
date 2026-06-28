# Package: vigiar
# Diagnostic functions for data quality assessment
#
# Implements a comprehensive diagnostic system that inspects
# temporal series of PM2.5 data and reports issues with severity
# levels: ok, aviso, problema, critico.
#
# Design principle: the package distrusts data before trusting it.

#' Diagnostic severity levels
#' @keywords internal
VIGIAR_SEVERITY_LEVELS <- c("ok" = 0, "aviso" = 1, "problema" = 2, "critico" = 3)

#' Create a diagnostic object
#' @param tabela Table name
#' @param dados Input data frame
#' @return A vigiar_diagnostic object
#' @keywords internal
new_vigiar_diagnostic <- function(tabela, dados) {
  structure(
    list(
      tabela       = tabela,
      timestamp    = Sys.time(),
      n_rows       = nrow(dados),
      n_cols       = ncol(dados),
      colunas      = names(dados),
      resultados   = list(),
      severidade   = "ok",
      mensagens    = character(0),
      metricas     = list(),
      recomendacoes = character(0)
    ),
    class = "vigiar_diagnostic"
  )
}

# ===============================================================================
# Main diagnostic function
# ===============================================================================

#' Diagnose a PM2.5 time series
#'
#' Comprehensive diagnostic of a VIGIAR PM2.5 temporal series.
#' Checks temporal coverage, spatial coverage, PM2.5 values,
#' IBGE codes, duplicates, series breaks, and outliers.
#' Returns a structured diagnostic object with severity levels.
#'
#' @param dados A data frame or tibble with PM2.5 data.
#'   Required columns: municipality code, year, PM2.5 value.
#'   Optional: month, health region, latitude, longitude.
#' @param col_muni Name of municipality code column (auto-detected).
#' @param col_ano Name of year column (default \code{"ano"}).
#' @param col_mes Name of month column (default \code{"mes"}).
#' @param col_pm25 Name of PM2.5 column (auto-detected).
#' @param uf Expected UF (default \code{"RJ"}). Use \code{NULL} for any.
#' @param escopo Scope for spatial checks: \code{"rj"}, \code{"uf"}, or \code{"nacional"}.
#' @return A \code{vigiar_diagnostic} object.
#' @export
vigiar_diagnosticar_serie <- function(dados,
                                       col_muni = NULL,
                                       col_ano = "ano",
                                       col_mes = "mes",
                                       col_pm25 = NULL,
                                       uf = "RJ",
                                       escopo = c("rj", "uf", "nacional")) {
  escopo <- match.arg(escopo)
  tabela <- attr(dados, "vigiar_tabela") %||% deparse(substitute(dados))
  diag <- new_vigiar_diagnostic(tabela, dados)

  # Auto-detect columns
  if (is.null(col_muni)) {
    col_muni <- intersect(c("cod_municipio", "muni", "ID_MUNI", "id_muni",
                            "codigo_ibge", "cod_ibge", "MUN_COD"), names(dados))[1]
  }
  if (is.null(col_pm25)) {
    col_pm25 <- intersect(c("pm25_media_anual", "pm25_media", "pm25",
                            "Media_pm25", "pm25_media_periodo"), names(dados))[1]
  }

  if (is.na(col_muni)) {
    diag <- .vigiar_add_issue(diag, "critico",
      "Coluna de codigo municipal nao encontrada. Verifique os nomes das colunas.")
    return(diag)
  }
  if (is.na(col_pm25)) {
    diag <- .vigiar_add_issue(diag, "critico",
      "Coluna de PM2.5 nao encontrada. Verifique os nomes das colunas.")
    return(diag)
  }

  # Store column mapping
  diag$col_muni <- col_muni
  diag$col_ano  <- col_ano
  diag$col_mes  <- col_mes
  diag$col_pm25 <- col_pm25

  # ---- 1. IBGE code validation ----
  diag <- vigiar_checar_ibge(diag, dados, col_muni, uf, escopo)

  # ---- 2. Temporal coverage ----
  diag <- vigiar_checar_cobertura_temporal(diag, dados, col_ano, col_mes)

  # ---- 3. Spatial coverage ----
  diag <- vigiar_checar_cobertura_espacial(diag, dados, col_muni, uf, escopo)

  # ---- 4. PM2.5 value validation ----
  diag <- vigiar_checar_pm25(diag, dados, col_pm25)

  # ---- 5. Duplicate detection ----
  diag <- vigiar_checar_duplicatas(diag, dados, col_muni, col_ano, col_mes)

  # ---- 6. Series break detection ----
  diag <- vigiar_checar_quebra_serie(diag, dados, col_muni, col_ano, col_pm25)

  # ---- 7. Classify alerts ----
  diag <- vigiar_classificar_alertas(diag)

  # ---- 8. Generate recommendations ----
  diag <- .vigiar_gerar_recomendacoes(diag)

  class(diag) <- "vigiar_diagnostic"
  diag
}

# ===============================================================================
# Individual check functions
# ===============================================================================

#' Check IBGE municipality codes
#'
#' Validates that municipality codes are within the valid Brazilian range
#' (110001-530010), flags non-RJ codes when scope is RJ, and reports
#' missing or invalid codes.
#'
#' @param diag A vigiar_diagnostic object (modified in place).
#' @param dados Data frame.
#' @param col_muni Municipality code column name.
#' @param uf Expected UF.
#' @param escopo Scope for checks.
#' @return The modified diagnostic object.
#' @export
vigiar_checar_ibge <- function(diag, dados, col_muni, uf = "RJ",
                                escopo = "rj") {
  if (!col_muni %in% names(dados)) {
    return(.vigiar_add_issue(diag, "critico",
      sprintf("Coluna '%s' nao encontrada nos dados.", col_muni)))
  }

  codigos <- as.integer(dados[[col_muni]])
  codigos <- codigos[!is.na(codigos)]
  n_total <- length(codigos)

  if (n_total == 0) {
    return(.vigiar_add_issue(diag, "critico",
      "Nenhum codigo IBGE valido encontrado (todos NA)."))
  }

  # Valid range check
  invalidos <- codigos[codigos < 110001 | codigos > 530010]
  n_invalid <- length(invalidos)

  if (n_invalid > 0) {
    diag <- .vigiar_add_issue(diag, "critico",
      sprintf("%d codigos IBGE fora do intervalo esperado (110001-530010): %s",
              n_invalid, paste(utils::head(invalidos, 10), collapse = ", ")))
  }

  # NA check
  n_na <- sum(is.na(dados[[col_muni]]))
  if (n_na > 0) {
    pct <- round(100 * n_na / nrow(dados), 1)
    if (pct > 50) {
      diag <- .vigiar_add_issue(diag, "problema",
        sprintf("%d (%.1f%%) codigos IBGE ausentes.", n_na, pct))
    } else if (pct > 0) {
      diag <- .vigiar_add_issue(diag, "aviso",
        sprintf("%d (%.1f%%) codigos IBGE ausentes.", n_na, pct))
    }
  }

  # RJ check
  if (!is.null(uf) && toupper(uf) == "RJ" && escopo == "rj") {
    rj_codes <- RJ_MUNICIPIOS$codigo_ibge
    fora_rj <- setdiff(unique(codigos), rj_codes)
    if (length(fora_rj) > 0) {
      diag <- .vigiar_add_issue(diag, "problema",
        sprintf("%d codigos nao pertencem ao RJ: %s",
                length(fora_rj), paste(utils::head(fora_rj, 10), collapse = ", ")))
    }
  }

  diag$metricas$n_ibge_validos <- n_total - n_invalid
  diag$metricas$n_ibge_invalidos <- n_invalid
  diag$metricas$n_ibge_ausentes <- n_na

  if (n_invalid == 0 && n_na == 0) {
    .vigiar_add_issue(diag, "ok", sprintf("IBGE: %d codigos validos.", n_total))
  }

  diag
}

#' Check temporal coverage
#'
#' Detects missing months, incomplete years, and dates outside
#' the expected range (2000 to current year).
#'
#' @param diag A vigiar_diagnostic object.
#' @param dados Data frame.
#' @param col_ano Year column name.
#' @param col_mes Month column name (optional).
#' @return The modified diagnostic object.
#' @export
vigiar_checar_cobertura_temporal <- function(diag, dados,
                                              col_ano = "ano",
                                              col_mes = "mes") {
  current_year <- as.integer(format(Sys.Date(), "%Y"))

  if (!col_ano %in% names(dados)) {
    return(.vigiar_add_issue(diag, "critico",
      sprintf("Coluna '%s' nao encontrada.", col_ano)))
  }

  anos <- as.integer(dados[[col_ano]])
  anos <- anos[!is.na(anos)]

  if (length(anos) == 0) {
    return(.vigiar_add_issue(diag, "critico", "Nenhum ano valido encontrado."))
  }

  # Year range check
  anos_fora <- anos[anos < 2000 | anos > current_year]
  if (length(anos_fora) > 0) {
    diag <- .vigiar_add_issue(diag, "problema",
      sprintf("%d anos fora de 2000-%d: %s",
              length(anos_fora), current_year,
              paste(utils::head(unique(anos_fora), 5), collapse = ", ")))
  }

  anos_unicos <- sort(unique(anos))
  ano_min <- min(anos_unicos)
  ano_max <- max(anos_unicos)
  diag$metricas$ano_min <- ano_min
  diag$metricas$ano_max <- ano_max

  # Missing years
  expected_years <- seq(ano_min, ano_max)
  missing_years <- setdiff(expected_years, anos_unicos)
  if (length(missing_years) > 0) {
    diag <- .vigiar_add_issue(diag, "aviso",
      sprintf("Anos ausentes na serie: %s",
              paste(missing_years, collapse = ", ")))
  }

  # Check months if column present
  tem_mes <- col_mes %in% names(dados)
  diag$tem_coluna_mes <- tem_mes

  if (tem_mes) {
    # Filter to rows where BOTH ano and mes are non-NA (keep aligned)
    valid_idx <- !is.na(dados[[col_ano]]) & !is.na(dados[[col_mes]])
    anos_validos <- as.integer(dados[[col_ano]][valid_idx])
    meses_validos <- as.integer(dados[[col_mes]][valid_idx])

    if (length(meses_validos) > 0) {
      meses_fora <- meses_validos[meses_validos < 1 | meses_validos > 12]
      if (length(meses_fora) > 0) {
        diag <- .vigiar_add_issue(diag, "problema",
          sprintf("%d meses fora de 1-12.", length(meses_fora)))
      }

      # Count truly missing months (not invalid)
      n_total_meses <- length(meses_validos)
      diag$metricas$n_meses_ausentes <- sum(is.na(dados[[col_mes]]))

      # Check coverage per year
      for (y in anos_unicos) {
        idx_y <- which(anos_validos == y)
        if (length(idx_y) == 0) next
        meses_ano <- sort(unique(meses_validos[idx_y]))
        missing_meses <- setdiff(1:12, meses_ano)
        if (length(missing_meses) > 0 && length(missing_meses) < 12) {
          diag <- .vigiar_add_issue(diag, "aviso",
            sprintf("Ano %d: meses ausentes: %s",
                    y, paste(missing_meses, collapse = ", ")))
        }
      }

      diag$metricas$n_meses_invalidos <- length(meses_fora)
    }
  }

  diag$metricas$n_anos <- length(anos_unicos)
  diag$metricas$anos_ausentes <- length(missing_years)

  if (length(missing_years) == 0 && length(anos_fora) == 0) {
    .vigiar_add_issue(diag, "ok",
      sprintf("Temporal: %d anos (%d-%d) completos.", length(anos_unicos), ano_min, ano_max))
  }

  diag
}

#' Check spatial coverage
#'
#' Evaluates spatial coverage by municipality count, health
#' macro-region representation, and flags regions with few
#' observed municipalities.
#'
#' @param diag A vigiar_diagnostic object.
#' @param dados Data frame.
#' @param col_muni Municipality code column.
#' @param uf Expected UF.
#' @param escopo Scope: "rj", "uf", or "nacional".
#' @return The modified diagnostic object.
#' @export
vigiar_checar_cobertura_espacial <- function(diag, dados,
                                              col_muni, uf = "RJ",
                                              escopo = "rj") {
  if (!col_muni %in% names(dados)) return(diag)

  codigos <- unique(as.integer(dados[[col_muni]]))
  codigos <- codigos[!is.na(codigos)]
  n_muni <- length(codigos)
  diag$metricas$n_municipios <- n_muni

  if (n_muni == 0) {
    return(.vigiar_add_issue(diag, "critico",
      "Nenhum municipio encontrado na cobertura espacial."))
  }

  # RJ-specific checks
  if (!is.null(uf) && toupper(uf) == "RJ" && escopo == "rj") {
    rj_codes <- RJ_MUNICIPIOS$codigo_ibge
    presentes <- intersect(codigos, rj_codes)
    faltantes <- setdiff(rj_codes, codigos)
    pct <- round(100 * length(presentes) / 92, 1)

    diag$metricas$rj_presentes <- length(presentes)
    diag$metricas$rj_faltantes <- length(faltantes)
    diag$metricas$rj_cobertura_pct <- pct

    if (pct < 5) {
      diag <- .vigiar_add_issue(diag, "critico",
        sprintf("Cobertura RJ: apenas %.0f%% (%d/92) municipios.", pct, length(presentes)))
    } else if (pct < 30) {
      diag <- .vigiar_add_issue(diag, "problema",
        sprintf("Cobertura RJ baixa: %.0f%% (%d/92) municipios. Inferencias limitadas.", pct, length(presentes)))
    } else if (pct < 60) {
      diag <- .vigiar_add_issue(diag, "aviso",
        sprintf("Cobertura RJ parcial: %.0f%% (%d/92) municipios. %d ausentes.",
                pct, length(presentes), length(faltantes)))
    } else if (pct < 100) {
      diag <- .vigiar_add_issue(diag, "aviso",
        sprintf("Cobertura RJ: %.0f%% (%d/92) municipios. %d ausentes.",
                pct, length(presentes), length(faltantes)))
    } else {
      .vigiar_add_issue(diag, "ok",
        sprintf("Cobertura RJ: 100%% (%d municipios).", 92))
    }

    # Macro-region coverage
    merged <- merge(
      data.frame(codigo_ibge = codigos),
      RJ_MUNICIPIOS,
      by = "codigo_ibge", all.x = TRUE
    )
    by_region <- table(merged$macrorregiao_saude)
    diag$metricas$macroregioes <- as.list(by_region)

    for (regiao in names(by_region)) {
      expected <- sum(RJ_MUNICIPIOS$macrorregiao_saude == regiao)
      observed <- as.integer(by_region[regiao])
      if (observed < 3 && expected > 3) {
        diag <- .vigiar_add_issue(diag, "problema",
          sprintf("Macrorregiao '%s': apenas %d/%d municipios.", regiao, observed, expected))
      } else if (observed < expected * 0.5) {
        diag <- .vigiar_add_issue(diag, "aviso",
          sprintf("Macrorregiao '%s': baixa cobertura (%d/%d).", regiao, observed, expected))
      }
    }
  }

  if (n_muni < 5 && escopo != "nacional") {
    diag <- .vigiar_add_issue(diag, "aviso",
      sprintf("Apenas %d municipios na base. Inferencias espaciais limitadas.", n_muni))
  }

  diag
}

#' Check PM2.5 values
#'
#' Validates PM2.5 values: detects negative values, impossible
#' concentrations (>1000 ug/m3), extreme outliers, and excess
#' missing values.
#'
#' @param diag A vigiar_diagnostic object.
#' @param dados Data frame.
#' @param col_pm25 PM2.5 column name.
#' @return The modified diagnostic object.
#' @export
vigiar_checar_pm25 <- function(diag, dados, col_pm25) {
  if (!col_pm25 %in% names(dados)) {
    return(.vigiar_add_issue(diag, "critico",
      sprintf("Coluna '%s' nao encontrada.", col_pm25)))
  }

  vals <- as.numeric(dados[[col_pm25]])
  vals <- vals[!is.na(vals)]
  n_total <- length(vals)
  n_na <- sum(is.na(dados[[col_pm25]]))

  if (n_total == 0) {
    return(.vigiar_add_issue(diag, "critico",
      "Todos os valores de PM2.5 sao NA."))
  }

  # Negative values
  negativos <- sum(vals < 0, na.rm = TRUE)
  if (negativos > 0) {
    diag <- .vigiar_add_issue(diag, "critico",
      sprintf("%d valores NEGATIVOS de PM2.5 detectados (impossivel fisicamente).", negativos))
  }

  # Implausible high values
  altos <- sum(vals > 1000, na.rm = TRUE)
  if (altos > 0) {
    diag <- .vigiar_add_issue(diag, "critico",
      sprintf("%d valores > 1000 ug/m3 (improvavel). Verifique unidades.", altos))
  }

  # Extreme outliers (IQR method)
  q1 <- stats::quantile(vals, 0.25, na.rm = TRUE)
  q3 <- stats::quantile(vals, 0.75, na.rm = TRUE)
  iqr <- q3 - q1
  upper <- q3 + 3 * iqr
  extremos <- sum(vals > upper, na.rm = TRUE)
  if (extremos > 0 && extremos / n_total > 0.01) {
    diag <- .vigiar_add_issue(diag, "problema",
      sprintf("%d valores extremos de PM2.5 (> %.0f ug/m3, IQR*3).", extremos, upper))
  }

  # Missing rate
  pct_na <- round(100 * n_na / nrow(dados), 1)
  if (pct_na > 50) {
    diag <- .vigiar_add_issue(diag, "problema",
      sprintf("PM2.5: %.0f%% ausente. Analises comprometidas.", pct_na))
  } else if (pct_na > 20) {
    diag <- .vigiar_add_issue(diag, "aviso",
      sprintf("PM2.5: %.0f%% ausente.", pct_na))
  }

  diag$metricas$pm25_media <- mean(vals, na.rm = TRUE)
  diag$metricas$pm25_mediana <- stats::median(vals, na.rm = TRUE)
  diag$metricas$pm25_dp <- stats::sd(vals, na.rm = TRUE)
  diag$metricas$pm25_min <- min(vals, na.rm = TRUE)
  diag$metricas$pm25_max <- max(vals, na.rm = TRUE)
  diag$metricas$pm25_pct_ausente <- pct_na

  if (negativos == 0 && altos == 0 && extremos == 0) {
    .vigiar_add_issue(diag, "ok",
      sprintf("PM2.5: media=%.1f, mediana=%.1f, dp=%.1f ug/m3.",
              diag$metricas$pm25_media, diag$metricas$pm25_mediana,
              diag$metricas$pm25_dp))
  }

  diag
}

#' Check for duplicate municipality-time entries
#'
#' Detects rows that share the same municipality, year, and
#' optionally month.
#'
#' @param diag A vigiar_diagnostic object.
#' @param dados Data frame.
#' @param col_muni Municipality code column.
#' @param col_ano Year column.
#' @param col_mes Month column (optional).
#' @return The modified diagnostic object.
#' @export
vigiar_checar_duplicatas <- function(diag, dados, col_muni,
                                      col_ano = "ano", col_mes = "mes") {
  cols <- c(col_muni, col_ano)
  if (col_mes %in% names(dados)) cols <- c(cols, col_mes)
  cols <- intersect(cols, names(dados))

  if (length(cols) < 2) return(diag)

  dup_idx <- duplicated(dados[, cols])
  n_dup <- sum(dup_idx)

  diag$metricas$n_duplicatas <- n_dup

  if (n_dup > 0) {
    pct <- round(100 * n_dup / nrow(dados), 1)
    if (pct > 10) {
      diag <- .vigiar_add_issue(diag, "problema",
        sprintf("%d linhas duplicadas (%.1f%%). Dados podem conter repeticoes.", n_dup, pct))
    } else {
      diag <- .vigiar_add_issue(diag, "aviso",
        sprintf("%d linhas duplicadas (%.1f%%).", n_dup, pct))
    }
  } else {
    .vigiar_add_issue(diag, "ok", "Nenhuma duplicata municipio-tempo encontrada.")
  }

  diag
}

#' Detect series breaks
#'
#' Identifies abrupt changes in PM2.5 values within municipalities
#' that may indicate data issues or real environmental changes.
#'
#' @param diag A vigiar_diagnostic object.
#' @param dados Data frame.
#' @param col_muni Municipality code column.
#' @param col_ano Year column.
#' @param col_pm25 PM2.5 column.
#' @return The modified diagnostic object.
#' @export
vigiar_checar_quebra_serie <- function(diag, dados, col_muni,
                                        col_ano = "ano", col_pm25) {
  if (!all(c(col_muni, col_ano, col_pm25) %in% names(dados))) return(diag)

  # Group by municipality, sort by year, detect large year-over-year changes
  dados_ordenados <- dados[order(dados[[col_muni]], dados[[col_ano]]), ]
  municipios <- unique(dados_ordenados[[col_muni]])

  n_quebras <- 0
  muni_quebras <- character(0)

  for (m in municipios) {
    idx <- which(dados_ordenados[[col_muni]] == m)
    if (length(idx) < 3) next
    vals <- as.numeric(dados_ordenados[[col_pm25]][idx])
    anos <- as.integer(dados_ordenados[[col_ano]][idx])

    for (i in seq_along(vals)[-1]) {
      if (is.na(vals[i]) || is.na(vals[i-1])) next
      change <- abs(vals[i] - vals[i-1])
      pct_change <- change / max(abs(vals[i-1]), 0.01)
      if (pct_change > 2 && change > 10) {  # >200% change AND >10 ug/m3
        n_quebras <- n_quebras + 1
        muni_quebras <- c(muni_quebras,
          sprintf("%s (%d->%d: %.1f->%.1f)", m, anos[i-1], anos[i], vals[i-1], vals[i]))
      }
    }
  }

  diag$metricas$n_quebras_serie <- n_quebras

  if (n_quebras > 0) {
    diag <- .vigiar_add_issue(diag, "problema",
      sprintf("%d quebras de serie detectadas (variacao >200%% entre anos consecutivos).", n_quebras))
    if (length(muni_quebras) <= 5) {
      for (q in muni_quebras) {
        diag$mensagens <- c(diag$mensagens, sprintf("  Quebra: %s", q))
      }
    }
  } else {
    .vigiar_add_issue(diag, "ok", "Nenhuma quebra abrupta de serie detectada.")
  }

  diag
}

#' Classify overall alert level
#'
#' Aggregates all diagnostic findings into a final severity
#' classification: ok, aviso, problema, or critico.
#'
#' @param diag A vigiar_diagnostic object.
#' @return The modified diagnostic object with \code{severidade} set.
#' @export
vigiar_classificar_alertas <- function(diag) {
  results <- diag$resultados
  if (length(results) == 0) {
    diag$severidade <- "ok"
    return(diag)
  }

  severities <- vapply(results, `[[`, "", "severidade", USE.NAMES = FALSE)
  worst <- severities[which.max(match(severities, names(VIGIAR_SEVERITY_LEVELS)))]

  diag$severidade <- if (length(worst) > 0) worst else "ok"
  diag
}

#' Generate a diagnostic report
#'
#' Prints a formatted diagnostic report to the console.
#'
#' @param diag A vigiar_diagnostic object.
#' @return Invisibly, the diagnostic object.
#' @export
vigiar_relatorio_diagnostico <- function(diag) {
  stopifnot(inherits(diag, "vigiar_diagnostic"))

  cli::cli_h1("Relatorio Diagnostico VIGIAR")
  cli::cli_text("Tabela: {.strong {diag$tabela}}")
  cli::cli_text("Data: {format(diag$timestamp)}")
  cli::cli_text("Dimensoes: {diag$n_rows} linhas x {diag$n_cols} colunas")
  cli::cli_rule()

  severity_color <- switch(diag$severidade,
    ok      = cli::col_green,
    aviso   = cli::col_yellow,
    problema = cli::col_red,
    critico = cli::col_red,
    identity
  )

  cli::cli_h2("Severidade: {severity_color(toupper(diag$severidade))}")

  if (length(diag$resultados) > 0) {
    cli::cli_h2("Resultados")
    for (r in diag$resultados) {
      icon <- switch(r$severidade,
        ok      = cli::symbol$tick,
        aviso   = cli::symbol$warning,
        problema = cli::symbol$cross,
        critico = cli::symbol$cross
      )
      color <- switch(r$severidade,
        ok      = cli::col_green,
        aviso   = cli::col_yellow,
        problema = cli::col_red,
        critico = cli::col_red,
        identity
      )
      cli::cli_text("{color(icon)} {r$mensagem}")
    }
  }

  if (length(diag$metricas) > 0) {
    cli::cli_h2("Metricas")
    for (nm in names(diag$metricas)) {
      val <- diag$metricas[[nm]]
      if (is.numeric(val) && length(val) == 1) {
        cli::cli_text("  {nm}: {round(val, 2)}")
      } else if (is.character(val)) {
        cli::cli_text("  {nm}: {val}")
      }
    }
  }

  if (length(diag$recomendacoes) > 0) {
    cli::cli_h2("Recomendacoes")
    for (rec in diag$recomendacoes) {
      cli::cli_li(rec)
    }
  }

  invisible(diag)
}

# ===============================================================================
# S3 methods
# ===============================================================================

#' Print a vigiar_diagnostic object
#' @param x A vigiar_diagnostic object.
#' @param ... Additional arguments (ignored).
#' @export
print.vigiar_diagnostic <- function(x, ...) {
  vigiar_relatorio_diagnostico(x)
}

#' Summary method for vigiar_diagnostic
#' @param object A vigiar_diagnostic object.
#' @param ... Additional arguments (ignored).
#' @export
summary.vigiar_diagnostic <- function(object, ...) {
  cat(sprintf("VIGIAR Diagnostic: %s\n", object$tabela))
  cat(sprintf("Severity: %s\n", object$severidade))
  cat(sprintf("Issues: ok=%d aviso=%d problema=%d critico=%d\n",
    sum(vapply(object$resultados, function(x) x$severidade == "ok", logical(1))),
    sum(vapply(object$resultados, function(x) x$severidade == "aviso", logical(1))),
    sum(vapply(object$resultados, function(x) x$severidade == "problema", logical(1))),
    sum(vapply(object$resultados, function(x) x$severidade == "critico", logical(1)))))
  invisible(object)
}

# ===============================================================================
# Internal helpers
# ===============================================================================

.vigiar_add_issue <- function(diag, severity, message) {
  diag$resultados[[length(diag$resultados) + 1L]] <- list(
    severidade = severity,
    mensagem   = message
  )
  diag
}

.vigiar_gerar_recomendacoes <- function(diag) {
  recs <- character(0)

  for (r in diag$resultados) {
    if (r$severidade == "critico") {
      recs <- c(recs, paste0("[CRITICO] ", r$mensagem, " Corrija antes de qualquer analise."))
    }
    if (r$severidade == "problema") {
      recs <- c(recs, paste0("[PROBLEMA] ", r$mensagem, " Investigue a causa antes de modelar."))
    }
  }

  # Contextual recommendations
  if (diag$tem_coluna_mes %||% FALSE) {
    recs <- c(recs, "[INFO] Dados mensais detectados. Verifique completude por municipio-mes antes de agregar.")
  }

  if (!is.null(diag$metricas$rj_cobertura_pct) && diag$metricas$rj_cobertura_pct < 80) {
    recs <- c(recs, "[AVISO] Cobertura municipal insuficiente para inferencias por macrorregiao. Considere analise exploratoria apenas.")
  }

  if (!is.null(diag$metricas$pm25_pct_ausente) && diag$metricas$pm25_pct_ausente > 20) {
    recs <- c(recs, "[AVISO] Alta taxa de dados faltantes de PM2.5. Imputacao pode introduzir vies.")
  }

  diag$recomendacoes <- recs
  diag
}
