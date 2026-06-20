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
