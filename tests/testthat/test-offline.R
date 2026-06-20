# vigiar: offline unit tests
# These tests do NOT require internet access.

library(testthat)
library(vigiar)

# ── Utility functions ─────────────────────────────────────────────────────────

test_that("uuid_v4 generates valid v4 UUID format", {
  u <- uuid_v4()
  expect_match(u, paste0(
    "^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-",
    "[89ab][0-9a-f]{3}-[0-9a-f]{12}$"
  ))
})

test_that("uuid_v4 generates unique values", {
  uu <- replicate(20, uuid_v4())
  expect_equal(length(unique(uu)), 20)
})

test_that("%||% works correctly", {
  expect_equal(1 %||% 2, 1)
  expect_equal(NULL %||% 2, 2)
  expect_equal(NA %||% 3, NA)
  expect_equal(FALSE %||% TRUE, FALSE)
})

# ── Type mapping ──────────────────────────────────────────────────────────────

test_that(".vigiar_tipo_dado maps Power BI types to R types", {
  expect_equal(.vigiar_tipo_dado(1), "character")
  expect_equal(.vigiar_tipo_dado(2), "numeric")
  expect_equal(.vigiar_tipo_dado(3), "numeric")
  expect_equal(.vigiar_tipo_dado(4), "integer")
  expect_equal(.vigiar_tipo_dado(5), "logical")
  expect_equal(.vigiar_tipo_dado(6), "Date")
  expect_equal(.vigiar_tipo_dado(7), "POSIXct")
  expect_equal(.vigiar_tipo_dado(8), "numeric")  # Int64 → numeric
  expect_equal(.vigiar_tipo_dado(999), "character")  # fallback
})

# ── Cookie extraction ─────────────────────────────────────────────────────────

test_that(".vigiar_extrair_cookies handles NULL/empty", {
  expect_equal(.vigiar_extrair_cookies(NULL), character(0))
  expect_equal(.vigiar_extrair_cookies(character(0)), character(0))
})

test_that(".vigiar_extrair_cookies extracts cookie name=value pairs", {
  header <- c(
    "WFESessionId=abc-123; path=/; secure; SameSite=None",
    "ARRAffinity=xyz-789;Path=/;HttpOnly;Secure"
  )
  result <- .vigiar_extrair_cookies(header)
  expect_true(any(grepl("WFESessionId=abc-123", result)))
  expect_true(any(grepl("ARRAffinity=xyz-789", result)))
})

# ── Gzip decompression ────────────────────────────────────────────────────────

test_that(".vigiar_gunzip decompresses gzip data", {
  # Create a small gzip payload
  tmp <- tempfile(fileext = ".gz")
  con <- gzfile(tmp, "wb")
  writeLines("hello vigiar", con)
  close(con)
  compressed <- readBin(tmp, raw(), file.info(tmp)$size)
  unlink(tmp)

  result <- .vigiar_gunzip(compressed)
  expect_equal(rawToChar(result), "hello vigiar\n")
})

test_that(".vigiar_gunzip returns raw data unchanged if not gzip", {
  raw <- charToRaw("plain text")
  expect_equal(.vigiar_gunzip(raw), raw)
})

test_that(".vigiar_gunzip handles empty input", {
  expect_equal(.vigiar_gunzip(raw(0)), raw(0))
})

# ── Query construction ────────────────────────────────────────────────────────

test_that(".vigiar_construir_query builds correct structure", {
  old_esquema <- .vigiar_env$esquema
  .vigiar_env$esquema <- list(
    teste = list(
      col1 = list(nome = "col1", tipo = "integer"),
      col2 = list(nome = "col2", tipo = "character")
    )
  )
  on.exit({ .vigiar_env$esquema <- old_esquema })

  q <- .vigiar_construir_query("teste", modelo_id = 123)

  expect_equal(q$modelId, 123)
  expect_equal(length(q$queries[[1]]$Query$Commands), 1)

  cmd <- q$queries[[1]]$Query$Commands[[1]]$SemanticQueryDataShapeCommand
  expect_equal(cmd$Query$From[[1]]$Entity, "teste")
  expect_equal(length(cmd$Query$Select), 2)

  # Check Top is an integer when provided
  q2 <- .vigiar_construir_query("teste", limite = 10, modelo_id = 123)
  cmd2 <- q2$queries[[1]]$Query$Commands[[1]]$SemanticQueryDataShapeCommand
  expect_equal(cmd2$Query$Top, 10L)
})

test_that(".vigiar_construir_query handles order_by", {
  old_esquema <- .vigiar_env$esquema
  .vigiar_env$esquema <- list(
    teste = list(
      x = list(nome = "x", tipo = "integer")
    )
  )
  on.exit({ .vigiar_env$esquema <- old_esquema })

  q <- .vigiar_construir_query("teste", colunas = "x",
                                 ordenar_por = "x", modelo_id = 1)
  cmd <- q$queries[[1]]$Query$Commands[[1]]$SemanticQueryDataShapeCommand
  expect_equal(cmd$Query$OrderBy[[1]]$Expression$Column$Property, "x")
})

# ── DSR Parser ────────────────────────────────────────────────────────────────

.make_dsr_response <- function(schema, dm0_entries, value_dicts = list()) {
  # Helper to build a mock DSR response
  list(
    results = list(list(
      result = list(
        data = list(
          descriptor = list(
            Select = lapply(seq_along(schema), function(i) {
              list(
                Name  = schema[[i]]$Name %||% paste0("col", i),
                Kind  = 1L, Depth = 0L,
                Value = paste0("G", i - 1L)
              )
            })
          ),
          dsr = list(
            DS = list(list(
              N          = "DS0",
              ValueDicts = value_dicts,
              PH         = list(list(DM0 = dm0_entries))
            ))
          )
        )
      )
    ))
  )
}

test_that(".vigiar_parse_dados handles simple flat table", {
  schema <- list(
    list(N = "G0", T = 4L),          # integer
    list(N = "G1", T = 1L),          # text
    list(N = "G2", T = 3L)           # double
  )
  dm0 <- list(
    list(S = schema, C = list(2020L, "SP", 25.5)),
    list(R = 3L, C = list(30.1)),              # keep 2, 1 new
    list(R = 2L, C = list("RJ", 18.2))          # keep 1, 2 new
  )
  names(schema) <- c("ano", "uf", "pm25")
  for (i in seq_along(schema)) schema[[i]]$Name <- names(schema)[i]

  resp <- .make_dsr_response(schema, dm0)
  df <- .vigiar_parse_dados(resp, "teste")

  expect_equal(nrow(df), 3)
  expect_equal(ncol(df), 3)
  expect_equal(df$ano,  c(2020, 2020, 2020))
  expect_equal(df$uf,   c("SP", "SP", "RJ"))
  expect_equal(df$pm25, c(25.5, 30.1, 18.2))
})

test_that(".vigiar_parse_dados resolves ValueDicts", {
  schema <- list(
    list(N = "G0", T = 4L),
    list(N = "G1", T = 1L, DN = "D0")
  )
  names(schema) <- c("id", "estado")
  for (i in seq_along(schema)) schema[[i]]$Name <- names(schema)[i]

  dm0 <- list(
    list(S = schema, C = list(1L, 1L)),
    list(R = 2L, C = list(2L)),
    list(R = 2L, C = list(3L))
  )
  vd <- list(D0 = c("São Paulo", "Rio de Janeiro", "Minas Gerais"))

  resp <- .make_dsr_response(schema, dm0, value_dicts = vd)
  df <- .vigiar_parse_dados(resp, "teste")

  expect_equal(df$estado, c("São Paulo", "Rio de Janeiro", "Minas Gerais"))
})

test_that(".vigiar_parse_dados handles empty response gracefully", {
  resp <- list(results = list(list(result = list(data = list()))))
  df <- .vigiar_parse_dados(resp, "vazia")
  expect_equal(nrow(df), 0)
})

test_that(".vigiar_parse_dados warns on DM0 with R but no previous row", {
  schema <- list(list(N = "G0", T = 4L))
  names(schema) <- "x"
  schema[[1]]$Name <- "x"

  dm0 <- list(
    list(R = 2L, C = list(1L))  # R but no S entry before — abnormal
  )

  resp <- .make_dsr_response(schema, dm0)
  expect_warning(
    df <- .vigiar_parse_dados(resp, "teste"),
    "sem linha anterior"
  )
  expect_equal(nrow(df), 1)
})

test_that(".vigiar_parse_dados pads short rows", {
  schema <- list(
    list(N = "G0", T = 4L),
    list(N = "G1", T = 4L),
    list(N = "G2", T = 4L)
  )
  names(schema) <- c("a", "b", "c")
  for (i in seq_along(schema)) schema[[i]]$Name <- names(schema)[i]

  dm0 <- list(
    list(S = schema, C = list(1L, 2L, 3L)),
    list(R = 2L, C = list(5L))  # R=2 → keep 1, C has 1 → 2 values total, needs pad
  )

  resp <- .make_dsr_response(schema, dm0)
  df <- .vigiar_parse_dados(resp, "teste")
  expect_equal(nrow(df), 2)
  expect_equal(ncol(df), 3)
  expect_equal(df$a, c(1L, 1L))
  expect_equal(df$b, c(2L, 5L))
  expect_true(is.na(df$c[2]))
})

# ── Processing functions ──────────────────────────────────────────────────────

test_that("process_pm25 renames columns correctly", {
  raw <- data.frame(
    muni = 355030L, UF = "SP", ano = 2022L,
    Media_pm25 = 22.5, Categoria_pm25 = "> 35 µg/m³",
    stringsAsFactors = FALSE
  )
  result <- process_pm25(raw, tipo = "anual")
  expect_s3_class(result, "vigiar_pm25")
  expect_true("cod_municipio" %in% names(result))
  expect_true("sigla_uf" %in% names(result))
  expect_true("pm25_media_anual" %in% names(result))
  expect_true("categoria_oms" %in% names(result))
  expect_equal(result$pm25_media_anual, 22.5)
})

test_that("process_populacao_exposta renames columns", {
  raw <- data.frame(
    muni = 355030L, ano = 2022L, pop = 12345678,
    categoria = "> 35 µg/m³", UF = "SP",
    stringsAsFactors = FALSE
  )
  result <- process_populacao_exposta(raw)
  expect_s3_class(result, "vigiar_population")
  expect_true("cod_municipio" %in% names(result))
  expect_true("populacao" %in% names(result))
  expect_true("categoria_exposicao" %in% names(result))
})

test_that("process_indicadores_saude renames columns", {
  raw <- data.frame(
    Indicador = "Fração atribuível (%)", n = 5e7, est = 4.5,
    low = 2.5, high = 6.8, desfecho = "Mortalidade geral",
    ano = 2022L, stringsAsFactors = FALSE
  )
  result <- process_indicadores_saude(raw, agregacao = "brasil")
  expect_s3_class(result, "vigiar_health")
  expect_true("indicador" %in% names(result))
  expect_true("estimativa" %in% names(result))
  expect_true("ic_inferior" %in% names(result))
  expect_true("ic_superior" %in% names(result))
})

test_that("process_fracao_atribuivel renames columns", {
  raw <- data.frame(
    Indicador = "Fração atribuível (%)", n = 1e6, est = 12.3,
    low = 8.1, high = 16.5, desfecho = "Câncer de Pulmão",
    ano = 2022L, stringsAsFactors = FALSE
  )
  result <- process_fracao_atribuivel(raw)
  expect_s3_class(result, "vigiar_attributable_fraction")
  expect_true("fracao_atribuivel" %in% names(result))
})

test_that("process_exposicao_indoor renames columns", {
  raw <- data.frame(
    Code = 35L, Ano = 2022L, comb_sol = 0.194,
    pop_exposta = 186256, percent_comb = 19.4,
    Quartis = "Q2", stringsAsFactors = FALSE
  )
  result <- process_exposicao_indoor(raw, tipo = "exposicao")
  expect_s3_class(result, "vigiar_indoor")
  expect_true("cod_uf" %in% names(result))
  expect_true("prop_combustiveis_solidos" %in% names(result))
  expect_true("populacao_exposta" %in% names(result))
})

test_that("process_municipios renames columns", {
  raw <- data.frame(
    UF_COD = 35L, UF_SIGLA = "SP", UF_NOME = "São Paulo",
    REGIAO = "Sudeste", LAT = -23.5, LON = -46.6,
    stringsAsFactors = FALSE
  )
  result <- process_municipios(raw)
  expect_s3_class(result, "vigiar_municipios")
  expect_true("cod_uf" %in% names(result))
  expect_true("sigla_uf" %in% names(result))
  expect_true("latitude" %in% names(result))
})

# ── Validation functions ──────────────────────────────────────────────────────

test_that("vigiar_validar_ibge warns on invalid codes", {
  dados <- data.frame(
    cod_municipio = c(355030L, 999999L, 110001L),
    stringsAsFactors = FALSE
  )
  expect_warning(
    vigiar_validar_ibge(dados, "cod_municipio"),
    "fora do intervalo"
  )
})

test_that("vigiar_validar_ibge passes on valid codes", {
  dados <- data.frame(cod_municipio = c(355030L, 110001L, 530010L))
  expect_silent(vigiar_validar_ibge(dados, "cod_municipio"))
})

test_that("vigiar_validar_datas warns on invalid years", {
  dados <- data.frame(ano = c(2022L, 1800L, 3000L))
  expect_warning(vigiar_validar_datas(dados), "fora do intervalo")
})

test_that("vigiar_validar_unidades warns on implausible PM2.5", {
  dados <- data.frame(pm25_media = c(22.5, -5, 2000))
  expect_warning(
    vigiar_validar_unidades(dados, "pm25_media"),
    "fora do intervalo"
  )
})

# ── Dictionary ────────────────────────────────────────────────────────────────

test_that("vigiar_dicionario returns tibble", {
  dict <- vigiar_dicionario()
  expect_s3_class(dict, "tbl_df")
  expect_true(nrow(dict) > 0)
  expect_true(all(c("table_id", "original_name", "standard_name") %in% names(dict)))
})

test_that("vigiar_variaveis filters by domain", {
  pm25_vars <- vigiar_variaveis("pm25")
  expect_true(all(pm25_vars$table_id %in%
    c("df_anual", "df_mensal", "df_dias", "df_dias_conama")))
})

test_that("vigiar_descrever_variavel errors on missing variable", {
  expect_error(
    vigiar_descrever_variavel("pm25", "variavel_inexistente"),
    "não encontrada"
  )
})

# ── S3 class methods ──────────────────────────────────────────────────────────

test_that("new_vigiar_tbl creates typed tibble", {
  df <- data.frame(x = 1:3, y = letters[1:3])
  out <- new_vigiar_tbl(df, subclass = "vigiar_pm25", tabela = "test")
  expect_s3_class(out, "vigiar_pm25")
  expect_s3_class(out, "vigiar_tbl")
  expect_equal(attr(out, "vigiar_tabela"), "test")
})

test_that("print.vigiar_tbl works", {
  df <- data.frame(x = 1:3)
  out <- new_vigiar_tbl(df, tabela = "test")
  expect_output(print(out), "VIGIAR tibble")
})

test_that("summary.vigiar_tbl works", {
  df <- data.frame(x = c(1, NA, 3))
  out <- new_vigiar_tbl(df, tabela = "test")
  expect_output(summary(out), "Resumo")
})

test_that("validate.vigiar_tbl detects issues", {
  df <- data.frame(x = numeric(0))
  out <- new_vigiar_tbl(df, tabela = "")
  attr(out, "vigiar_tabela") <- NULL
  expect_warning(validate(out), "vigiar_tabela")
})
