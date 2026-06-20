# Package: vigiar
# Rio de Janeiro state — official municipality registry
#
# Source: IBGE 2022 + SES-RJ health regions
# 92 municipios, 9 macrorregioes de saude

# ---- RJ Municipality Registry ------------------------------------------------

RJ_MUNICIPIOS <- data.frame(
  codigo_ibge = c(
    330010, 330015, 330020, 330022, 330023, 330025, 330030, 330033,
    330040, 330045, 330050, 330060, 330070, 330080, 330090, 330093,
    330095, 330100, 330110, 330115, 330120, 330130, 330140, 330150,
    330160, 330170, 330180, 330185, 330187, 330190, 330200, 330205,
    330210, 330220, 330225, 330227, 330230, 330240, 330245, 330250,
    330260, 330270, 330280, 330285, 330290, 330300, 330310, 330320,
    330330, 330340, 330350, 330360, 330370, 330380, 330385, 330390,
    330395, 330400, 330410, 330411, 330412, 330414, 330415, 330420,
    330430, 330440, 330450, 330452, 330455, 330460, 330470, 330475,
    330480, 330490, 330500, 330510, 330513, 330515, 330520, 330530,
    330540, 330550, 330555, 330560, 330570, 330575, 330580, 330590,
    330600, 330610, 330615, 330620),
  municipio = c(
    "Angra dos Reis", "Aperibe", "Araruama", "Areal",
    "Armacao dos Buzios", "Arraial do Cabo", "Barra do Pirai", "Italva",
    "Barra Mansa", "Belford Roxo", "Bom Jardim", "Bom Jesus do Itabapoana",
    "Cabo Frio", "Cachoeiras de Macacu", "Cambuci", "Campos dos Goytacazes",
    "Cantagalo", "Carapebus", "Cardoso Moreira", "Carmo",
    "Casimiro de Abreu", "Comendador Levy Gasparian", "Conceicao de Macabu", "Cordeiro",
    "Duas Barras", "Duque de Caxias", "Engenheiro Paulo de Frontin", "Guapimirim",
    "Iguaba Grande", "Itaborai", "Itaguai", "Itaocara",
    "Itaperuna", "Itatiaia", "Japeri", "Laje do Muriae",
    "Macae", "Macuco", "Mage", "Mangaratiba",
    "Marica", "Mendes", "Mesquita", "Miguel Pereira",
    "Miracema", "Natividade", "Nilopolis", "Niteroi",
    "Nova Friburgo", "Nova Iguacu", "Paracambi", "Paraiba do Sul",
    "Paraty", "Paty do Alferes", "Petropolis", "Pinheiral",
    "Pirai", "Porciuncula", "Porto Real", "Quatis",
    "Queimados", "Quissama", "Resende", "Rio Bonito",
    "Rio Claro", "Rio das Flores", "Rio das Ostras", "Rio de Janeiro",
    "Santa Maria Madalena", "Santo Antonio de Padua", "Sao Fidelis", "Sao Francisco de Itabapoana",
    "Sao Goncalo", "Sao Joao da Barra", "Sao Joao de Meriti", "Sao Jose de Uba",
    "Sao Jose do Vale do Rio Preto", "Sao Pedro da Aldeia", "Sao Sebastiao do Alto", "Sapucaia",
    "Saquarema", "Seropedica", "Silva Jardim", "Sumidouro",
    "Tangua", "Teresopolis", "Trajano de Moraes", "Tres Rios",
    "Valenca", "Varre-Sai", "Vassouras", "Volta Redonda"),
  macrorregiao_saude = c(
    "Baia da Ilha Grande", "Noroeste", "Baixada Litoranea", "Centro-Sul",
    "Baixada Litoranea", "Baixada Litoranea", "Medio Paraiba", "Noroeste",
    "Medio Paraiba", "Metropolitana I", "Serrana", "Noroeste",
    "Baixada Litoranea", "Metropolitana II", "Noroeste", "Norte",
    "Serrana", "Norte", "Norte", "Serrana",
    "Baixada Litoranea", "Centro-Sul", "Norte", "Serrana",
    "Serrana", "Metropolitana I", "Centro-Sul", "Metropolitana II",
    "Baixada Litoranea", "Metropolitana II", "Metropolitana I", "Noroeste",
    "Noroeste", "Medio Paraiba", "Metropolitana I", "Noroeste",
    "Norte", "Serrana", "Metropolitana I", "Metropolitana I",
    "Metropolitana II", "Centro-Sul", "Metropolitana I", "Centro-Sul",
    "Noroeste", "Noroeste", "Metropolitana I", "Metropolitana II",
    "Serrana", "Metropolitana I", "Metropolitana I", "Centro-Sul",
    "Baia da Ilha Grande", "Centro-Sul", "Serrana", "Medio Paraiba",
    "Medio Paraiba", "Noroeste", "Medio Paraiba", "Medio Paraiba",
    "Metropolitana I", "Norte", "Medio Paraiba", "Metropolitana II",
    "Medio Paraiba", "Serrana", "Norte", "Metropolitana II",
    "Serrana", "Noroeste", "Norte", "Norte",
    "Metropolitana II", "Norte", "Metropolitana I", "Noroeste",
    "Serrana", "Baixada Litoranea", "Serrana", "Centro-Sul",
    "Baixada Litoranea", "Metropolitana I", "Baixada Litoranea", "Serrana",
    "Metropolitana II", "Serrana", "Serrana", "Centro-Sul",
    "Medio Paraiba", "Noroeste", "Centro-Sul", "Medio Paraiba"),
  regiao_saude = c(
    "Baia da Ilha Grande", "Noroeste", "Baixada Litoranea", "Centro-Sul",
    "Baixada Litoranea", "Baixada Litoranea", "Medio Paraiba", "Noroeste",
    "Medio Paraiba", "Metropolitana I", "Serrana", "Noroeste",
    "Baixada Litoranea", "Metropolitana II", "Noroeste", "Norte",
    "Serrana", "Norte", "Norte", "Serrana",
    "Baixada Litoranea", "Centro-Sul", "Norte", "Serrana",
    "Serrana", "Metropolitana I", "Centro-Sul", "Metropolitana II",
    "Baixada Litoranea", "Metropolitana II", "Metropolitana I", "Noroeste",
    "Noroeste", "Medio Paraiba", "Metropolitana I", "Noroeste",
    "Norte", "Serrana", "Metropolitana I", "Metropolitana I",
    "Metropolitana II", "Centro-Sul", "Metropolitana I", "Centro-Sul",
    "Noroeste", "Noroeste", "Metropolitana I", "Metropolitana II",
    "Serrana", "Metropolitana I", "Metropolitana I", "Centro-Sul",
    "Baia da Ilha Grande", "Centro-Sul", "Serrana", "Medio Paraiba",
    "Medio Paraiba", "Noroeste", "Medio Paraiba", "Medio Paraiba",
    "Metropolitana I", "Norte", "Medio Paraiba", "Metropolitana II",
    "Medio Paraiba", "Serrana", "Norte", "Metropolitana II",
    "Serrana", "Noroeste", "Norte", "Norte",
    "Metropolitana II", "Norte", "Metropolitana I", "Noroeste",
    "Serrana", "Baixada Litoranea", "Serrana", "Centro-Sul",
    "Baixada Litoranea", "Metropolitana I", "Baixada Litoranea", "Serrana",
    "Metropolitana II", "Serrana", "Serrana", "Centro-Sul",
    "Medio Paraiba", "Noroeste", "Centro-Sul", "Medio Paraiba"),
  stringsAsFactors = FALSE
)

RJ_CODIGOS_VALIDOS <- c(
  "RJ", "rj", "Rio de Janeiro", "RIO DE JANEIRO"
)

RJ_MUNI_RANGE <- c(330010L, 330630L)

# ---- RJ-specific functions ---------------------------------------------------

#' List all 92 Rio de Janeiro municipalities
#'
#' @return A data.frame with columns: codigo_ibge, municipio,
#'   macrorregiao_saude, regiao_saude.
#' @export
vigiar_rj_municipios <- function() {
  RJ_MUNICIPIOS
}

#' List Rio de Janeiro health macro-regions
#'
#' @return Character vector of the 9 macro-regions.
#' @export
vigiar_rj_macrorregioes <- function() {
  sort(unique(RJ_MUNICIPIOS$macrorregiao_saude))
}

#' List Rio de Janeiro health regions
#'
#' @return Character vector of health regions.
#' @export
vigiar_rj_regioes_saude <- function() {
  sort(unique(RJ_MUNICIPIOS$regiao_saude))
}

#' Summarise Rio de Janeiro VIGIAR data
#'
#' @param dados A processed VIGIAR tibble.
#' @param agregacao One of "municipio", "macrorregiao", or "regiao_saude".
#' @return A tibble with summary statistics.
#' @export
vigiar_rj_resumo <- function(dados, agregacao = c("municipio", "macrorregiao", "regiao_saude")) {
  agregacao <- match.arg(agregacao)
  
  # Ensure data has cod_municipio
  col_muni <- intersect(c("cod_municipio", "muni"), names(dados))[1]
  if (is.na(col_muni)) stop("Coluna de codigo de municipio nao encontrada.")
  
  # Filter to RJ only
  dados_rj <- dados[dados[[col_muni]] >= RJ_MUNI_RANGE[1] & 
                     dados[[col_muni]] <= RJ_MUNI_RANGE[2], ]
  
  if (nrow(dados_rj) == 0) {
    warning("Nenhum municipio do RJ encontrado nos dados.")
    return(tibble::tibble())
  }
  
  # Merge with registry
  merged <- merge(dados_rj, RJ_MUNICIPIOS, 
                  by.x = col_muni, by.y = "codigo_ibge",
                  all.x = TRUE)
  
  # Aggregate
  if (agregacao == "municipio") {
    grp <- "municipio"
  } else if (agregacao == "macrorregiao") {
    grp <- "macrorregiao_saude"
  } else {
    grp <- "regiao_saude"
  }
  
  # Find numerical columns to summarise
  num_cols <- names(merged)[sapply(merged, is.numeric)]
  num_cols <- setdiff(num_cols, c("cod_municipio", "ano", "mes"))
  
  if (length(num_cols) == 0) {
    return(tibble::as_tibble(merged))
  }
  
  result <- merged |>
    dplyr::group_by(dplyr::across(dplyr::all_of(grp))) |>
    dplyr::summarise(
      n_municipios = dplyr::n_distinct(.data[[col_muni]]),
      dplyr::across(dplyr::all_of(num_cols), 
                    list(media = ~mean(.x, na.rm = TRUE),
                         dp = ~sd(.x, na.rm = TRUE),
                         n = ~sum(!is.na(.x))),
                    .names = "{.col}_{.fn}"),
      .groups = "drop"
    )
  
  tibble::as_tibble(result)
}

#' Aggregate Rio de Janeiro data by health region
#'
#' @param dados A processed VIGIAR tibble with cod_municipio.
#' @param agregacao "macrorregiao" or "regiao_saude".
#' @return A tibble with aggregated data.
#' @export
vigiar_rj_series <- function(dados, agregacao = c("macrorregiao", "regiao_saude")) {
  agregacao <- match.arg(agregacao)
  vigiar_rj_resumo(dados, agregacao = agregacao)
}

#' Validate that data contains only RJ municipalities
#'
#' Checks IBGE codes, flags non-RJ municipalities, and reports issues.
#'
#' @param dados A data frame with a municipality code column.
#' @param col_muni Name of the municipality code column (auto-detected).
#' @return Invisibly, a list with validation results.
#' @export
vigiar_validar_rj <- function(dados, col_muni = NULL) {
  if (is.null(col_muni)) {
    col_muni <- intersect(c("cod_municipio", "muni", "codigo_ibge"), names(dados))[1]
  }
  if (is.na(col_muni)) stop("Coluna de codigo de municipio nao encontrada.")
  
  codigos <- unique(dados[[col_muni]])
  codigos <- codigos[!is.na(codigos)]
  
  rj_codes <- RJ_MUNICIPIOS$codigo_ibge
  
  in_rj <- codigos[codigos %in% rj_codes]
  fora_rj <- codigos[!codigos %in% rj_codes]
  
  result <- list(
    n_total = length(codigos),
    n_rj = length(in_rj),
    n_fora_rj = length(fora_rj),
    codigos_fora_rj = fora_rj,
    municipios_rj_faltantes = setdiff(rj_codes, codigos),
    valido = length(fora_rj) == 0
  )
  
  if (!result$valido) {
    warning(sprintf(
      "ATENCAO: %d codigos NAO pertencem ao RJ: %s",
      length(fora_rj), paste(fora_rj, collapse = ", ")
    ))
  }
  
  if (length(result$municipios_rj_faltantes) > 0) {
    message(sprintf(
      "%d municipios do RJ nao estao nos dados.",
      length(result$municipios_rj_faltantes)
    ))
  } else {
    message(sprintf(
      "OK: todos os %d municipios do RJ presentes. Nenhum codigo externo.",
      length(in_rj)
    ))
  }
  
  invisible(result)
}

#' Download Rio de Janeiro VIGIAR data (convenience)
#'
#' Shortcut that downloads a table and filters for RJ municipalities.
#'
#' @param tabela Table name.
#' @param ... Additional arguments passed to vigiar_baixar().
#' @return A tibble with RJ-only data.
#' @export
vigiar_baixar_rj <- function(tabela, ...) {
  dados <- vigiar_baixar(tabela, ...)
  
  col_muni <- intersect(c("cod_municipio", "muni", "MUN_COD"), names(dados))[1]
  col_uf <- intersect(c("sigla_uf", "UF", "UF_SIGLA"), names(dados))[1]
  
  if (!is.na(col_muni)) {
    dados <- dados[dados[[col_muni]] >= RJ_MUNI_RANGE[1] & 
                   dados[[col_muni]] <= RJ_MUNI_RANGE[2], ]
    message(sprintf("Filtrado para RJ: %d linhas.", nrow(dados)))
  } else if (!is.na(col_uf)) {
    dados <- dados[toupper(dados[[col_uf]]) == "RJ", ]
    message(sprintf("Filtrado para RJ (por UF): %d linhas.", nrow(dados)))
  }
  
  vigiar_validar_rj(dados, col_muni)
  tibble::as_tibble(dados)
}
