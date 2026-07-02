# Package: vigiar
# Rio de Janeiro state registry, completeness checks, and RJ downloads
#
# Municipality codes use the 6-digit IBGE code as the package standard.
# The registry also stores the official 7-digit IBGE code for interoperability.

# ---- RJ Municipality Registry ------------------------------------------------

RJ_MUNICIPIOS <- data.frame(
  codigo_ibge = c(
    330010, 330015, 330020, 330022, 330023, 330025, 330030, 330205,
    330040, 330045, 330050, 330060, 330070, 330080, 330090, 330100,
    330110, 330093, 330115, 330120, 330130, 330095, 330140, 330150,
    330160, 330170, 330180, 330185, 330187, 330190, 330200, 330210,
    330220, 330225, 330227, 330230, 330240, 330245, 330250, 330260,
    330270, 330280, 330285, 330290, 330300, 330310, 330320, 330330,
    330340, 330350, 330360, 330370, 330380, 330385, 330390, 330395,
    330400, 330410, 330411, 330412, 330414, 330415, 330420, 330430,
    330440, 330450, 330452, 330455, 330460, 330470, 330480, 330475,
    330490, 330500, 330510, 330513, 330515, 330520, 330530, 330540,
    330550, 330555, 330560, 330570, 330575, 330580, 330590, 330600,
    330610, 330615, 330620, 330630),
  codigo_ibge_7 = c(
    3300100, 3300159, 3300209, 3300225, 3300233, 3300258, 3300308, 3302056,
    3300407, 3300456, 3300506, 3300605, 3300704, 3300803, 3300902, 3301009,
    3301108, 3300936, 3301157, 3301207, 3301306, 3300951, 3301405, 3301504,
    3301603, 3301702, 3301801, 3301850, 3301876, 3301900, 3302007, 3302106,
    3302205, 3302254, 3302270, 3302304, 3302403, 3302452, 3302502, 3302601,
    3302700, 3302809, 3302858, 3302908, 3303005, 3303104, 3303203, 3303302,
    3303401, 3303500, 3303609, 3303708, 3303807, 3303856, 3303906, 3303955,
    3304003, 3304102, 3304110, 3304128, 3304144, 3304151, 3304201, 3304300,
    3304409, 3304508, 3304524, 3304557, 3304607, 3304706, 3304805, 3304755,
    3304904, 3305000, 3305109, 3305133, 3305158, 3305208, 3305307, 3305406,
    3305505, 3305554, 3305604, 3305703, 3305752, 3305802, 3305901, 3306008,
    3306107, 3306156, 3306206, 3306305),
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
    "Norte", "Serrana", "Metropolitana I", "Baia da Ilha Grande",
    "Metropolitana II", "Centro-Sul", "Metropolitana I", "Centro-Sul",
    "Noroeste", "Noroeste", "Metropolitana I", "Metropolitana II",
    "Serrana", "Metropolitana I", "Metropolitana I", "Centro-Sul",
    "Baia da Ilha Grande", "Centro-Sul", "Serrana", "Medio Paraiba",
    "Medio Paraiba", "Noroeste", "Medio Paraiba", "Medio Paraiba",
    "Metropolitana I", "Norte", "Medio Paraiba", "Metropolitana II",
    "Medio Paraiba", "Medio Paraiba", "Norte", "Metropolitana I",
    "Serrana", "Noroeste", "Norte", "Norte",
    "Metropolitana II", "Norte", "Metropolitana I", "Noroeste",
    "Serrana", "Baixada Litoranea", "Serrana", "Centro-Sul",
    "Baixada Litoranea", "Metropolitana I", "Metropolitana II", "Serrana",
    "Metropolitana II", "Serrana", "Serrana", "Centro-Sul",
    "Medio Paraiba", "Noroeste", "Centro-Sul", "Medio Paraiba"),
  stringsAsFactors = FALSE
)

RJ_MUNICIPIOS$codigo_ibge_6 <- RJ_MUNICIPIOS$codigo_ibge
RJ_MUNICIPIOS$regiao_saude <- RJ_MUNICIPIOS$macrorregiao_saude
RJ_MUNICIPIOS <- RJ_MUNICIPIOS[
  c("codigo_ibge", "codigo_ibge_6", "codigo_ibge_7", "municipio",
    "macrorregiao_saude", "regiao_saude")
]

RJ_CODIGOS_VALIDOS <- c(
  "RJ", "rj", "Rio de Janeiro", "RIO DE JANEIRO"
)

RJ_MUNI_RANGE <- c(330010L, 330630L)

# ---- RJ-specific functions ---------------------------------------------------

#' List all 92 Rio de Janeiro municipalities
#'
#' The package standard is the 6-digit IBGE municipality code
#' (`codigo_ibge` / `codigo_ibge_6`). The 7-digit official IBGE code is also
#' returned as `codigo_ibge_7` for joins with sources that use the check digit.
#'
#' @return A tibble with municipality codes, municipality names, health
#'   macro-regions, and health regions.
#' @export
vigiar_rj_municipios <- function() {
  tibble::as_tibble(RJ_MUNICIPIOS)
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
  dados_rj <- .vigiar_filtrar_rj(dados, validar = FALSE)

  if (nrow(dados_rj) == 0) {
    warning("No Rio de Janeiro municipality was found in the data.", call. = FALSE)
    return(tibble::tibble())
  }

  merged <- merge(
    dados_rj,
    RJ_MUNICIPIOS,
    by.x = "codigo_ibge_6",
    by.y = "codigo_ibge_6",
    all.x = TRUE,
    suffixes = c("", "_rj")
  )

  grp <- switch(agregacao,
    municipio = "municipio",
    macrorregiao = "macrorregiao_saude",
    regiao_saude = "regiao_saude"
  )

  num_cols <- names(merged)[vapply(merged, is.numeric, logical(1))]
  num_cols <- setdiff(num_cols, c("codigo_ibge", "codigo_ibge_6", "codigo_ibge_7",
                                  "cod_municipio", "ano", "mes"))

  if (length(num_cols) == 0) {
    return(tibble::as_tibble(merged))
  }

  result <- merged |>
    dplyr::group_by(dplyr::across(dplyr::all_of(grp))) |>
    dplyr::summarise(
      n_municipios = dplyr::n_distinct(.data[["codigo_ibge_6"]]),
      dplyr::across(
        dplyr::all_of(num_cols),
        list(
          mean = ~mean(.x, na.rm = TRUE),
          sd = ~stats::sd(.x, na.rm = TRUE),
          n = ~sum(!is.na(.x))
        ),
        .names = "{.col}_{.fn}"
      ),
      .groups = "drop"
    )

  tibble::as_tibble(result)
}

#' Aggregate Rio de Janeiro data by health region
#'
#' @param dados A processed VIGIAR tibble with municipality codes.
#' @param agregacao "macrorregiao" or "regiao_saude".
#' @return A tibble with aggregated data.
#' @export
vigiar_rj_series <- function(dados, agregacao = c("macrorregiao", "regiao_saude")) {
  agregacao <- match.arg(agregacao)
  vigiar_rj_resumo(dados, agregacao = agregacao)
}

#' Validate that data contains only RJ municipalities
#'
#' Checks municipality codes, flags non-RJ municipalities, and reports missing
#' Rio de Janeiro municipalities using the internal 92-municipality registry.
#'
#' @param dados A data frame with a municipality code column.
#' @param col_muni Name of the municipality code column (auto-detected).
#' @return Invisibly, a list with validation results.
#' @export
vigiar_validar_rj <- function(dados, col_muni = NULL) {
  col_muni <- col_muni %||% .vigiar_coluna_municipio(dados)
  if (is.na(col_muni)) {
    stop("Municipality code column not found.", call. = FALSE)
  }

  codigos <- unique(.vigiar_normalizar_codigo_municipio(dados[[col_muni]]))
  codigos <- codigos[!is.na(codigos)]

  if (length(codigos) == 0) {
    message("No valid municipality code was found in the data.")
    return(invisible(list(n_total = 0, n_rj = 0, n_fora_rj = 0, valido = TRUE)))
  }

  rj_codes <- RJ_MUNICIPIOS$codigo_ibge_6
  in_rj <- sort(intersect(codigos, rj_codes))
  fora_rj <- sort(setdiff(codigos, rj_codes))
  faltantes <- sort(setdiff(rj_codes, in_rj))

  result <- list(
    n_total = length(codigos),
    n_rj = length(in_rj),
    n_fora_rj = length(fora_rj),
    codigos_fora_rj = fora_rj,
    municipios_rj_faltantes = faltantes,
    valido = length(fora_rj) == 0
  )

  if (!result$valido) {
    warning(sprintf(
      "%d municipality code(s) do not belong to Rio de Janeiro: %s",
      length(fora_rj), paste(utils::head(fora_rj, 10), collapse = ", ")
    ), call. = FALSE)
  }

  if (length(faltantes) > 0) {
    message(sprintf(
      "%d Rio de Janeiro municipalities are absent from the data.",
      length(faltantes)
    ))
  } else {
    message("OK: all 92 Rio de Janeiro municipalities are present.")
  }

  invisible(result)
}

#' Download Rio de Janeiro VIGIAR data with completeness metadata
#'
#' Downloads one VIGIAR table, filters Rio de Janeiro with the internal
#' 92-municipality registry, normalizes municipality codes, and attaches
#' coverage and truncation metadata to the returned tibble.
#'
#' @param tabela Table name.
#' @param colunas Optional character vector of column names.
#' @param ordenar_por Optional column used to sort the Power BI query.
#' @param limite Optional row limit passed to the Power BI query.
#' @param timeout Timeout in seconds for the HTTP request.
#' @param validar_cobertura If \code{TRUE}, report RJ coverage after download.
#' @param exigir_completo If \code{TRUE}, error unless all 92 municipalities
#'   are present.
#' @param require_complete English alias for \code{exigir_completo}. When
#'   \code{TRUE}, possible API truncation is also an error.
#' @param processar If \code{TRUE}, process the table after filtering.
#' @param tipo Optional processor type, used mainly for PM2.5 tables.
#' @param usar_cache If \code{TRUE}, reuse a local RJ-specific cache entry.
#' @param snapshot If \code{TRUE}, attach a \code{vigiar_snapshot} attribute.
#' @param ... Additional arguments passed to \code{vigiar_baixar()}.
#' @return A tibble containing RJ-only data and RJ coverage attributes.
#' @export
vigiar_baixar_rj <- function(
  tabela,
  colunas = NULL,
  ordenar_por = NULL,
  limite = NULL,
  timeout = 120,
  validar_cobertura = TRUE,
  exigir_completo = FALSE,
  require_complete = exigir_completo,
  processar = FALSE,
  tipo = NULL,
  usar_cache = FALSE,
  snapshot = FALSE,
  ...
) {
  if (is.null(.vigiar_env$sessao)) {
    stop("No active session. Run vigiar_conectar() first.", call. = FALSE)
  }
  .vigiar_check_tabela(tabela)
  complete_required <- isTRUE(exigir_completo) || isTRUE(require_complete)

  dots <- list(...)
  if (!is.null(dots$cache)) {
    usar_cache <- isTRUE(dots$cache)
    dots$cache <- NULL
    warning("Argument 'cache' is deprecated for vigiar_baixar_rj(); use 'usar_cache'.",
            call. = FALSE)
  }
  dots$uf <- NULL
  dots$strategy <- NULL
  schema_hash <- .vigiar_schema_hash(tabela)
  cache_file <- NULL

  if (isTRUE(usar_cache)) {
    cache_file <- .vigiar_rj_cache_file(
      tabela = tabela,
      colunas = colunas,
      ordenar_por = ordenar_por,
      limite = limite,
      schema_hash = schema_hash,
      dots = dots
    )
    if (file.exists(cache_file)) {
      cached <- readRDS(cache_file)
      cli::cli_alert_success("RJ cache hit: {tabela}")
      return(cached)
    }
  }

  args <- c(
    list(
      tabela = tabela,
      colunas = colunas,
      ordenar_por = ordenar_por,
      limite = limite,
      timeout = timeout,
      uf = NULL
    ),
    dots
  )

  dados <- do.call(vigiar_baixar, args)
  dados <- .vigiar_detectar_truncamento(dados, tabela = tabela, limite = limite)
  possivel_truncamento <- isTRUE(attr(dados, "vigiar_possivel_truncamento"))
  if (isTRUE(possivel_truncamento) && isTRUE(complete_required)) {
    stop(
      "Possible API truncation was detected; complete RJ data cannot be guaranteed. ",
      "Use a validated partitioned download before running scientific analyses.",
      call. = FALSE
    )
  }

  dados_rj <- .vigiar_filtrar_rj(dados, validar = FALSE)
  has_municipality <- !is.na(.vigiar_coluna_municipio(dados_rj))
  if (!has_municipality) {
    msg <- sprintf(
      "Table '%s' has no municipality code column; RJ 92-municipality completeness cannot be evaluated.",
      tabela
    )
    if (isTRUE(validar_cobertura) || isTRUE(complete_required)) {
      stop(msg, call. = FALSE)
    }
    warning(msg, call. = FALSE)
  }

  cobertura <- vigiar_rj_cobertura(
    dados_rj,
    por = "geral",
    exigir_coluna_municipio = has_municipality
  )

  if (isTRUE(validar_cobertura)) {
    .vigiar_emitir_cobertura_rj(cobertura)
  }

  completo <- isTRUE(cobertura$completo[[1]])
  if (isTRUE(complete_required) && !completo) {
    ausentes <- cobertura$municipios_ausentes[[1]]
    stop(
      sprintf(
        "RJ coverage is incomplete: %d/92 municipalities present. Missing: %s",
        cobertura$n_municipios_presentes[[1]],
        paste(utils::head(ausentes, 20), collapse = ", ")
      ),
      call. = FALSE
    )
  }

  if (isTRUE(processar)) {
    dados_rj <- .vigiar_processar_tabela_rj(dados_rj, tabela = tabela, tipo = tipo)
  }

  dados_rj <- .vigiar_anexar_metadados_rj(
    dados_rj,
    tabela = tabela,
    cobertura = cobertura,
    possivel_truncamento = possivel_truncamento,
    schema_hash = schema_hash
  )

  if (isTRUE(snapshot)) {
    attr(dados_rj, "vigiar_snapshot") <- vigiar_snapshot(dados = dados_rj, tabela = tabela)
  }

  if (isTRUE(usar_cache) && !is.null(cache_file)) {
    dir.create(dirname(cache_file), recursive = TRUE, showWarnings = FALSE)
    saveRDS(dados_rj, cache_file)
    cli::cli_alert_success("RJ cache saved: {tabela}")
  }

  tibble::as_tibble(dados_rj)
}

#' Download one Rio de Janeiro municipality
#'
#' Downloads an RJ-scoped VIGIAR table and returns rows for a single
#' municipality, identified only by IBGE code. This avoids fragile filters based
#' on municipality names.
#'
#' @param tabela Table name.
#' @param codigo_ibge 6- or 7-digit IBGE municipality code.
#' @param colunas Optional character vector of column names.
#' @param ordenar_por Optional column used to sort the Power BI query.
#' @param limite Optional row limit passed to the Power BI query.
#' @param timeout Timeout in seconds.
#' @param exigir_dados If \code{TRUE}, error when the municipality has no rows.
#' @param require_complete If \code{TRUE}, possible API truncation is an error.
#' @param processar If \code{TRUE}, process the table after filtering.
#' @param tipo Optional processor type.
#' @param usar_cache If \code{TRUE}, reuse the RJ download cache.
#' @param snapshot If \code{TRUE}, attach a \code{vigiar_snapshot} attribute.
#' @param ... Additional arguments passed to \code{vigiar_baixar_rj()}.
#' @return A tibble for one RJ municipality with municipality metadata.
#' @export
vigiar_baixar_municipio <- function(
  tabela,
  codigo_ibge,
  colunas = NULL,
  ordenar_por = NULL,
  limite = NULL,
  timeout = 120,
  exigir_dados = FALSE,
  require_complete = FALSE,
  processar = FALSE,
  tipo = NULL,
  usar_cache = FALSE,
  snapshot = FALSE,
  ...
) {
  codigo6 <- .vigiar_normalizar_codigo_municipio(codigo_ibge, formato = "6")
  if (length(codigo6) != 1L || is.na(codigo6)) {
    stop("codigo_ibge must be one valid 6- or 7-digit IBGE municipality code.",
         call. = FALSE)
  }
  if (!codigo6 %in% RJ_MUNICIPIOS$codigo_ibge_6) {
    stop("codigo_ibge does not identify a Rio de Janeiro municipality.",
         call. = FALSE)
  }

  dados_rj <- vigiar_baixar_rj(
    tabela = tabela,
    colunas = colunas,
    ordenar_por = ordenar_por,
    limite = limite,
    timeout = timeout,
    validar_cobertura = FALSE,
    exigir_completo = FALSE,
    require_complete = FALSE,
    processar = processar,
    tipo = tipo,
    usar_cache = usar_cache,
    snapshot = FALSE,
    ...
  )

  if (isTRUE(require_complete) &&
      isTRUE(attr(dados_rj, "vigiar_possivel_truncamento"))) {
    stop(
      "Possible API truncation was detected; complete municipality data cannot be guaranteed.",
      call. = FALSE
    )
  }

  out <- dados_rj[dados_rj$codigo_ibge_6 == codigo6, , drop = FALSE]
  reg <- RJ_MUNICIPIOS[RJ_MUNICIPIOS$codigo_ibge_6 == codigo6, ]

  if (nrow(out) == 0) {
    msg <- sprintf(
      "No rows were returned for municipality %s (%s) in table '%s'.",
      reg$municipio[[1]], codigo6, tabela
    )
    if (isTRUE(exigir_dados)) {
      stop(msg, call. = FALSE)
    }
    warning(msg, call. = FALSE)
  }

  attr(out, "vigiar_tabela") <- tabela
  attr(out, "vigiar_uf") <- "RJ"
  attr(out, "vigiar_codigo_ibge_6") <- codigo6
  attr(out, "vigiar_codigo_ibge_7") <- reg$codigo_ibge_7[[1]]
  attr(out, "vigiar_municipio") <- reg$municipio[[1]]
  attr(out, "vigiar_macrorregiao_saude") <- reg$macrorregiao_saude[[1]]
  attr(out, "vigiar_regiao_saude") <- reg$regiao_saude[[1]]
  attr(out, "vigiar_municipio_presente") <- nrow(out) > 0
  attr(out, "vigiar_municipio_linhas") <- nrow(out)
  attr(out, "vigiar_possivel_truncamento") <- isTRUE(attr(dados_rj, "vigiar_possivel_truncamento"))
  attr(out, "vigiar_download_timestamp") <- Sys.time()

  if (isTRUE(snapshot)) {
    attr(out, "vigiar_snapshot") <- vigiar_snapshot(dados = out, tabela = tabela)
  }

  tibble::as_tibble(out)
}

#' Download Rio de Janeiro VIGIAR data using smaller partitions
#'
#' This is a preparatory interface for partitioned RJ downloads. The current
#' public Power BI query builder does not yet expose reliable server-side
#' filters by year, month, or municipality, so non-auto partitioning stops with
#' an explicit message instead of pretending that the result is complete.
#'
#' @param tabela Table name.
#' @param por Partitioning strategy.
#' @param anos Optional years to download.
#' @param meses Optional months to download.
#' @param municipios Optional municipality codes to download.
#' @param timeout Timeout in seconds.
#' @param delay Delay between partitions.
#' @param validar_cobertura If \code{TRUE}, validate final RJ coverage.
#' @param exigir_completo If \code{TRUE}, error unless all expected RJ
#'   municipalities are present in the final result.
#' @param require_complete English alias for \code{exigir_completo}.
#' @param ... Additional arguments passed to \code{vigiar_baixar_rj()}.
#' @return A tibble from \code{vigiar_baixar_rj()} when \code{por = "auto"}.
#' @export
vigiar_baixar_rj_completo <- function(
  tabela,
  por = c("auto", "ano", "mes", "municipio"),
  anos = NULL,
  meses = NULL,
  municipios = NULL,
  timeout = 120,
  delay = 0.5,
  validar_cobertura = TRUE,
  exigir_completo = FALSE,
  require_complete = exigir_completo,
  ...
) {
  por <- match.arg(por)
  if (por != "auto") {
    stop(
      "Partitioned RJ downloads are not available yet because the current ",
      "Power BI query builder has no validated server-side filters by year, ",
      "month, or municipality. Use vigiar_baixar_rj() and inspect the ",
      "vigiar_possivel_truncamento attribute.",
      call. = FALSE
    )
  }

  dados <- vigiar_baixar_rj(
    tabela = tabela,
    timeout = timeout,
    validar_cobertura = validar_cobertura,
    exigir_completo = exigir_completo,
    require_complete = require_complete,
    ...
  )

  if (isTRUE(attr(dados, "vigiar_possivel_truncamento"))) {
    warning(
      "Possible truncation remains after the auto download. A validated ",
      "server-side partition strategy is required before claiming completeness.",
      call. = FALSE
    )
  }

  dados
}

#' Measure Rio de Janeiro municipality coverage
#'
#' @param dados A data frame with a municipality code column.
#' @param por Coverage level: overall, by year, by month, by year-month,
#'   by health macro-region, or by health region.
#' @param exigir_coluna_municipio If \code{TRUE}, error when no municipality
#'   code column can be detected. If \code{FALSE}, return an explicit unknown
#'   coverage row.
#' @return A tibble with coverage metrics and list-columns for absent
#'   municipalities, absent codes, and incomplete macro-regions.
#' @export
vigiar_rj_cobertura <- function(
  dados,
  por = c("geral", "ano", "mes", "ano_mes", "macrorregiao", "regiao_saude"),
  exigir_coluna_municipio = TRUE
) {
  por <- match.arg(por)
  dados <- tibble::as_tibble(dados)
  col_muni <- .vigiar_coluna_municipio(dados)
  possivel_truncamento <- isTRUE(attr(dados, "vigiar_possivel_truncamento"))

  if (is.na(col_muni)) {
    msg <- "Municipality code column not found; RJ coverage is unknown."
    if (isTRUE(exigir_coluna_municipio)) {
      stop(msg, call. = FALSE)
    }
    warning(msg, call. = FALSE)
    return(.vigiar_cobertura_sem_municipio(por, possivel_truncamento))
  }

  dados$codigo_ibge_6__vigiar <- .vigiar_normalizar_codigo_municipio(dados[[col_muni]])
  groups <- .vigiar_grupos_cobertura(dados, por)
  rows <- lapply(groups, function(g) {
    .vigiar_cobertura_linha(
      dados = dados[g$idx, , drop = FALSE],
      por = g$por,
      ano = g$ano,
      mes = g$mes,
      macrorregiao_saude = g$macrorregiao_saude,
      regiao_saude = g$regiao_saude,
      expected_codes = g$expected_codes,
      possivel_truncamento = possivel_truncamento
    )
  })

  out <- do.call(rbind.data.frame, lapply(rows, function(row) {
    data.frame(
      por = row$por,
      nivel = row$por,
      ano = row$ano,
      mes = row$mes,
      macrorregiao_saude = row$macrorregiao_saude,
      regiao_saude = row$regiao_saude,
      n_municipios_presentes = row$n_municipios_presentes,
      n_municipios_esperados = row$n_municipios_esperados,
      cobertura_pct = row$cobertura_pct,
      n_ausentes = row$n_ausentes,
      completo = row$completo,
      possivel_truncamento = row$possivel_truncamento,
      stringsAsFactors = FALSE
    )
  }))
  out$municipios_ausentes <- I(lapply(rows, `[[`, "municipios_ausentes"))
  out$codigos_ausentes <- I(lapply(rows, `[[`, "codigos_ausentes"))
  out$macrorregioes_incompletas <- I(lapply(rows, `[[`, "macrorregioes_incompletas"))
  tibble::as_tibble(out)
}

#' Check RJ completeness using the table's expected panel grain
#'
#' This function distinguishes "data were downloaded" from "the expected RJ
#' panel is complete". For `df_mensal`, completeness is assessed by
#' municipality x year x month. For `df_anual` and `df_dias`, completeness is
#' assessed by municipality x year when a year column exists.
#'
#' @param dados A data frame with municipality codes.
#' @param tabela Optional table name. Defaults to the `vigiar_tabela` attribute.
#' @param require_complete If \code{TRUE}, incomplete coverage or possible
#'   truncation is an error.
#' @return A tibble with RJ coverage metrics at the expected table grain.
#' @export
vigiar_rj_completude_tabela <- function(dados, tabela = NULL, require_complete = FALSE) {
  tabela <- tabela %||% attr(dados, "vigiar_tabela") %||% "dados"
  dados <- tibble::as_tibble(dados)
  por <- .vigiar_cobertura_por_tabela(tabela, dados)

  cobertura <- vigiar_rj_cobertura(dados, por = por)
  cobertura$tabela <- tabela
  cobertura$grade <- .vigiar_grade_cobertura_label(tabela, por)
  cobertura <- cobertura[
    c("tabela", "grade", setdiff(names(cobertura), c("tabela", "grade")))
  ]

  incomplete <- any(!cobertura$completo)
  truncated <- any(cobertura$possivel_truncamento)
  if (isTRUE(require_complete) && (incomplete || truncated)) {
    if (truncated) {
      stop(
        "Possible API truncation was detected; complete RJ table coverage cannot be guaranteed.",
        call. = FALSE
      )
    }
    stop(
      sprintf("RJ table coverage is incomplete for '%s' at grain '%s'.",
              tabela, unique(cobertura$grade)[[1]]),
      call. = FALSE
    )
  }

  cobertura
}

#' List absent Rio de Janeiro municipalities
#'
#' @param dados A data frame with a municipality code column.
#' @param por Missingness level: overall, by year, by month, by year-month,
#'   by health macro-region, or by health region.
#' @return A tibble with one row per absent municipality per level.
#' @export
vigiar_rj_municipios_ausentes <- function(
  dados,
  por = c("geral", "ano", "mes", "ano_mes", "macrorregiao", "regiao_saude")
) {
  por <- match.arg(por)

  cobertura <- suppressWarnings(vigiar_rj_cobertura(
    dados,
    por = por,
    exigir_coluna_municipio = FALSE
  ))

  out <- lapply(seq_len(nrow(cobertura)), function(i) {
    codes <- cobertura$codigos_ausentes[[i]]
    reg <- RJ_MUNICIPIOS[RJ_MUNICIPIOS$codigo_ibge_6 %in% codes, ]
    if (nrow(reg) == 0) {
      return(NULL)
    }
    reg$por <- cobertura$por[[i]]
    reg$nivel <- cobertura$por[[i]]
    reg$ano <- cobertura$ano[[i]]
    reg$mes <- cobertura$mes[[i]]
    reg$grupo_macrorregiao_saude <- cobertura$macrorregiao_saude[[i]]
    reg$grupo_regiao_saude <- cobertura$regiao_saude[[i]]
    reg[c(
      "por", "nivel", "ano", "mes", "grupo_macrorregiao_saude",
      "grupo_regiao_saude", "codigo_ibge", "codigo_ibge_6",
      "codigo_ibge_7", "municipio", "macrorregiao_saude", "regiao_saude"
    )]
  })
  out <- out[!vapply(out, is.null, logical(1))]

  if (length(out) == 0) {
    return(tibble::tibble(
      por = character(0),
      nivel = character(0),
      ano = integer(0),
      mes = integer(0),
      grupo_macrorregiao_saude = character(0),
      grupo_regiao_saude = character(0),
      codigo_ibge = integer(0),
      codigo_ibge_6 = integer(0),
      codigo_ibge_7 = integer(0),
      municipio = character(0),
      macrorregiao_saude = character(0),
      regiao_saude = character(0)
    ))
  }

  tibble::as_tibble(do.call(rbind.data.frame, out))
}

#' Exploratory PM2.5 plot for Rio de Janeiro data
#'
#' @param dados A data frame already downloaded and processed by vigiar.
#' @param por Grouping level: "ano", "macrorregiao", or "municipio".
#' @param valor Optional PM2.5 value column. If \code{NULL}, it is detected.
#' @return A ggplot object.
#' @export
vigiar_plot_pm25_rj <- function(dados, por = c("ano", "macrorregiao", "municipio"), valor = NULL) {
  por <- match.arg(por)
  if (!requireNamespace("ggplot2", quietly = TRUE)) {
    stop("Package 'ggplot2' is required for vigiar_plot_pm25_rj().", call. = FALSE)
  }

  dados <- .vigiar_filtrar_rj(dados, validar = FALSE)
  if (nrow(dados) == 0) {
    stop("No RJ municipality was detected in the data.", call. = FALSE)
  }

  valor <- valor %||% .vigiar_coluna_pm25(dados)
  if (is.na(valor) || !valor %in% names(dados)) {
    stop("PM2.5 value column not found.", call. = FALSE)
  }

  dados <- merge(dados, RJ_MUNICIPIOS, by = "codigo_ibge_6", all.x = TRUE,
                 suffixes = c("", "_rj"))
  dados[[valor]] <- as.numeric(dados[[valor]])

  if (por == "ano") {
    if (!"ano" %in% names(dados)) {
      stop("Column 'ano' is required for por = 'ano'.", call. = FALSE)
    }
    plot_data <- stats::aggregate(dados[[valor]], list(ano = dados$ano), mean, na.rm = TRUE)
    names(plot_data)[2] <- "pm25"
    return(ggplot2::ggplot(plot_data, ggplot2::aes(.data[["ano"]], .data[["pm25"]])) +
      ggplot2::geom_line() +
      ggplot2::geom_point() +
      ggplot2::labs(x = "Year", y = "PM2.5", title = "RJ mean PM2.5 by year"))
  }

  group_col <- if (por == "macrorregiao") "macrorregiao_saude" else "municipio"
  plot_data <- stats::aggregate(dados[[valor]], list(grupo = dados[[group_col]]), mean, na.rm = TRUE)
  names(plot_data)[2] <- "pm25"
  ggplot2::ggplot(plot_data, ggplot2::aes(.data[["pm25"]], stats::reorder(.data[["grupo"]], .data[["pm25"]]))) +
    ggplot2::geom_col() +
    ggplot2::labs(x = "Mean PM2.5", y = NULL, title = paste("RJ PM2.5 by", por))
}

# ---- Internal helpers ---------------------------------------------------------

.vigiar_coluna_municipio <- function(dados) {
  intersect(
    c("codigo_ibge_6", "cod_municipio", "muni", "id_muni", "ID_MUNI",
      "codigo_ibge", "cod_ibge", "codigo_municipio", "MUN_COD",
      "cod_municipio_6", "cod_municipio_7", "codigo_ibge_7"),
    names(dados)
  )[1]
}

.vigiar_coluna_uf <- function(dados) {
  intersect(c("sigla_uf", "UF", "UF_SIGLA", "uf", "cod_uf"), names(dados))[1]
}

.vigiar_coluna_pm25 <- function(dados) {
  intersect(c("pm25_media_anual", "pm25_media", "pm25",
              "Media_pm25", "pm25_media_periodo"), names(dados))[1]
}

.vigiar_cobertura_por_tabela <- function(tabela, dados) {
  tabela <- tabela %||% ""
  if (identical(tabela, "df_mensal")) {
    if (!all(c("ano", "mes") %in% names(dados))) {
      stop("Table 'df_mensal' requires 'ano' and 'mes' columns for RJ completeness.",
           call. = FALSE)
    }
    return("ano_mes")
  }

  if (tabela %in% c("df_anual", "df_dias", "df_dias_conama")) {
    if ("ano" %in% names(dados)) {
      return("ano")
    }
    return("geral")
  }

  if (all(c("ano", "mes") %in% names(dados))) {
    return("ano_mes")
  }
  if ("ano" %in% names(dados)) {
    return("ano")
  }
  "geral"
}

.vigiar_grade_cobertura_label <- function(tabela, por) {
  switch(por,
    ano_mes = "municipio x ano x mes",
    ano = "municipio x ano",
    mes = "municipio x mes",
    geral = "municipio",
    macrorregiao = "macrorregiao",
    regiao_saude = "regiao_saude",
    por
  )
}

.vigiar_normalizar_codigo_municipio <- function(x, formato = c("auto", "6", "7")) {
  formato <- match.arg(formato)
  if (length(x) == 0) {
    return(integer(0))
  }

  out6 <- rep(NA_integer_, length(x))
  out7 <- rep(NA_integer_, length(x))
  missing <- is.na(x)
  chr <- trimws(as.character(x))
  chr[missing] <- NA_character_
  chr <- sub("\\.0+$", "", chr)
  valid_digits <- !is.na(chr) & nzchar(chr) & grepl("^[0-9]+$", chr)

  is_6 <- valid_digits & nchar(chr) == 6
  if (any(is_6)) {
    val <- suppressWarnings(as.integer(chr[is_6]))
    ok <- !is.na(val) & val >= 110001L & val <= 530010L
    idx <- which(is_6)
    out6[idx[ok]] <- val[ok]
    match_rj <- match(val[ok], RJ_MUNICIPIOS$codigo_ibge_6)
    has_rj <- !is.na(match_rj)
    if (any(has_rj)) {
      out7[idx[ok][has_rj]] <- RJ_MUNICIPIOS$codigo_ibge_7[match_rj[has_rj]]
    }
  }

  is_7 <- valid_digits & nchar(chr) == 7
  if (any(is_7)) {
    val7 <- suppressWarnings(as.integer(chr[is_7]))
    val6 <- suppressWarnings(as.integer(substr(chr[is_7], 1, 6)))
    ok <- !is.na(val6) & val6 >= 110001L & val6 <= 530010L
    rj_idx <- match(val6, RJ_MUNICIPIOS$codigo_ibge_6)
    is_rj_code <- !is.na(rj_idx)
    official_rj_7 <- rep(FALSE, length(val7))
    official_rj_7[is_rj_code] <- val7[is_rj_code] == RJ_MUNICIPIOS$codigo_ibge_7[rj_idx[is_rj_code]]
    ok <- ok & (!is_rj_code | official_rj_7)
    idx <- which(is_7)
    out6[idx[ok]] <- val6[ok]
    out7[idx[ok]] <- val7[ok]
  }

  if (formato == "7") {
    return(out7)
  }

  out6
}

.vigiar_filtrar_rj <- function(dados, validar = TRUE) {
  dados <- tibble::as_tibble(dados)
  col_muni <- .vigiar_coluna_municipio(dados)
  col_uf <- .vigiar_coluna_uf(dados)

  if (!is.na(col_muni)) {
    before <- nrow(dados)
    dados$codigo_ibge_6 <- .vigiar_normalizar_codigo_municipio(dados[[col_muni]])
    idx <- !is.na(dados$codigo_ibge_6) &
      dados$codigo_ibge_6 %in% RJ_MUNICIPIOS$codigo_ibge_6
    dados <- dados[idx, , drop = FALSE]
    lookup <- match(dados$codigo_ibge_6, RJ_MUNICIPIOS$codigo_ibge_6)
    dados$codigo_ibge_7 <- RJ_MUNICIPIOS$codigo_ibge_7[lookup]
    cli::cli_alert_info("RJ filter by municipality registry: {nrow(dados)} rows from {before}.")
  } else if (!is.na(col_uf)) {
    before <- nrow(dados)
    if (is.numeric(dados[[col_uf]])) {
      dados <- dados[as.integer(dados[[col_uf]]) == 33L, , drop = FALSE]
    } else {
      dados <- dados[toupper(as.character(dados[[col_uf]])) %in% c("RJ", "RIO DE JANEIRO"), , drop = FALSE]
    }
    cli::cli_alert_warning(
      "RJ filter used UF column '{col_uf}' because no municipality code column was found."
    )
    cli::cli_alert_info("RJ filter by UF: {nrow(dados)} rows from {before}.")
  } else {
    warning(
      "No municipality or UF column was found. The data were not filtered to RJ.",
      call. = FALSE
    )
  }

  if (isTRUE(validar) && nrow(dados) > 0 && !is.na(.vigiar_coluna_municipio(dados))) {
    vigiar_validar_rj(dados)
  }

  tibble::as_tibble(dados)
}

.vigiar_detectar_truncamento <- function(dados, tabela = NULL, limite = NULL) {
  n <- nrow(dados)
  table_label <- tabela %||% "<unknown>"
  power_bi_threshold <- 28500L
  explicit_limit_threshold <- if (is.null(limite)) Inf else max(1L, floor(0.95 * as.integer(limite)))
  possible <- isTRUE(attr(dados, "vigiar_possivel_truncamento")) ||
    (n > 0 && n >= power_bi_threshold) ||
    (n > 0 && n >= explicit_limit_threshold)
  attr(dados, "vigiar_possivel_truncamento") <- possible

  if (isTRUE(possible)) {
    msg <- if (is.null(limite)) {
      sprintf(
        "Possible truncation: table '%s' returned %d rows, close to the Power BI API limit.",
        table_label, n
      )
    } else {
      sprintf(
        "Possible truncation: table '%s' returned %d rows, close to or above the requested limit of %d.",
        table_label, n, as.integer(limite)
      )
    }
    .vigiar_log("WARN", msg, table = table_label)
    warning(
      msg,
      " Download by validated partitions before claiming completeness.",
      call. = FALSE
    )
  }

  dados
}

.vigiar_schema_hash <- function(tabela) {
  if (is.null(.vigiar_env$esquema) || is.null(.vigiar_env$esquema[[tabela]])) {
    return(NA_character_)
  }
  raw <- serialize(.vigiar_env$esquema[[tabela]], NULL)
  as.character(openssl::sha256(raw))
}

.vigiar_rj_cache_file <- function(tabela, colunas, ordenar_por, limite, schema_hash, dots) {
  cache_dir <- .vigiar_env$cache_dir %||% file.path(tools::R_user_dir("vigiar", "cache"))
  .vigiar_env$cache_dir <- cache_dir
  key <- list(
    tabela = tabela,
    uf = "RJ",
    colunas = colunas,
    ordenar_por = ordenar_por,
    limite = limite,
    schema_hash = schema_hash,
    dots = dots
  )
  key_raw <- serialize(key, NULL)
  key_hash <- as.character(openssl::sha256(key_raw))
  file.path(cache_dir, paste0("rj-", tabela, "-", substr(key_hash, 1, 16), ".rds"))
}

.vigiar_processar_tabela_rj <- function(dados, tabela, tipo = NULL) {
  if (!is.null(tipo) && tabela %in% c("df_anual", "df_mensal", "df_dias", "df_dias_conama")) {
    return(process_pm25(dados, tipo = tipo))
  }
  process_vigiar(dados, tabela = tabela)
}

.vigiar_anexar_metadados_rj <- function(dados, tabela, cobertura,
                                         possivel_truncamento, schema_hash) {
  attr(dados, "vigiar_tabela") <- tabela
  attr(dados, "vigiar_uf") <- "RJ"
  attr(dados, "vigiar_rj_n_municipios") <- cobertura$n_municipios_presentes[[1]]
  attr(dados, "vigiar_rj_n_esperado") <- cobertura$n_municipios_esperados[[1]]
  attr(dados, "vigiar_rj_cobertura_pct") <- cobertura$cobertura_pct[[1]]
  attr(dados, "vigiar_rj_municipios_ausentes") <- cobertura$municipios_ausentes[[1]]
  attr(dados, "vigiar_n_municipios_presentes") <- cobertura$n_municipios_presentes[[1]]
  attr(dados, "vigiar_n_municipios_esperados") <- cobertura$n_municipios_esperados[[1]]
  attr(dados, "vigiar_cobertura_rj_pct") <- cobertura$cobertura_pct[[1]]
  attr(dados, "vigiar_municipios_ausentes") <- cobertura$municipios_ausentes[[1]]
  attr(dados, "vigiar_download_timestamp") <- Sys.time()
  attr(dados, "vigiar_schema_hash") <- schema_hash
  attr(dados, "vigiar_possivel_truncamento") <- possivel_truncamento
  attr(dados, "vigiar_rj_cobertura") <- cobertura
  dados
}

.vigiar_emitir_cobertura_rj <- function(cobertura) {
  n <- cobertura$n_municipios_presentes[[1]]
  pct <- cobertura$cobertura_pct[[1]]

  if (n == 92L) {
    cli::cli_alert_success("OK: complete RJ coverage, 92/92 municipalities.")
  } else if (n == 0L) {
    warning(
      "Critical: no valid Rio de Janeiro municipality code was detected.",
      call. = FALSE
    )
  } else {
    warning(sprintf(
      "Warning: partial RJ coverage, %d/92 municipalities (%.1f%%).",
      n, pct
    ), call. = FALSE)
  }

  if (isTRUE(cobertura$possivel_truncamento[[1]])) {
    warning(
      "Possible truncation: the response reached an approximate API limit; use a validated partitioned download.",
      call. = FALSE
    )
  }
}

.vigiar_cobertura_sem_municipio <- function(por, possivel_truncamento) {
  row <- data.frame(
    por = por,
    nivel = por,
    ano = NA_integer_,
    mes = NA_integer_,
    macrorregiao_saude = NA_character_,
    regiao_saude = NA_character_,
    n_municipios_presentes = 0L,
    n_municipios_esperados = 92L,
    cobertura_pct = 0,
    n_ausentes = 92L,
    completo = FALSE,
    possivel_truncamento = possivel_truncamento,
    stringsAsFactors = FALSE
  )
  row$municipios_ausentes <- I(list(RJ_MUNICIPIOS$municipio))
  row$codigos_ausentes <- I(list(RJ_MUNICIPIOS$codigo_ibge_6))
  row$macrorregioes_incompletas <- I(list(vigiar_rj_macrorregioes()))
  tibble::as_tibble(row)
}

.vigiar_grupos_cobertura <- function(dados, por) {
  all_codes <- RJ_MUNICIPIOS$codigo_ibge_6
  make_group <- function(idx, ano = NA_integer_, mes = NA_integer_,
                         macrorregiao_saude = NA_character_,
                         regiao_saude = NA_character_,
                         expected_codes = all_codes) {
    list(
      idx = idx,
      por = por,
      ano = as.integer(ano),
      mes = as.integer(mes),
      macrorregiao_saude = macrorregiao_saude,
      regiao_saude = regiao_saude,
      expected_codes = expected_codes
    )
  }

  if (nrow(dados) == 0) {
    return(list(make_group(integer(0))))
  }

  if (por == "geral") {
    return(list(make_group(seq_len(nrow(dados)))))
  }

  if (por %in% c("ano", "ano_mes") && !"ano" %in% names(dados)) {
    stop("Column 'ano' is required for this RJ coverage level.", call. = FALSE)
  }
  if (por %in% c("mes", "ano_mes") && !"mes" %in% names(dados)) {
    stop("Column 'mes' is required for this RJ coverage level.", call. = FALSE)
  }

  if (por == "ano") {
    keys <- sort(unique(as.integer(dados$ano)))
    return(lapply(keys, function(y) {
      make_group(which(as.integer(dados$ano) == y), ano = y)
    }))
  }

  if (por == "mes") {
    keys <- sort(unique(as.integer(dados$mes)))
    return(lapply(keys, function(m) {
      make_group(which(as.integer(dados$mes) == m), mes = m)
    }))
  }

  if (por == "macrorregiao") {
    keys <- sort(unique(RJ_MUNICIPIOS$macrorregiao_saude))
    return(lapply(keys, function(regiao) {
      expected <- RJ_MUNICIPIOS$codigo_ibge_6[RJ_MUNICIPIOS$macrorregiao_saude == regiao]
      make_group(
        which(dados$codigo_ibge_6__vigiar %in% expected),
        macrorregiao_saude = regiao,
        expected_codes = expected
      )
    }))
  }

  if (por == "regiao_saude") {
    keys <- sort(unique(RJ_MUNICIPIOS$regiao_saude))
    return(lapply(keys, function(regiao) {
      expected <- RJ_MUNICIPIOS$codigo_ibge_6[RJ_MUNICIPIOS$regiao_saude == regiao]
      make_group(
        which(dados$codigo_ibge_6__vigiar %in% expected),
        regiao_saude = regiao,
        expected_codes = expected
      )
    }))
  }

  combos <- unique(data.frame(
    ano = as.integer(dados$ano),
    mes = as.integer(dados$mes)
  ))
  combos <- combos[order(combos$ano, combos$mes), , drop = FALSE]
  lapply(seq_len(nrow(combos)), function(i) {
    y <- combos$ano[[i]]
    m <- combos$mes[[i]]
    make_group(
      which(as.integer(dados$ano) == y & as.integer(dados$mes) == m),
      ano = y,
      mes = m
    )
  })
}

.vigiar_cobertura_linha <- function(dados, por, ano, mes, macrorregiao_saude,
                                    regiao_saude, expected_codes,
                                    possivel_truncamento) {
  presentes <- unique(dados$codigo_ibge_6__vigiar)
  presentes <- sort(presentes[!is.na(presentes) & presentes %in% expected_codes])
  ausentes_cod <- sort(setdiff(expected_codes, presentes))
  ausentes <- RJ_MUNICIPIOS$municipio[match(ausentes_cod, RJ_MUNICIPIOS$codigo_ibge_6)]
  incomplete <- .vigiar_macrorregioes_incompletas(presentes, expected_codes)
  n_present <- length(presentes)
  n_expected <- length(expected_codes)

  list(
    por = por,
    ano = as.integer(ano),
    mes = as.integer(mes),
    macrorregiao_saude = macrorregiao_saude,
    regiao_saude = regiao_saude,
    n_municipios_presentes = as.integer(n_present),
    n_municipios_esperados = as.integer(n_expected),
    cobertura_pct = if (n_expected > 0) round(100 * n_present / n_expected, 1) else NA_real_,
    n_ausentes = as.integer(length(ausentes_cod)),
    municipios_ausentes = ausentes,
    codigos_ausentes = ausentes_cod,
    macrorregioes_incompletas = incomplete,
    completo = n_present == n_expected,
    possivel_truncamento = possivel_truncamento,
    stringsAsFactors = FALSE
  )
}

.vigiar_macrorregioes_incompletas <- function(presentes, expected_codes = RJ_MUNICIPIOS$codigo_ibge_6) {
  registry <- RJ_MUNICIPIOS[RJ_MUNICIPIOS$codigo_ibge_6 %in% expected_codes, ]
  expected <- table(registry$macrorregiao_saude)
  if (length(presentes) == 0) {
    return(names(expected))
  }

  observed_registry <- registry[registry$codigo_ibge_6 %in% presentes, ]
  observed <- table(observed_registry$macrorregiao_saude)
  incomplete <- names(expected)[vapply(names(expected), function(regiao) {
    obs <- if (regiao %in% names(observed)) observed[[regiao]] else 0L
    obs < expected[[regiao]]
  }, logical(1))]
  sort(incomplete)
}
