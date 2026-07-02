# Package: vigiar
# Compliance auditing and data quality assurance
#
# Implements comprehensive data auditing following the microdatasus
# philosophy: every download is validated, every deviation is reported,
# and audit trails are preserved for reproducibility.

#' Full data compliance audit
#'
#' Performs a comprehensive audit of a VIGIAR data table against
#' the expected schema, IBGE standards, and data quality rules.
#' Returns a structured report suitable for regulatory compliance.
#'
#' @param dados A VIGIAR data frame or tibble.
#' @param tabela Table name for context.
#' @param verbose If \code{TRUE}, prints detailed audit results.
#' @return A list with audit sections: \code{schema}, \code{ibge},
#'   \code{temporal}, \code{units}, \code{coverage}, \code{checksums}.
#' @export
vigiar_auditar <- function(dados, tabela = NULL, verbose = TRUE) {
  tabela <- tabela %||% attr(dados, "vigiar_tabela") %||% "desconhecida"

  if (verbose) {
    cli::cli_h1("Auditoria VIGIAR")
    cli::cli_text("Tabela: {.strong {tabela}}")
    cli::cli_text("Auditado em: {format(Sys.time())}")
    cli::cli_rule()
  }

  audit <- list(
    tabela     = tabela,
    timestamp  = Sys.time(),
    r_version  = R.version.string,
    vigiar_version = as.character(utils::packageVersion("vigiar")),
    session_info  = .vigiar_session_info()
  )

  # 1. Schema compliance
  audit$schema <- .vigiar_auditar_schema(dados, tabela, verbose)

  # 2. IBGE code validation
  audit$ibge <- .vigiar_auditar_ibge(dados, verbose)

  # 3. Temporal consistency
  audit$temporal <- .vigiar_auditar_temporal(dados, verbose)

  # 4. Unit validation
  audit$units <- .vigiar_auditar_units(dados, tabela, verbose)

  # 5. Spatial coverage
  audit$coverage <- .vigiar_auditar_coverage(dados, verbose)

  # 6. Data checksums (reproducibility)
  audit$checksums <- .vigiar_auditar_checksums(dados, verbose)

  # 7. Overall assessment
  audit$passed <- all(
    audit$schema$ok,
    audit$ibge$ok,
    audit$temporal$ok,
    audit$units$ok,
    audit$coverage$ok
  )

  if (verbose) {
    cli::cli_rule()
    if (audit$passed) {
      cli::cli_alert_success("AUDITORIA APROVADA -- Todos os checks passaram")
    } else {
      cli::cli_alert_danger("AUDITORIA REPROVADA -- Verificar sessoes com FAIL")
    }
  }

  class(audit) <- "vigiar_audit"
  invisible(audit)
}

#' Print method for vigiar_audit
#' @param x A vigiar_audit object.
#' @param ... Additional arguments (ignored).
#' @export
print.vigiar_audit <- function(x, ...) {
  cli::cli_h1("Relatorio de Auditoria VIGIAR")
  cli::cli_text("Tabela: {x$tabela}")
  cli::cli_text("Data: {format(x$timestamp)}")
  cli::cli_text("R: {x$r_version}")
  cli::cli_text("vigiar: {x$vigiar_version}")
  cli::cli_rule()

  sections <- c("schema", "ibge", "temporal", "units", "coverage")
  labels <- c(
    schema   = "Conformidade de Esquema",
    ibge     = "Validacao de Codigos IBGE",
    temporal = "Consistencia Temporal",
    units    = "Validacao de Unidades",
    coverage = "Cobertura Espacial"
  )

  for (s in sections) {
    if (!is.null(x[[s]])) {
      status <- if (isTRUE(x[[s]]$ok)) cli::col_green("PASS") else cli::col_red("FAIL")
      cli::cli_text("{status} {labels[s]}")
      if (!is.null(x[[s]]$details)) {
        for (d in x[[s]]$details) {
          cli::cli_text("  - {d}")
        }
      }
    }
  }

  cli::cli_rule()
  if (x$passed) {
    cli::cli_alert_success("Resultado final: APROVADO")
  } else {
    cli::cli_alert_danger("Resultado final: REPROVADO")
  }
  invisible(x)
}

#' Audit all downloaded tables
#'
#' Runs \code{vigiar_auditar()} on every table in a named list
#' (e.g., the result of \code{vigiar_baixar_tudo()}).
#'
#' @param dados_list Named list of data frames.
#' @param verbose If \code{TRUE}, prints progress.
#' @return A named list of audit reports.
#' @export
vigiar_auditar_tudo <- function(dados_list, verbose = TRUE) {
  if (!is.list(dados_list) || is.null(names(dados_list))) {
    stop("'dados_list' deve ser uma lista nomeada de data frames.")
  }

  results <- vector("list", length(dados_list))
  names(results) <- names(dados_list)

  for (i in seq_along(dados_list)) {
    tab <- names(dados_list)[i]
    if (verbose) cli::cli_text("Auditando: {tab} ({i}/{length(dados_list)})")
    results[[tab]] <- tryCatch(
      vigiar_auditar(dados_list[[tab]], tabela = tab, verbose = FALSE),
      error = function(e) {
        list(tabela = tab, error = e$message, passed = FALSE)
      }
    )
  }

  n_passed <- sum(vapply(results, function(x) isTRUE(x$passed), logical(1)))
  if (verbose) {
    cli::cli_rule()
    cli::cli_alert_info(
      "Auditoria concluida: {n_passed}/{length(results)} tabelas aprovadas"
    )
  }

  class(results) <- "vigiar_audit_list"
  invisible(results)
}

#' Print method for vigiar_audit_list
#' @param x A vigiar_audit_list object.
#' @param ... Additional arguments (ignored).
#' @export
print.vigiar_audit_list <- function(x, ...) {
  n <- length(x)
  n_ok <- sum(vapply(x, function(a) isTRUE(a$passed), logical(1)))
  cli::cli_h1("Auditoria Multi-Tabela")
  cli::cli_text("{n_ok}/{n} tabelas aprovadas")
  cli::cli_rule()
  for (tab in names(x)) {
    a <- x[[tab]]
    status <- if (isTRUE(a$passed)) cli::col_green("OK") else cli::col_red("FAIL")
    cli::cli_text("{status} {tab}")
  }
  invisible(x)
}

#' Run a batch audit across multiple compliance profiles
#'
#' @param dados A VIGIAR data frame.
#' @param tabela Table name.
#' @param profiles Character vector of audit profiles:
#'   \code{"basico"} (default), \code{"rigoroso"}, \code{"rj"},
#'   \code{"corrupcao"}. Use \code{"all"} for everything.
#' @param verbose If \code{TRUE}, prints progress and detailed results.
#' @return A list of per-profile audit results.
#' @export
vigiar_compliance_check <- function(dados, tabela = NULL,
                                     profiles = c("basico", "rigoroso", "rj"),
                                     verbose = TRUE) {
  tabela <- tabela %||% attr(dados, "vigiar_tabela") %||% "desconhecida"

  all_profiles <- c("basico", "rigoroso", "rj", "corrupcao")
  if ("all" %in% profiles) profiles <- all_profiles
  profiles <- match.arg(profiles, all_profiles, several.ok = TRUE)

  results <- vector("list", length(profiles))
  names(results) <- profiles

  for (p in profiles) {
    if (verbose) cli::cli_h2("Perfil: {p}")
    results[[p]] <- switch(p,
      basico = {
        # Basic: schema + IBGE + temporal
        list(
          schema   = .vigiar_auditar_schema(dados, tabela, verbose),
          ibge     = .vigiar_auditar_ibge(dados, verbose),
          temporal = .vigiar_auditar_temporal(dados, verbose),
          ok       = TRUE  # evaluated below
        )
      },
      rigoroso = {
        # Strict: everything + outlier detection
        base <- vigiar_auditar(dados, tabela, verbose = FALSE)
        base$outliers <- .vigiar_detectar_outliers(dados, verbose = verbose)
        base
      },
      rj = {
        # RJ-specific compliance
        validar_rj <- function() vigiar_validar_rj(dados)
        list(
          rj_municipios = if (verbose) {
            validar_rj()
          } else {
            suppressWarnings(suppressMessages(validar_rj()))
          },
          rj_cobertura  = .vigiar_auditar_cobertura_rj(dados, verbose = verbose),
          ok            = TRUE
        )
      },
      corrupcao = {
        # Data integrity / corruption checks
        .vigiar_auditar_integridade(dados, tabela, verbose = verbose)
      }
    )

    # Evaluate ok status
    if ("ok" %in% names(results[[p]])) {
      sub_oks <- vapply(
        results[[p]],
        function(x) if (is.list(x) && "ok" %in% names(x)) x$ok else TRUE,
        logical(1)
      )
      results[[p]]$ok <- all(sub_oks)
    }
  }

  all_ok <- all(vapply(results, function(x) isTRUE(x$ok), logical(1)))

  if (verbose) {
    cli::cli_rule()
    if (all_ok) {
      cli::cli_alert_success("COMPLIANCE: Todos os perfis aprovados")
    } else {
      fails <- names(results)[!vapply(results, function(x) isTRUE(x$ok), logical(1))]
      cli::cli_alert_danger("COMPLIANCE FALHOU nos perfis: {paste(fails, collapse=', ')}")
    }
  }

  class(results) <- "vigiar_compliance"
  invisible(results)
}

#' Print method for vigiar_compliance
#' @param x A vigiar_compliance object.
#' @param ... Additional arguments (ignored).
#' @export
print.vigiar_compliance <- function(x, ...) {
  cli::cli_h1("Relatorio de Compliance VIGIAR")
  for (p in names(x)) {
    status <- if (isTRUE(x[[p]]$ok)) cli::col_green("PASS") else cli::col_red("FAIL")
    cli::cli_text("{status} Perfil: {p}")
  }
  invisible(x)
}

# -- Internal audit helpers ----------------------------------------------------

.vigiar_auditar_schema <- function(dados, tabela, verbose) {
  n_rows <- nrow(dados)
  n_cols <- ncol(dados)
  col_names <- names(dados)
  n_dup <- sum(duplicated(dados))
  na_total <- sum(is.na(dados))
  na_pct <- if (n_rows > 0) round(100 * na_total / (n_rows * n_cols), 2) else 0

  issues <- character(0)

  if (n_rows == 0) issues <- c(issues, "Tabela vazia (0 linhas)")
  if (n_dup > 0) issues <- c(issues, sprintf("%d linhas duplicadas (%.1f%%)",
                                              n_dup, 100 * n_dup / n_rows))
  if (na_pct > 20) issues <- c(issues, sprintf("Alta taxa de NAs: %.1f%%", na_pct))

  # Check against schema if we have one
  schema_ok <- TRUE
  if (!is.null(.vigiar_env$esquema) && tabela %in% names(.vigiar_env$esquema)) {
    expected_cols <- names(.vigiar_env$esquema[[tabela]])
    missing <- setdiff(expected_cols, col_names)
    extra <- setdiff(col_names, expected_cols)
    if (length(missing) > 0) {
      issues <- c(issues, sprintf("Colunas esperadas ausentes: %s",
                                  paste(missing, collapse = ", ")))
      schema_ok <- FALSE
    }
    if (length(extra) > 0) {
      issues <- c(issues, sprintf("Colunas extras inesperadas: %s",
                                  paste(extra, collapse = ", ")))
      schema_ok <- FALSE
    }
  }

  result <- list(
    ok         = length(issues) == 0,
    n_rows     = n_rows,
    n_cols     = n_cols,
    n_dup      = n_dup,
    na_total   = na_total,
    na_pct     = na_pct,
    details    = issues
  )

  if (verbose && length(issues) > 0) {
    for (issue in issues) cli::cli_alert_warning(issue)
  }
  if (verbose && result$ok) cli::cli_alert_success("Schema: OK")

  result
}

.vigiar_auditar_ibge <- function(dados, verbose) {
  col_muni <- intersect(
    c("cod_municipio", "muni", "id_muni", "ID_MUNI", "codigo_ibge",
      "cod_ibge", "codigo_municipio", "MUN_COD"),
    names(dados)
  )[1]

  if (is.na(col_muni)) {
    if (verbose) cli::cli_alert_info("IBGE: Sem coluna de codigo municipal")
    return(list(ok = TRUE, details = "Sem coluna de codigo IBGE"))
  }

  raw_codes <- dados[[col_muni]]
  normalized <- .vigiar_normalizar_codigo_municipio(raw_codes)
  codigos <- normalized[!is.na(normalized)]
  raw_non_missing <- raw_codes[!is.na(raw_codes)]

  if (length(raw_non_missing) == 0) {
    return(list(ok = TRUE, details = "Nenhum codigo IBGE nos dados"))
  }

  invalidos <- raw_codes[is.na(normalized) & !is.na(raw_codes)]
  validos <- codigos

  ok <- length(invalidos) == 0
  details <- sprintf(
    "%d codigos IBGE, %d validos, %d fora do intervalo esperado",
    length(raw_non_missing), length(validos), length(invalidos)
  )

  if (verbose) {
    if (ok) {
      cli::cli_alert_success("IBGE: {details}")
    } else {
      cli::cli_alert_warning("IBGE: {details}")
    }
  }

  list(
    ok        = ok,
    n_total   = length(raw_non_missing),
    n_validos = length(validos),
    n_invalidos = length(invalidos),
    codigos_invalidos = invalidos,
    details   = details
  )
}

.vigiar_auditar_temporal <- function(dados, verbose) {
  issues <- character(0)
  current_year <- as.integer(format(Sys.Date(), "%Y"))

  if ("ano" %in% names(dados)) {
    anos <- as.integer(dados$ano)
    anos <- anos[!is.na(anos)]
    bad_anos <- sum(anos < 2000 | anos > current_year)
    if (bad_anos > 0) {
      issues <- c(issues, sprintf("%d anos fora de 2000-%d", bad_anos, current_year))
    }
    range_anos <- if (length(anos) > 0) paste(range(anos), collapse = "-") else "N/A"
  } else {
    range_anos <- "N/A"
  }

  if ("mes" %in% names(dados)) {
    meses <- as.integer(dados$mes)
    meses <- meses[!is.na(meses)]
    bad_mes <- sum(meses < 1 | meses > 12)
    if (bad_mes > 0) {
      issues <- c(issues, sprintf("%d meses fora de 1-12", bad_mes))
    }
  }

  ok <- length(issues) == 0

  if (verbose) {
    if (ok) {
      cli::cli_alert_success("Temporal: faixa {range_anos} -- OK")
    } else {
      for (i in issues) cli::cli_alert_warning(i)
    }
  }

  list(
    ok         = ok,
    faixa_anos = range_anos,
    details    = issues
  )
}

.vigiar_auditar_units <- function(dados, tabela, verbose) {
  issues <- character(0)

  # PM2.5 range check
  pm25_cols <- intersect(
    c("pm25_media", "pm25_media_anual", "pm25_media_periodo", "Media_pm25"),
    names(dados)
  )
  for (col in pm25_cols) {
    vals <- as.numeric(dados[[col]])
    bad <- sum(!is.na(vals) & (vals < 0 | vals > 1000))
    if (bad > 0) {
      issues <- c(issues, sprintf("PM2.5 (%s): %d valores implausiveis", col, bad))
    }
  }

  # Population magnitude check
  pop_cols <- intersect(c("populacao", "populacao_exposta", "pop"), names(dados))
  for (col in pop_cols) {
    vals <- as.numeric(dados[[col]])
    bad <- sum(!is.na(vals) & vals < 0, na.rm = TRUE)
    if (bad > 0) {
      issues <- c(issues, sprintf("Populacao (%s): %d valores negativos", col, bad))
    }
  }

  ok <- length(issues) == 0

  if (verbose) {
    if (ok) {
      cli::cli_alert_success("Unidades: OK")
    } else {
      for (i in issues) cli::cli_alert_warning(i)
    }
  }

  list(ok = ok, details = issues)
}

.vigiar_auditar_coverage <- function(dados, verbose) {
  col_uf <- intersect(c("sigla_uf", "UF", "UF_SIGLA"), names(dados))[1]
  col_muni <- intersect(
    c("cod_municipio", "muni", "ID_MUNI", "codigo_ibge"), names(dados)
  )[1]

  n_uf <- NA_integer_
  n_muni <- NA_integer_

  if (!is.na(col_uf)) n_uf <- dplyr::n_distinct(dados[[col_uf]], na.rm = TRUE)
  if (!is.na(col_muni)) n_muni <- dplyr::n_distinct(dados[[col_muni]], na.rm = TRUE)

  if (verbose) {
    msg <- sprintf(
      "Cobertura: %s UFs, %s municipios",
      if (is.na(n_uf)) "?" else as.character(n_uf),
      if (is.na(n_muni)) "?" else as.character(n_muni)
    )
    cli::cli_alert_info(msg)
  }

  list(
    ok      = TRUE,
    n_uf    = n_uf,
    n_muni  = n_muni
  )
}

.vigiar_auditar_cobertura_rj <- function(dados, verbose) {
  col_muni <- intersect(
    c("cod_municipio", "muni", "ID_MUNI", "codigo_ibge"), names(dados)
  )[1]

  if (is.na(col_muni)) {
    if (verbose) cli::cli_alert_warning("Cobertura RJ: sem coluna de municipio")
    return(list(ok = FALSE, details = "Sem coluna de municipio para checagem RJ"))
  }

  codigos <- unique(.vigiar_normalizar_codigo_municipio(dados[[col_muni]]))
  codigos <- codigos[!is.na(codigos)]

  rj_codes <- RJ_MUNICIPIOS$codigo_ibge_6
  presentes <- intersect(codigos, rj_codes)
  faltantes <- setdiff(rj_codes, codigos)

  pct <- round(100 * length(presentes) / 92, 1)

  if (verbose) {
    cli::cli_alert_info(
      "Cobertura RJ: {length(presentes)}/92 municipios ({pct}%)"
    )
    if (length(faltantes) > 0) {
      cli::cli_alert_warning(
        "{length(faltantes)} municipios RJ faltando"
      )
    }
  }

  list(
    ok                 = length(faltantes) == 0,
    n_presentes        = length(presentes),
    n_faltantes        = length(faltantes),
    pct_cobertura      = pct,
    municipios_faltantes = faltantes
  )
}

.vigiar_auditar_integridade <- function(dados, tabela, verbose) {
  issues <- character(0)

  # Check for all-NA columns
  all_na <- vapply(dados, function(x) all(is.na(x)), logical(1))
  if (any(all_na)) {
    na_cols <- names(dados)[all_na]
    issues <- c(issues, sprintf("Colunas 100%% NA: %s", paste(na_cols, collapse = ", ")))
  }

  # Check for constant-value columns
  constant <- vapply(dados, function(x) {
    if (all(is.na(x))) return(FALSE)
    length(unique(x[!is.na(x)])) == 1L
  }, logical(1))
  if (any(constant)) {
    const_cols <- names(dados)[constant]
    issues <- c(issues, sprintf("Colunas com valor unico: %s",
                                paste(const_cols, collapse = ", ")))
  }

  # Check for mixed types per column (raw list columns)
  for (col in names(dados)) {
    if (is.list(dados[[col]]) && !inherits(dados[[col]], "POSIXct")) {
      types <- unique(vapply(dados[[col]], typeof, ""))
      if (length(types) > 1) {
        issues <- c(issues, sprintf("Coluna '%s' tem tipos mistos: %s",
                                    col, paste(types, collapse = ", ")))
      }
    }
  }

  # Row count consistency with schema
  if (!is.null(.vigiar_env$esquema) && tabela %in% names(.vigiar_env$esquema)) {
    expected_ncols <- length(.vigiar_env$esquema[[tabela]])
    if (ncol(dados) != expected_ncols) {
      issues <- c(issues,
        sprintf("Numero de colunas: %d (esperado: %d)", ncol(dados), expected_ncols))
    }
  }

  ok <- length(issues) == 0

  if (verbose) {
    if (ok) {
      cli::cli_alert_success("Integridade: OK")
    } else {
      for (i in issues) cli::cli_alert_danger(i)
    }
  }

  list(ok = ok, details = issues)
}

#' Detect outliers in numeric columns
#' @keywords internal
.vigiar_detectar_outliers <- function(dados, verbose = TRUE) {
  num_cols <- names(dados)[vapply(dados, is.numeric, logical(1))]
  outliers <- list()

  for (col in num_cols) {
    x <- dados[[col]]
    x <- x[!is.na(x)]
    if (length(x) < 10) next

    q1 <- stats::quantile(x, 0.25, na.rm = TRUE)
    q3 <- stats::quantile(x, 0.75, na.rm = TRUE)
    iqr <- q3 - q1
    lower <- q1 - 1.5 * iqr
    upper <- q3 + 1.5 * iqr

    n_low <- sum(x < lower, na.rm = TRUE)
    n_high <- sum(x > upper, na.rm = TRUE)

    if (n_low + n_high > 0) {
      outliers[[col]] <- list(
        n_low  = n_low,
        n_high = n_high,
        lower  = lower,
        upper  = upper,
        pct    = 100 * (n_low + n_high) / length(x)
      )
      if (verbose) {
        cli::cli_alert_warning(
          "Outliers em '{col}': {n_low + n_high} valores ({round(outliers[[col]]$pct, 1)}%)"
        )
      }
    }
  }

  if (verbose && length(outliers) == 0) {
    cli::cli_alert_success("Outliers: nenhum detectado (metodo IQR)")
  }

  outliers
}

# -- Checksum-based reproducibility --------------------------------------------

.vigiar_auditar_checksums <- function(dados, verbose) {
  # Compute deterministic checksums for key columns
  checksums <- list(
    nrow       = nrow(dados),
    ncol       = ncol(dados),
    col_names  = paste(sort(names(dados)), collapse = ", "),
    sha256     = .vigiar_data_checksum(dados)
  )

  if (verbose) {
    cli::cli_alert_info(
      "Checksum SHA256: {substr(checksums$sha256, 1, 16)}..."
    )
  }

  list(
    ok        = TRUE,
    checksums = checksums
  )
}

#' Compute a deterministic checksum for a data frame
#'
#' Uses SHA256 on a canonical JSON representation. Same data always
#' produces the same hash -- enabling cross-environment reproducibility.
#'
#' @param dados A data frame.
#' @return A SHA256 hex string.
#' @export
vigiar_checksum <- function(dados) {
  .vigiar_data_checksum(dados)
}

.vigiar_data_checksum <- function(dados) {
  # Convert to canonical JSON
  json <- jsonlite::toJSON(
    dados,
    dataframe = "columns",
    auto_unbox = TRUE,
    digits = 10,
    pretty = FALSE
  )
  # Hash with SHA256
  raw_hash <- openssl::sha256(charToRaw(json))
  paste(format(raw_hash), collapse = "")
}

# -- Session info --------------------------------------------------------------

.vigiar_session_info <- function() {
  list(
    r_version   = R.version.string,
    platform    = R.version$platform,
    locale      = Sys.getlocale("LC_COLLATE"),
    timezone    = Sys.timezone(),
    packages    = c(
      httr2 = as.character(utils::packageVersion("httr2")),
      jsonlite = as.character(utils::packageVersion("jsonlite")),
      tibble = as.character(utils::packageVersion("tibble")),
      dplyr = as.character(utils::packageVersion("dplyr"))
    )
  )
}

#' Export audit report as JSON
#'
#' Serializes a \code{vigiar_audit} or \code{vigiar_compliance}
#' report to JSON for long-term archiving.
#'
#' @param audit An audit object.
#' @param caminho File path to write JSON.
#' @return Invisibly, the file path.
#' @export
vigiar_exportar_auditoria <- function(audit, caminho) {
  dir.create(dirname(caminho), showWarnings = FALSE, recursive = TRUE)
  json <- jsonlite::toJSON(audit, auto_unbox = TRUE, pretty = TRUE,
                            null = "null", force = TRUE)
  writeLines(json, caminho)
  cli::cli_alert_success("Auditoria exportada: {caminho}")
  invisible(caminho)
}
