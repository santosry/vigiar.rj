# Package: vigiar
# Variable dictionary query interface
#
# Provides functions to explore the VIGIAR data dictionary:
#   vigiar_dicionario()     -- full dictionary
#   vigiar_variaveis()      -- variables for a table
#   vigiar_descrever_variavel() -- describe a single variable
#   vigiar_convencoes()     -- open conventions page
#   vigiar_schema()         -- table schema overview

#' Load the VIGIAR variable dictionary
#'
#' Returns the complete variable dictionary as a tibble.
#'
#' @return A tibble with columns: table_id, table_name, original_name,
#'   standard_name, type_raw, type_processed, description, unit,
#'   allowed_values, notes.
#' @export
vigiar_dicionario <- function() {
  path <- system.file("extdata", "vigiar_variable_dictionary.csv",
                      package = "vigiar.rj", mustWork = TRUE)
  tbl <- tryCatch(
    utils::read.csv(path, stringsAsFactors = FALSE, encoding = "UTF-8"),
    error = function(e) {
      # Fallback: return empty dict with a message
      warning("Dicionario de variaveis nao encontrado. Execute data-raw/dictionary.R")
      data.frame(
        table_id = character(0), table_name = character(0),
        original_name = character(0), standard_name = character(0),
        type_raw = character(0), type_processed = character(0),
        description = character(0), unit = character(0),
        allowed_values = character(0), missing_values = character(0),
        example = character(0), processing_rule = character(0),
        validation_rule = character(0), notes = character(0),
        stringsAsFactors = FALSE
      )
    }
  )
  tibble::as_tibble(tbl)
}

#' List variables for a specific data domain
#'
#' @param dominio One of \code{"pm25"}, \code{"populacao_exposta"},
#'   \code{"indicadores_saude"}, \code{"fracao_atribuivel"},
#'   \code{"exposicao_indoor"}, \code{"municipios"}, or \code{"all"}.
#' @return A tibble subset of the dictionary.
#' @export
vigiar_variaveis <- function(dominio = c("pm25", "populacao_exposta",
                                          "indicadores_saude",
                                          "fracao_atribuivel",
                                          "exposicao_indoor",
                                          "municipios", "all")) {
  dominio <- match.arg(dominio)

  dict <- vigiar_dicionario()

  if (dominio == "all") return(dict)

  table_map <- list(
    pm25                = c("df_anual", "df_mensal", "df_dias", "df_dias_conama"),
    populacao_exposta   = "pop",
    indicadores_saude   = c("tb_brasil", "tb_uf", "tb_muni", "tb_quartis"),
    fracao_atribuivel   = "tb_fracao",
    exposicao_indoor    = c("df_indoor", "df_indoor_desfecho"),
    municipios          = "df_muni"
  )

  tabelas <- table_map[[dominio]]
  dict[dict$table_id %in% tabelas, ]
}

#' Describe a single VIGIAR variable
#'
#' @param dominio Data domain (see \code{vigiar_variaveis}).
#' @param variavel Standard variable name.
#' @return Invisibly, the dictionary row for the variable.
#' @export
vigiar_descrever_variavel <- function(dominio, variavel) {
  vars <- vigiar_variaveis(dominio)
  row <- vars[vars$standard_name == variavel, ]

  if (nrow(row) == 0) {
    stop(sprintf(
      "Variavel '%s' nao encontrada no dominio '%s'.", variavel, dominio
    ))
  }

  cat(sprintf("\nVariavel: %s\n", variavel))
  cat(strrep("-", 60), "\n")
  cat(sprintf("Dominio:         %s\n", dominio))
  cat(sprintf("Nome original:   %s\n", row$original_name[1]))
  cat(sprintf("Tipo (raw):      %s\n", row$type_raw[1]))
  cat(sprintf("Tipo (processado): %s\n", row$type_processed[1]))
  cat(sprintf("Descricao:       %s\n", row$description[1]))
  if (nzchar(row$unit[1])) {
    cat(sprintf("Unidade:         %s\n", row$unit[1]))
  }
  if (nzchar(row$allowed_values[1])) {
    cat(sprintf("Valores aceitos: %s\n", row$allowed_values[1]))
  }
  if (nzchar(row$notes[1])) {
    cat(sprintf("Observacoes:     %s\n", row$notes[1]))
  }
  cat("\n")

  invisible(row)
}

#' Open VIGIAR conventions documentation
#'
#' Opens the online conventions page (equivalent to microdatasus
#' "Convencoes SIH-RD").
#'
#' @export
vigiar_convencoes <- function() {
  url <- "https://santosry.github.io/vigiar-download/articles/convencoes-vigiar.html"
  utils::browseURL(url)
}

#' Show schema for a data domain
#'
#' Returns a summary of all variables in a domain: names, types,
#' descriptions, and units.
#'
#' @param dominio Data domain name.
#' @return A tibble with schema information.
#' @export
vigiar_schema <- function(dominio = "all") {
  vars <- vigiar_variaveis(dominio)
  vars[, c("table_id", "standard_name", "type_processed",
           "description", "unit")]
}

# -- Internal helpers ----------------------------------------------------------

.vigiar_dicionario_interno <- function(tabela) {
  dict <- tryCatch(
    vigiar_dicionario(),
    error = function(e) NULL
  )
  if (is.null(dict)) return(NULL)
  dict[dict$table_id == tabela, ]
}
