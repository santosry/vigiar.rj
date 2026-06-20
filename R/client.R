# Package: vigiar.rj
# Power BI client abstraction
#
# Encapsulates session management and API communication
# behind a clean S3 interface.  Replaces the global .vigiar_env
# pattern with explicit session objects.

#' Create a VIGIAR Power BI client
#'
#' Returns an S3 object that holds session state and provides
#' methods for data download.  All state is self-contained;
#' no global variables are used.
#'
#' @param timeout Seconds before HTTP timeout.
#' @param max_retries Maximum retry attempts on transient failures.
#' @return An object of class \code{vigiar_client}.
#' @export
vigiar_client <- function(timeout = 30, max_retries = 3) {
  # Step 1: fetch dashboard page for cookies + session token
  resp <- .vigiar_retry({
    httr2::request(VIGIAR_BASE_URL) |>
      httr2::req_user_agent(.vigiar_ua()) |>
      httr2::req_timeout(timeout) |>
      httr2::req_perform()
  }, max_tries = max_retries, context = "client")

  html <- httr2::resp_body_string(resp)
  sid <- regmatches(html, regexpr("(?<=telemetrySessionId = ')[^']+",
                                   html, perl = TRUE))
  if (length(sid) == 0) {
    stop("Nao foi possivel obter o token de sessao do Power BI.")
  }

  # Extract cookies
  hdrs <- httr2::resp_headers(resp)
  raw <- hdrs[["set-cookie"]]
  if (is.null(raw)) {
    idx <- which(tolower(names(hdrs)) == "set-cookie")
    if (length(idx) > 0) raw <- hdrs[[idx[1]]]
  }
  cookies <- paste(.vigiar_extrair_cookies(raw), collapse = "; ")

  # Step 2: fetch conceptual schema
  schema <- .vigiar_fetch_schema(sid, cookies, timeout)

  client <- list(
    session_id = sid,
    cookies    = cookies,
    schema     = schema,
    api_url    = VIGIAR_API_CLUSTER,
    rk         = VIGIAR_RESOURCE_KEY,
    model_id   = VIGIAR_MODEL_ID,
    created    = Sys.time()
  )
  class(client) <- "vigiar_client"

  n_tables <- length(schema)
  message(sprintf("VIGIAR conectado: %d tabelas disponiveis.", n_tables))
  client
}

#' @export
print.vigiar_client <- function(x, ...) {
  cat(sprintf("VIGIAR client — %d tabelas\n", length(x$schema)))
  cat(sprintf("  Criado em: %s\n", format(x$created)))
  cat(sprintf("  Tabelas:   %s\n",
              paste(names(x$schema)[1:5], collapse = ", ")))
  invisible(x)
}

# ---- Internal: fetch schema --------------------------------------------------

.vigiar_fetch_schema <- function(sid, cookies, timeout) {
  url <- sprintf("%spublic/reports/%s/conceptualschema",
                 VIGIAR_API_CLUSTER, VIGIAR_RESOURCE_KEY)

  resp <- .vigiar_retry({
    httr2::request(url) |>
      httr2::req_headers(
        "X-PowerBI-ResourceKey" = VIGIAR_RESOURCE_KEY,
        ActivityId              = sid,
        RequestId               = uuid_v4(),
        Accept                  = "application/json",
        Referer                 = "https://app.powerbi.com/",
        Cookie                  = cookies
      ) |>
      httr2::req_user_agent(.vigiar_ua()) |>
      httr2::req_timeout(timeout) |>
      httr2::req_perform()
  }, max_tries = 2, context = "schema")

  raw <- httr2::resp_body_raw(resp)
  raw <- .vigiar_gunzip(raw)
  data <- jsonlite::fromJSON(rawToChar(raw), simplifyVector = FALSE)

  entities <- data$schemas[[1]]$schema$Entities
  tabelas <- list()
  for (ent in entities) {
    props <- ent$Properties
    cols <- lapply(props, function(p) {
      list(nome = p$Name, tipo = .vigiar_tipo_dado(p$DataType))
    })
    names(cols) <- vapply(props, `[[`, "", "Name", USE.NAMES = FALSE)
    tabelas[[ent$Name]] <- cols
  }
  tabelas
}

# Keep backward compatibility: global session
.vigiar_client_default <- function() {
  if (is.null(.vigiar_env$client)) {
    .vigiar_env$client <- vigiar_client()
  }
  .vigiar_env$client
}
