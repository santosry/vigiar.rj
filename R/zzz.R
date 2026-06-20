# Package: vigiar
# Core constants, internal environment, and utility functions

# Suppress R CMD check NOTE about ggplot2's .data pronoun

# vigiar: Download Data from the VIGIAR Environmental Health Surveillance Dashboard
# Copyright (C) 2026 Ryan Santos
# Licensed under MIT

# -- Dashboard constants -------------------------------------------------------

VIGIAR_BASE_URL <- paste0(
  "https://app.powerbi.com/view?r=",
  "eyJrIjoiNmRhODQwNzItNThlOS00ZmQ4LWJjZmItZDYxOTNhOTRmYmFhIiwidCI6",
  "IjlhNTU0YWQzLWI1MmItNDg2Mi1hMzZmLTg0ZDg5MWU1YzcwNSJ9"
)
VIGIAR_RESOURCE_KEY <- "6da84072-58e9-4fd8-bcfb-d6193a94fbaa"
VIGIAR_TENANT_ID   <- "9a554ad3-b52b-4862-a36f-84d891e5c705"
VIGIAR_MODEL_ID    <- 3930757L
VIGIAR_CLUSTER     <- paste0(
  "https://wabi-brazil-south-b-primary-redirect.analysis.windows.net/"
)
VIGIAR_API_CLUSTER <- paste0(
  "https://wabi-brazil-south-b-primary-api.analysis.windows.net/"
)

# -- Internal package environment ----------------------------------------------

.vigiar_env <- new.env(parent = emptyenv())

# -- NULL-coalesce operator ----------------------------------------------------

`%||%` <- function(x, y) if (is.null(x)) y else x

# -- UUID v4 generator (no external dependency) --------------------------------

uuid_v4 <- function() {
  hex <- c(0:9, "a", "b", "c", "d", "e", "f")
  parts <- c(
    paste0(sample(hex, 8,  replace = TRUE), collapse = ""),
    paste0(sample(hex, 4,  replace = TRUE), collapse = ""),
    paste0("4", sample(hex[1:4], 3, replace = TRUE), collapse = ""),
    paste0(sample(c("8", "9", "a", "b"), 1),
           paste0(sample(hex, 3, replace = TRUE), collapse = ""),
           collapse = ""),
    paste0(sample(hex, 12, replace = TRUE), collapse = "")
  )
  paste(parts, collapse = "-")
}

# -- Gzip decompression (base R only, streaming for large payloads) ------------

.vigiar_gunzip <- function(raw_body) {
  if (length(raw_body) < 2) return(raw_body)
  if (raw_body[1] != 0x1f || raw_body[2] != 0x8b) return(raw_body)

  tmp <- tempfile(fileext = ".gz")
  on.exit(unlink(tmp), add = TRUE)
  writeBin(raw_body, tmp)

  con <- gzfile(tmp, "rb")
  on.exit(close(con), add = TRUE)

  chunks <- list()
  repeat {
    chunk <- readBin(con, raw(), 65536L)
    if (length(chunk) == 0) break
    chunks[[length(chunks) + 1L]] <- chunk
  }
  do.call(c, chunks)
}

# -- Power BI data type mapping ------------------------------------------------

.vigiar_tipo_dado <- function(code) {
  switch(as.character(code),
    `1` = "character",  # Text
    `2` = "numeric",    # Decimal / Currency
    `3` = "numeric",    # Double
    `4` = "integer",    # Integer
    `5` = "logical",    # Boolean
    `6` = "Date",       # Date
    `7` = "POSIXct",    # DateTime
    `8` = "numeric",    # Int64 (stored as numeric in R)
    "character"         # fallback
  )
}

# -- Cookie extraction from set-cookie header ----------------------------------

.vigiar_extrair_cookies <- function(set_cookie) {
  if (is.null(set_cookie) || length(set_cookie) == 0) {
    return(character(0))
  }

  # httr2 may return multiple headers concatenated
  if (length(set_cookie) > 1) {
    set_cookie <- paste(set_cookie, collapse = "\n")
  }

  parts <- strsplit(set_cookie, "\n")[[1]]

  cookies <- character(0)
  for (part in parts) {
    part <- trimws(part)
    m <- regmatches(part, regexpr("^[^=;]+=[^;]+", part))
    if (length(m) > 0 && nzchar(m)) {
      cookies <- c(cookies, m)
    }
  }
  unique(cookies)
}

# -- Retry logic with exponential backoff --------------------------------------

.vigiar_retry <- function(expr, max_tries = 3L, initial_delay = 1,
                           max_delay = 30, backoff = 2, context = "") {
  delay <- initial_delay
  last_error <- NULL

  for (attempt in seq_len(max_tries)) {
    result <- tryCatch(
      expr,
      httr2_http_403 = function(e) {
        # Session expired -- do not retry
        stop(e)
      },
      httr2_http_429 = function(e) {
        # Rate limited -- retry with longer delay
        last_error <<- e
        NULL
      },
      httr2_http_5xx = function(e) {
        last_error <<- e
        NULL
      },
      httr2_failure = function(e) {
        last_error <<- e
        NULL
      },
      error = function(e) {
        last_error <<- e
        NULL
      }
    )

    if (!is.null(result)) return(result)

    if (attempt < max_tries) {
      if (nzchar(context)) {
        message(sprintf(
          "[%s] Tentativa %d/%d falhou. Retentando em %.0fs...",
          context, attempt, max_tries, delay
        ))
      }
      Sys.sleep(delay)
      delay <- min(delay * backoff, max_delay)
    }
  }

  stop(sprintf(
    "[%s] Todas as %d tentativas falharam. Ultimo erro: %s",
    context, max_tries,
    conditionMessage(last_error) %||% "desconhecido"
  ))
}
