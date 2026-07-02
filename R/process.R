# Package: vigiar
# Processing family -- data standardisation and validation
#
# Follows the microdatasus architecture:
#   1. Download raw data    -> vigiar_baixar()
#   2. Process / standardise -> process_*() or process_vigiar()
#   3. Validate              -> vigiar_checar_dados() / validate()
#   4. Use                   -> analysis-ready tibble

#' Process VIGIAR data -- generic dispatcher
#'
#' Automatically detects the table type and applies the appropriate
#' processing pipeline: standardises column names, converts types,
#' validates IBGE codes, and adds metadata attributes.
#'
#' @param dados A data frame returned by \code{vigiar_baixar()}.
#' @param tabela Table name (auto-detected if \code{dados} has the attribute).
#' @param ... Additional arguments passed to specific processors.
#' @return A \code{vigiar_tbl} with standardised columns and metadata.
#' @export
process_vigiar <- function(dados, tabela = NULL, ...) {
  tabela <- tabela %||% attr(dados, "vigiar_tabela") %||%
    stop("Informe o nome da tabela ou use dados com atributo 'vigiar_tabela'.")

  switch(tabela,
    df_anual             = process_pm25(dados, tipo = "anual", ...),
    df_mensal            = process_pm25(dados, tipo = "mensal", ...),
    df_dias              = process_pm25(dados, tipo = "dias", ...),
    df_dias_conama       = process_pm25(dados, tipo = "dias_conama", ...),
    pop                  = process_populacao_exposta(dados, ...),
    tb_brasil            = process_indicadores_saude(dados, agregacao = "brasil", ...),
    tb_uf                = process_indicadores_saude(dados, agregacao = "uf", ...),
    tb_muni              = process_indicadores_saude(dados, agregacao = "municipio", ...),
    tb_fracao            = process_fracao_atribuivel(dados, ...),
    tb_quartis           = process_indicadores_saude(dados, agregacao = "quartis", ...),
    df_indoor            = process_exposicao_indoor(dados, ...),
    df_indoor_desfecho   = process_exposicao_indoor(dados, tipo = "desfecho", ...),
    df_muni              = process_municipios(dados, ...),
    # fallback: generic processing
    dados
  )
}

# -- PM2.5 processor ----------------------------------------------------------

#' Process PM2.5 air quality data
#'
#' Standardises PM2.5 data from any VIGIAR air quality table
#' (annual, monthly, or critical days).
#'
#' @param dados Raw data frame from \code{vigiar_baixar()}.
#' @param tipo One of \code{"anual"}, \code{"mensal"}, \code{"dias"},
#'   or \code{"dias_conama"}.
#' @param ... Additional arguments (ignored).
#' @return A \code{vigiar_pm25} tibble.
#' @export
process_pm25 <- function(dados, tipo = c("anual", "mensal", "dias", "dias_conama"), ...) {
  tipo <- match.arg(tipo)
  dados <- tibble::as_tibble(dados)

  # -- Standardise column names ---------------------------------------------
  rename_map <- list(
    muni              = "cod_municipio",
    ID_MUNI           = "cod_municipio",
    UF                = "sigla_uf",
    UF_SIGLA          = "sigla_uf",
    UF_NOME           = "nome_uf",
    ano               = "ano",
    mes               = "mes",
    mes_nome          = "mes_nome",
    pm25              = "pm25_media",
    Media_pm25        = "pm25_media_anual",
    t_dias             = "pm25_media_periodo",
    n_dias             = "n_dias_criticos",
    n_dias_conama     = "n_dias_criticos_conama",
    LAT               = "latitude",
    LON               = "longitude",
    Categoria_pm25    = "categoria_oms",
    Categoria_pm25_conama = "categoria_conama",
    Regiao            = "regiao",
    regiao            = "regiao",
    "Regi\u00e3o"     = "regiao",
    Municipio         = "nome_municipio",
    municipio         = "nome_municipio",
    "Munic\u00edpio"  = "nome_municipio"
  )

  for (old_name in names(rename_map)) {
    if (old_name %in% names(dados)) {
      names(dados)[names(dados) == old_name] <- rename_map[[old_name]]
    }
  }

  # -- Type conversion -----------------------------------------------------
  if ("cod_municipio" %in% names(dados)) {
    dados$cod_municipio <- .vigiar_normalizar_codigo_municipio(dados$cod_municipio)
  }
  if ("ano" %in% names(dados)) {
    dados$ano <- as.integer(dados$ano)
  }
  if ("mes" %in% names(dados)) {
    dados$mes <- as.integer(dados$mes)
  }

  # Numeric columns
  for (col in c("pm25_media", "pm25_media_anual", "pm25_media_periodo",
                "n_dias_criticos", "n_dias_criticos_conama",
                "latitude", "longitude")) {
    if (col %in% names(dados)) {
      dados[[col]] <- as.numeric(dados[[col]])
    }
  }

  # -- Validation ----------------------------------------------------------
  dados <- vigiar_validar_ibge(dados, col_codigo = "cod_municipio")
  dados <- vigiar_validar_datas(dados)
  dados <- vigiar_validar_unidades(dados, col_pm25 = "pm25_media")

  # -- Build return object -------------------------------------------------
  metadados <- list(
    tipo         = tipo,
    fonte        = "VIGIAR -- Ministerio da Saude",
    tabela_raw   = switch(tipo,
      anual       = "df_anual",
      mensal      = "df_mensal",
      dias        = "df_dias",
      dias_conama = "df_dias_conama"
    ),
    unidade_pm25 = "\u00b5g/m\u00b3",
    processador  = "process_pm25"
  )

  new_vigiar_tbl(
    dados,
    subclass  = c("vigiar_pm25", "vigiar_air_quality"),
    tabela    = metadados$tabela_raw,
    metadados = metadados
  )
}

# -- Population processor ------------------------------------------------------

#' Process population exposure data
#'
#' @param dados Raw data frame from \code{vigiar_baixar("pop")}.
#' @param ... Additional arguments (ignored).
#' @return A \code{vigiar_population} tibble.
#' @export
process_populacao_exposta <- function(dados, ...) {
  dados <- tibble::as_tibble(dados)

  rename_map <- list(
    muni      = "cod_municipio",
    ano       = "ano",
    pop       = "populacao",
    categoria = "categoria_exposicao",
    UF        = "sigla_uf"
  )
  for (old_name in names(rename_map)) {
    if (old_name %in% names(dados)) {
      names(dados)[names(dados) == old_name] <- rename_map[[old_name]]
    }
  }

  if ("cod_municipio" %in% names(dados)) {
    dados$cod_municipio <- .vigiar_normalizar_codigo_municipio(dados$cod_municipio)
  }
  if ("ano" %in% names(dados)) {
    dados$ano <- as.integer(dados$ano)
  }
  if ("populacao" %in% names(dados)) {
    dados$populacao <- as.numeric(dados$populacao)
  }

  dados <- vigiar_validar_ibge(dados, col_codigo = "cod_municipio")
  dados <- vigiar_validar_datas(dados)

  new_vigiar_tbl(
    dados,
    subclass  = c("vigiar_population"),
    tabela    = "pop",
    metadados = list(
      fonte       = "VIGIAR -- Ministerio da Saude",
      tabela_raw  = "pop",
      processador = "process_populacao_exposta"
    )
  )
}

# -- Health indicators processor -----------------------------------------------

#' Process health indicators data
#'
#' @param dados Raw data frame from \code{vigiar_baixar("tb_brasil")},
#'   \code{vigiar_baixar("tb_uf")}, \code{vigiar_baixar("tb_muni")},
#'   or \code{vigiar_baixar("tb_quartis")}.
#' @param agregacao One of \code{"brasil"}, \code{"uf"},
#'   \code{"municipio"}, or \code{"quartis"}.
#' @param ... Additional arguments (ignored).
#' @return A \code{vigiar_health} tibble.
#' @export
process_indicadores_saude <- function(dados,
                                       agregacao = c("brasil", "uf",
                                                     "municipio", "quartis"),
                                       ...) {
  agregacao <- match.arg(agregacao)
  dados <- tibble::as_tibble(dados)

  rename_map <- list(
    Indicador  = "indicador",
    n          = "populacao_exposta",
    est        = "estimativa",
    low        = "ic_inferior",
    high       = "ic_superior",
    desfecho   = "desfecho",
    ano        = "ano",
    loc        = "codigo_localidade",
    cod        = "cod_municipio",
    lat        = "latitude",
    long       = "longitude",
    Alerta     = "alerta",
    q1         = "quartil_1",
    q2         = "quartil_2",
    q3         = "quartil_3"
  )
  for (old_name in names(rename_map)) {
    if (old_name %in% names(dados)) {
      names(dados)[names(dados) == old_name] <- rename_map[[old_name]]
    }
  }

  # Numeric columns
  for (col in c("populacao_exposta", "estimativa", "ic_inferior",
                "ic_superior", "ano", "cod_municipio", "codigo_localidade",
                "latitude", "longitude", "quartil_1", "quartil_2", "quartil_3")) {
    if (col %in% names(dados)) dados[[col]] <- as.numeric(dados[[col]])
  }

  if ("cod_municipio" %in% names(dados)) {
    dados$cod_municipio <- .vigiar_normalizar_codigo_municipio(dados$cod_municipio)
    dados <- vigiar_validar_ibge(dados, col_codigo = "cod_municipio")
  }

  # Metadata
  tabela_raw <- switch(agregacao,
    brasil    = "tb_brasil",
    uf        = "tb_uf",
    municipio = "tb_muni",
    quartis   = "tb_quartis"
  )

  new_vigiar_tbl(
    dados,
    subclass  = c("vigiar_health"),
    tabela    = tabela_raw,
    metadados = list(
      fonte       = "VIGIAR -- Ministerio da Saude",
      tabela_raw  = tabela_raw,
      agregacao   = agregacao,
      processador = "process_indicadores_saude"
    )
  )
}

# -- Attributable fraction processor -------------------------------------------

#' Process attributable fraction data
#'
#' @param dados Raw data frame from \code{vigiar_baixar("tb_fracao")}.
#' @param ... Additional arguments (ignored).
#' @return A \code{vigiar_attributable_fraction} tibble.
#' @export
process_fracao_atribuivel <- function(dados, ...) {
  dados <- tibble::as_tibble(dados)

  rename_map <- list(
    Indicador = "indicador",
    n         = "populacao_exposta",
    est       = "fracao_atribuivel",
    low       = "ic_inferior",
    high      = "ic_superior",
    desfecho  = "desfecho",
    ano       = "ano",
    loc       = "codigo_localidade",
    Alerta    = "alerta"
  )
  for (old_name in names(rename_map)) {
    if (old_name %in% names(dados)) {
      names(dados)[names(dados) == old_name] <- rename_map[[old_name]]
    }
  }

  for (col in c("populacao_exposta", "fracao_atribuivel", "ic_inferior",
                "ic_superior", "ano", "codigo_localidade")) {
    if (col %in% names(dados)) dados[[col]] <- as.numeric(dados[[col]])
  }

  new_vigiar_tbl(
    dados,
    subclass  = c("vigiar_attributable_fraction", "vigiar_health"),
    tabela    = "tb_fracao",
    metadados = list(
      fonte       = "VIGIAR -- Ministerio da Saude",
      tabela_raw  = "tb_fracao",
      processador = "process_fracao_atribuivel"
    )
  )
}

# -- Indoor exposure processor -------------------------------------------------

#' Process indoor exposure data
#'
#' @param dados Raw data frame from \code{vigiar_baixar("df_indoor")}
#'   or \code{vigiar_baixar("df_indoor_desfecho")}.
#' @param tipo One of \code{"exposicao"} or \code{"desfecho"}.
#' @param ... Additional arguments (ignored).
#' @return A \code{vigiar_indoor} tibble.
#' @export
process_exposicao_indoor <- function(dados, tipo = c("exposicao", "desfecho"), ...) {
  tipo <- match.arg(tipo)
  dados <- tibble::as_tibble(dados)

  rename_map <- list(
    Code          = "cod_uf",
    State.x       = "sigla_uf",
    Ano           = "ano",
    parametro     = "parametro",
    sexo          = "sexo",
    pop           = "populacao",
    comb_sol_perc = "perc_combustiveis_solidos",
    comb_sol      = "prop_combustiveis_solidos",
    pop_exposta   = "populacao_exposta",
    percent_comb  = "percentual_combustiveis",
    indicador     = "indicador",
    est           = "estimativa",
    low           = "ic_inferior",
    up            = "ic_superior",
    Quartis       = "quartis",
    cor_comb      = "cor_combustiveis",
    cor_pop       = "cor_populacao",
    cor_est       = "cor_estimativa",
    CV            = "coeficiente_variacao",
    cor_CV        = "cor_cv",
    Classifc_CV   = "classificacao_cv",
    CV_comb_sol_perc = "cv_perc_combustiveis"
  )
  for (old_name in names(rename_map)) {
    if (old_name %in% names(dados)) {
      names(dados)[names(dados) == old_name] <- rename_map[[old_name]]
    }
  }

  # Numeric
  for (col in c("cod_uf", "ano", "populacao", "populacao_exposta",
                "perc_combustiveis_solidos", "prop_combustiveis_solidos",
                "percentual_combustiveis", "estimativa", "ic_inferior",
                "ic_superior", "coeficiente_variacao", "cv_perc_combustiveis")) {
    if (col %in% names(dados)) dados[[col]] <- as.numeric(dados[[col]])
  }

  tabela_raw <- if (tipo == "desfecho") "df_indoor_desfecho" else "df_indoor"

  new_vigiar_tbl(
    dados,
    subclass  = c("vigiar_indoor", "vigiar_health"),
    tabela    = tabela_raw,
    metadados = list(
      fonte       = "VIGIAR -- Ministerio da Saude",
      tabela_raw  = tabela_raw,
      tipo        = tipo,
      processador = "process_exposicao_indoor"
    )
  )
}

# -- Municipality registry processor -------------------------------------------

#' Process municipality registry data
#'
#' @param dados Raw data frame from \code{vigiar_baixar("df_muni")}.
#' @param ... Additional arguments (ignored).
#' @return A \code{vigiar_municipios} tibble.
#' @export
process_municipios <- function(dados, ...) {
  dados <- tibble::as_tibble(dados)

  rename_map <- list(
    UF_COD        = "cod_uf",
    UF_SIGLA      = "sigla_uf",
    UF_NOME       = "nome_uf",
    UF_PARSED     = "uf_formatado",
    UF_UPPER      = "uf_maiusculo",
    REGIAO        = "regiao",
    REGIAO_UPPER  = "regiao_maiusculo",
    ORDEM_REGIAO  = "ordem_regiao",
    MUN_COD       = "cod_municipio",
    MUN_NOME      = "nome_municipio",
    LAT           = "latitude",
    LON           = "longitude"
  )
  for (old_name in names(rename_map)) {
    if (old_name %in% names(dados)) {
      names(dados)[names(dados) == old_name] <- rename_map[[old_name]]
    }
  }

  if ("cod_municipio" %in% names(dados)) {
    dados$cod_municipio <- .vigiar_normalizar_codigo_municipio(dados$cod_municipio)
  }
  if ("cod_uf" %in% names(dados)) {
    dados$cod_uf <- as.integer(dados$cod_uf)
  }
  if ("latitude" %in% names(dados)) {
    dados$latitude <- as.numeric(dados$latitude)
  }
  if ("longitude" %in% names(dados)) {
    dados$longitude <- as.numeric(dados$longitude)
  }

  dados <- vigiar_validar_ibge(dados, col_codigo = "cod_municipio")

  new_vigiar_tbl(
    dados,
    subclass  = c("vigiar_municipios"),
    tabela    = "df_muni",
    metadados = list(
      fonte       = "VIGIAR -- Ministerio da Saude",
      tabela_raw  = "df_muni",
      processador = "process_municipios"
    )
  )
}

# -- Generic UF processor ------------------------------------------------------

#' Process UF-level data
#'
#' Generic processor for any UF-level VIGIAR data.
#'
#' @param dados Raw data frame.
#' @param contexto Description of the data context.
#' @return A \code{vigiar_tbl}.
#' @export
process_ufs <- function(dados, contexto = "uf") {
  dados <- tibble::as_tibble(dados)

  if ("UF" %in% names(dados)) {
    names(dados)[names(dados) == "UF"] <- "sigla_uf"
  }

  new_vigiar_tbl(
    dados,
    subclass  = c("vigiar_uf"),
    tabela    = contexto,
    metadados = list(
      fonte       = "VIGIAR -- Ministerio da Saude",
      processador = "process_ufs"
    )
  )
}
