# Package: vigiar
# Session management and dashboard connection
#
# Handles Power BI anonymous "Publish to Web" session lifecycle:
#   1. Fetch dashboard page → extract cookies + telemetrySessionId
#   2. Fetch conceptual schema → discover tables and columns
#   3. Maintain session in package environment

#' Connect to the VIGIAR Power BI dashboard
#'
#' Establishes an anonymous session with the public VIGIAR Power BI
#' dashboard, obtaining the cookies and session token required for
#' subsequent data queries. Also fetches the conceptual schema
#' (table and column metadata).
#'
#' @param refresh If `TRUE`, forces a new session even if one exists.
#' @param timeout Maximum time in seconds to establish the connection.
#' @param max_retries Maximum number of retry attempts on transient failures.
#' @return Invisibly, a list with session data.
#' @export
vigiar_conectar <- function(refresh = FALSE, timeout = 30, max_retries = 3) {
  if (!refresh && !is.null(.vigiar_env$sessao)) {
    message("Sessão VIGIAR já está ativa. Use refresh = TRUE para renovar.")
    return(invisible(.vigiar_env$sessao))
  }

  # Step 1 — Fetch dashboard page
  resp <- .vigiar_retry(
    {
      httr2::request(VIGIAR_BASE_URL) |>
        httr2::req_user_agent(.vigiar_ua()) |>
        httr2::req_timeout(timeout) |>
        httr2::req_perform()
    },
    max_tries = max_retries,
    context = "conectar"
  )

  html_content <- httr2::resp_body_string(resp)

  # Extract telemetrySessionId from JavaScript
  session_id <- regmatches(
    html_content,
    regexpr("(?<=telemetrySessionId = ')[^']+", html_content, perl = TRUE)
  )
  if (length(session_id) == 0) {
    stop(
      "Não foi possível extrair o telemetrySessionId do dashboard Power BI. ",
      "O dashboard pode estar temporariamente indisponível."
    )
  }

  # Extract cookies from response headers
  all_headers <- httr2::resp_headers(resp)
  set_cookie_raw <- all_headers[["set-cookie"]]

  if (is.null(set_cookie_raw)) {
    names_lower <- tolower(names(all_headers))
    idx <- which(names_lower == "set-cookie")
    if (length(idx) > 0) set_cookie_raw <- all_headers[[idx[1]]]
  }

  cookie_parts <- .vigiar_extrair_cookies(set_cookie_raw)

  if (length(cookie_parts) == 0) {
    warning(
      "Não foi possível extrair cookies da resposta. ",
      "As consultas de dados podem falhar."
    )
    cookie_string <- ""
  } else {
    cookie_string <- paste(cookie_parts, collapse = "; ")
  }

  # Build session object
  sessao <- list(
    session_id   = session_id,
    cookies      = cookie_string,
    resource_key = VIGIAR_RESOURCE_KEY,
    model_id     = VIGIAR_MODEL_ID,
    api_url      = VIGIAR_API_CLUSTER,
    created_at   = Sys.time()
  )
  class(sessao) <- "vigiar_sessao"

  .vigiar_env$sessao <- sessao

  # Step 2 — Fetch conceptual schema
  message("Sessão VIGIAR estabelecida. Carregando esquema de dados...")
  .vigiar_env$esquema <- .vigiar_obter_esquema(sessao, timeout = timeout)

  n_tables <- length(.vigiar_env$esquema)
  message(sprintf("Sessão pronta! %d tabelas disponíveis.", n_tables))

  invisible(sessao)
}

#' Disconnect and clear VIGIAR session
#'
#' @return Invisibly, `NULL`.
#' @export
vigiar_desconectar <- function() {
  .vigiar_env$sessao  <- NULL
  .vigiar_env$esquema <- NULL
  message("Sessão VIGIAR encerrada.")
  invisible(NULL)
}

#' Check if a VIGIAR session is active
#'
#' @return `TRUE` if a session exists, `FALSE` otherwise.
#' @export
vigiar_sessao_ativa <- function() {
  !is.null(.vigiar_env$sessao)
}

# ── Internal helpers ──────────────────────────────────────────────────────────

.vigiar_ua <- function() {
  paste0(
    "Mozilla/5.0 (Windows NT 10.0; Win64; x64) ",
    "AppleWebKit/537.36 (KHTML, like Gecko) ",
    "Chrome/131.0.0.0 Safari/537.36"
  )
}

#' Fetch conceptual schema from Power BI
#' @param sessao Session list
#' @param timeout Timeout in seconds
#' @return Named list of tables, each with named column metadata
#' @keywords internal
.vigiar_obter_esquema <- function(sessao, timeout = 30) {
  req_id <- uuid_v4()
  url <- sprintf(
    "%spublic/reports/%s/conceptualschema",
    sessao$api_url, sessao$resource_key
  )

  resp <- .vigiar_retry(
    {
      httr2::request(url) |>
        httr2::req_headers(
          "X-PowerBI-ResourceKey" = sessao$resource_key,
          ActivityId              = sessao$session_id,
          RequestId               = req_id,
          Accept                  = "application/json",
          Referer                 = "https://app.powerbi.com/",
          Cookie                  = sessao$cookies
        ) |>
        httr2::req_user_agent(.vigiar_ua()) |>
        httr2::req_timeout(timeout) |>
        httr2::req_perform()
    },
    max_tries = 2,
    context   = "esquema"
  )

  raw_body <- httr2::resp_body_raw(resp)
  raw_body <- .vigiar_gunzip(raw_body)

  schema_data <- jsonlite::fromJSON(
    rawToChar(raw_body),
    simplifyVector = FALSE
  )

  entities <- schema_data$schemas[[1L]]$schema$Entities

  tabelas <- list()
  for (ent in entities) {
    nome <- ent$Name
    props <- ent$Properties
    colunas <- lapply(props, function(p) {
      list(nome = p$Name, tipo = .vigiar_tipo_dado(p$DataType))
    })
    names(colunas) <- vapply(props, `[[`, "", "Name", USE.NAMES = FALSE)
    tabelas[[nome]] <- colunas
  }

  tabelas
}

#' Check VIGIAR dashboard status
#'
#' Verifies that the Power BI dashboard is reachable and the
#' conceptual schema is unchanged from the cached version.
#'
#' @return Invisibly, a list with status information.
#' @export
vigiar_status <- function() {
  if (is.null(.vigiar_env$sessao)) {
    message("Nenhuma sessão ativa.")
    return(invisible(list(online = FALSE, tables_ok = FALSE)))
  }

  online <- FALSE
  tryCatch({
    esquema <- .vigiar_obter_esquema(.vigiar_env$sessao, timeout = 10)
    online <- TRUE
    cached_tables <- names(.vigiar_env$esquema)
    live_tables   <- names(esquema)
    new_tables    <- setdiff(live_tables, cached_tables)
    missing_tables <- setdiff(cached_tables, live_tables)

    tables_ok <- length(new_tables) == 0 && length(missing_tables) == 0
  }, error = function(e) {
    online <<- FALSE
    new_tables <<- character(0)
    missing_tables <<- character(0)
    tables_ok <<- FALSE
  })

  status <- list(
    online        = online,
    tables_ok     = tables_ok,
    new_tables    = if (exists("new_tables")) new_tables else character(0),
    missing_tables = if (exists("missing_tables")) missing_tables else character(0)
  )

  if (online && tables_ok) {
    message("Dashboard VIGIAR online. Esquema de dados consistente.")
  } else if (online) {
    warning(
      "Dashboard VIGIAR online, mas o esquema de dados mudou! ",
      "Execute vigiar_conectar(refresh = TRUE) para atualizar."
    )
  } else {
    warning("Dashboard VIGIAR indisponível ou inacessível.")
  }

  invisible(status)
}
