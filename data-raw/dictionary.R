# Build the VIGIAR variable dictionary from the conceptual schema
#
# This script fetches the live schema (or uses cached data) and
# generates:
#   inst/extdata/vigiar_variable_dictionary.csv
#   inst/extdata/vigiar_table_catalogue.csv
#
# Run manually after schema changes:
#   source("data-raw/dictionary.R")

library(vigiar.rj)

# ── Connect ───────────────────────────────────────────────────────────────────
message("Connecting to VIGIAR dashboard...")
vigiar_conectar()

# ── Build dictionary ──────────────────────────────────────────────────────────
tabelas <- vigiar_tabelas()
catalogo <- vigiar_info()

rows <- list()
for (tab in tabelas) {
  schema <- vigiar_esquema(tab)
  if (is.null(schema)) next

  cat_info <- catalogo[catalogo$tabela == tab, ]
  descricao_tabela <- if (nrow(cat_info) > 0) cat_info$descricao[1] else ""
  categoria <- if (nrow(cat_info) > 0) cat_info$categoria[1] else ""

  for (col_name in names(schema)) {
    col_info <- schema[[col_name]]

    # Infer standard name
    standard_name <- .vigiar_inferir_nome_padrao(col_name, tab)

    # Infer description
    description <- .vigiar_inferir_descricao(col_name, tab)

    # Infer unit
    unit <- .vigiar_inferir_unidade(col_name, tab)

    rows[[length(rows) + 1]] <- data.frame(
      table_id          = tab,
      table_name        = descricao_tabela,
      category          = categoria,
      original_name     = col_name,
      standard_name     = standard_name,
      type_raw          = col_info$tipo,
      type_processed    = .vigiar_tipo_processado(col_info$tipo, col_name),
      description       = description,
      unit              = unit,
      allowed_values    = "",
      missing_values    = "",
      example           = "",
      processing_rule   = "",
      validation_rule   = "",
      notes             = "",
      stringsAsFactors  = FALSE
    )
  }
}

dictionary <- do.call(rbind, rows)

# ── Write outputs ─────────────────────────────────────────────────────────────
dir.create("inst/extdata", showWarnings = FALSE, recursive = TRUE)
write.csv(dictionary, "inst/extdata/vigiar_variable_dictionary.csv",
          row.names = FALSE, fileEncoding = "UTF-8")
write.csv(catalogo, "inst/extdata/vigiar_table_catalogue.csv",
          row.names = FALSE, fileEncoding = "UTF-8")

message(sprintf("Dictionary written: %d variables across %d tables.",
                nrow(dictionary), length(unique(dictionary$table_id))))

# ── Helper functions ──────────────────────────────────────────────────────────

.vigiar_inferir_nome_padrao <- function(nome, tabela) {
  map <- c(
    muni = "cod_municipio", ID_MUNI = "cod_municipio",
    UF = "sigla_uf", UF_SIGLA = "sigla_uf", UF_NOME = "nome_uf",
    UF_COD = "cod_uf", UF_PARSED = "uf_formatado",
    ano = "ano", Ano = "ano", mes = "mes",
    pm25 = "pm25_media", Media_pm25 = "pm25_media_anual",
    t_dias = "pm25_media_periodo", n_dias = "n_dias_criticos",
    n_dias_conama = "n_dias_criticos_conama",
    LAT = "latitude", LON = "longitude",
    Indicador = "indicador", n = "populacao_exposta",
    est = "estimativa", low = "ic_inferior", high = "ic_superior",
    desfecho = "desfecho", pop = "populacao",
    q1 = "quartil_1", q2 = "quartil_2", q3 = "quartil_3",
    Code = "cod_uf", State.x = "sigla_uf",
    comb_sol_perc = "perc_combustiveis_solidos",
    comb_sol = "prop_combustiveis_solidos",
    pop_exposta = "populacao_exposta",
    percent_comb = "percentual_combustiveis",
    Quartis = "quartis"
  )
  if (nome %in% names(map)) return(map[[nome]])
  # Default: snake_case
  tolower(gsub("[^a-zA-Z0-9]+", "_", nome))
}

.vigiar_inferir_descricao <- function(nome, tabela) {
  desc_map <- c(
    muni       = "Código IBGE do município (6 ou 7 dígitos)",
    ID_MUNI    = "Código IBGE do município (6 ou 7 dígitos)",
    UF         = "Sigla da Unidade Federativa (2 letras)",
    UF_SIGLA   = "Sigla da Unidade Federativa (2 letras)",
    UF_NOME    = "Nome completo da Unidade Federativa",
    ano        = "Ano de referência",
    mes        = "Mês de referência (1–12)",
    pm25       = "Concentração média de PM2.5 (µg/m³)",
    Media_pm25 = "Média anual de concentração de PM2.5 (µg/m³)",
    n_dias     = "Número de dias acima do limite OMS (15 µg/m³)",
    n_dias_conama = "Número de dias acima do limite CONAMA (50 µg/m³)",
    LAT        = "Latitude (graus decimais)",
    LON        = "Longitude (graus decimais)",
    Indicador  = "Nome do indicador epidemiológico",
    n          = "População exposta",
    est        = "Estimativa pontual",
    low        = "Limite inferior do intervalo de confiança (95%)",
    high       = "Limite superior do intervalo de confiança (95%)",
    desfecho   = "Desfecho de saúde analisado",
    pop        = "População residente",
    categoria  = "Categoria de concentração de PM2.5",
    Code       = "Código da UF",
    Ano        = "Ano de referência (indoor)",
    pop_exposta = "População exposta a combustíveis sólidos",
    comb_sol_perc = "Percentual de domicílios usando combustíveis sólidos"
  )
  if (nome %in% names(desc_map)) return(desc_map[[nome]])
  ""
}

.vigiar_inferir_unidade <- function(nome, tabela) {
  unit_map <- c(
    pm25 = "µg/m³", Media_pm25 = "µg/m³",
    t_dias = "µg/m³", n_dias = "dias", n_dias_conama = "dias",
    LAT = "graus decimais", LON = "graus decimais",
    pop = "habitantes", pop_exposta = "habitantes",
    n = "habitantes", est = "varia conforme indicador",
    percent_comb = "%", comb_sol_perc = "%"
  )
  if (nome %in% names(unit_map)) return(unit_map[[nome]])
  ""
}

.vigiar_tipo_processado <- function(tipo_raw, nome) {
  # Refine type based on column semantics
  if (grepl("^(muni|ID_MUNI|UF_COD|Code|cod)$", nome)) return("integer")
  if (grepl("^(ano|Ano|mes)$", nome)) return("integer")
  if (grepl("^(LAT|LON|lat|long)$", nome)) return("numeric")
  if (nome %in% c("n_dias", "n_dias_conama")) return("integer")
  tipo_raw
}
