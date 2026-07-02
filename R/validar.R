# Package: vigiar
# Column standardisation and validation functions

#' Standardise VIGIAR column names
#'
#' Applies a standard naming convention to raw VIGIAR data.
#' Uses the internal variable dictionary when available.
#'
#' @param dados A data frame.
#' @param tabela Table name (used to look up the dictionary).
#' @return A data frame with standardised column names.
#' @export
vigiar_padronizar_colunas <- function(dados, tabela) {
  dict <- tryCatch(
    .vigiar_dicionario_interno(tabela),
    error = function(e) NULL
  )

  if (is.null(dict)) {
    # Fallback: basic snake_case transformation
    new_names <- tolower(names(dados))
    new_names <- gsub("[^a-z0-9]+", "_", new_names)
    new_names <- gsub("_+", "_", new_names)
    new_names <- gsub("^_|_$", "", new_names)
    names(dados) <- new_names
  } else {
    for (i in seq_len(ncol(dados))) {
      old <- names(dados)[i]
      match_row <- dict[dict$original_name == old, ]
      if (nrow(match_row) == 1 && !is.na(match_row$standard_name) &&
          nzchar(match_row$standard_name)) {
        names(dados)[i] <- match_row$standard_name
      }
    }
  }

  dados
}

#' Validate IBGE municipality codes
#'
#' Checks that municipality codes can be safely normalized to the package
#' standard 6-digit IBGE municipality code. Seven-digit IBGE codes are accepted
#' and normalized by removing the check digit.
#'
#' @param dados A data frame.
#' @param col_codigo Name of the column containing IBGE codes.
#' @return The data frame (unchanged), with a warning on invalid codes.
#' @export
vigiar_validar_ibge <- function(dados, col_codigo = "cod_municipio") {
  if (!col_codigo %in% names(dados)) return(dados)

  codigos <- .vigiar_normalizar_codigo_municipio(dados[[col_codigo]])

  n_invalid <- sum(is.na(codigos))
  if (n_invalid > 0) {
    warning(sprintf(
      "%d IBGE municipality code(s) could not be safely normalized to 6 digits",
      n_invalid
    ))
  }

  dados
}

#' Validate date-related columns
#'
#' Checks that \code{ano} is between 2000 and the current year,
#' and \code{mes} is between 1 and 12.
#'
#' @param dados A data frame.
#' @return The data frame (unchanged), with warnings on invalid values.
#' @export
vigiar_validar_datas <- function(dados) {
  current_year <- as.integer(format(Sys.Date(), "%Y"))

  if ("ano" %in% names(dados)) {
    anos <- as.integer(dados$ano)
    n_bad <- sum(is.na(anos) | anos < 2000 | anos > current_year)
    if (n_bad > 0) {
      warning(sprintf(
        "%d valor(es) de ano fora do intervalo 2000-%d", n_bad, current_year
      ))
    }
  }

  if ("mes" %in% names(dados)) {
    meses <- as.integer(dados$mes)
    n_bad <- sum(is.na(meses) | meses < 1 | meses > 12)
    if (n_bad > 0) {
      warning(sprintf(
        "%d valor(es) de mes fora do intervalo 1-12", n_bad
      ))
    }
  }

  dados
}

#' Validate PM2.5 units
#'
#' Checks that PM2.5 values are within a plausible range
#' (0-1000 ug/m3).
#'
#' @param dados A data frame.
#' @param col_pm25 Name of the PM2.5 column.
#' @return The data frame (unchanged), with a warning on implausible values.
#' @export
vigiar_validar_unidades <- function(dados, col_pm25 = "pm25_media") {
  if (!col_pm25 %in% names(dados)) return(dados)

  valores <- as.numeric(dados[[col_pm25]])
  n_implausible <- sum(!is.na(valores) & (valores < 0 | valores > 1000))
  if (n_implausible > 0) {
    warning(sprintf(
      "%d valor(es) de PM2.5 fora do intervalo plausivel (0-1000 ug/m3)",
      n_implausible
    ))
  }

  dados
}
