# Package: vigiar
# Power BI queryData API interaction
#
# Constructs SemanticQueryDataShapeCommand JSON and posts to the
# /public/reports/querydata endpoint.

#' Build a Power BI Semantic Query for a table
#'
#' @param tabela Table/entity name in the data model.
#' @param colunas Character vector of column names (NULL = all).
#' @param ordenar_por Column to order by (optional).
#' @param limite Maximum number of rows (optional).
#' @param modelo_id Model ID in Power BI.
#' @return A nested list ready for JSON serialisation.
#' @keywords internal
.vigiar_construir_query <- function(tabela, colunas = NULL, ordenar_por = NULL,
                                     limite = NULL, modelo_id) {
  if (is.null(colunas)) {
    colunas <- names(.vigiar_env$esquema[[tabela]])
  }

  selects <- vector("list", length(colunas))
  for (i in seq_along(colunas)) {
    selects[[i]] <- list(
      Column = list(
        Expression = list(SourceRef = list(Source = tabela)),
        Property   = colunas[[i]]
      ),
      Name = colunas[[i]]
    )
  }

  n <- length(colunas)
  query_cmd <- list(
    SemanticQueryDataShapeCommand = list(
      Query = list(
        Version = 2L,
        From    = list(list(Name = tabela, Entity = tabela)),
        Select  = selects
      ),
      Binding = list(
        Primary = list(
          Groupings = list(list(Projections = seq.int(0L, n - 1L)))
        ),
        Version = 1L
      )
    )
  )

  if (!is.null(ordenar_por)) {
    query_cmd$SemanticQueryDataShapeCommand$Query$OrderBy <- list(list(
      Direction  = 1L,
      Expression = list(
        Column = list(
          Expression = list(SourceRef = list(Source = tabela)),
          Property   = ordenar_por
        )
      )
    ))
  }

  if (!is.null(limite)) {
    query_cmd$SemanticQueryDataShapeCommand$Query$Top <- as.integer(limite)
  }

  list(
    version       = 1L,
    cancelQueries = list(),
    queries       = list(list(
      Query              = list(Commands = list(query_cmd)),
      CacheKey           = "",
      QueryId            = "",
      ApplicationContext = list(
        Sources   = list(),
        DatasetId = as.character(modelo_id)
      )
    )),
    modelId = modelo_id
  )
}

#' Execute a query against the Power BI queryData endpoint
#'
#' @param sessao Active VIGIAR session.
#' @param query_body Query body as an R list.
#' @param timeout Timeout in seconds.
#' @return Parsed API response as an R list.
#' @keywords internal
.vigiar_executar_query <- function(sessao, query_body, timeout = 120) {
  req_id    <- uuid_v4()
  body_json <- jsonlite::toJSON(
    query_body, auto_unbox = TRUE, null = "null", digits = NA
  )

  url <- sprintf(
    "%spublic/reports/querydata?synchronous=true",
    sessao$api_url
  )

  resp <- .vigiar_retry(
    {
      httr2::request(url) |>
        httr2::req_headers(
          "X-PowerBI-ResourceKey" = sessao$resource_key,
          ActivityId              = sessao$session_id,
          RequestId               = req_id,
          Accept                  = "application/json",
          "Content-Type"          = "application/json",
          Referer                 = "https://app.powerbi.com/",
          Cookie                  = sessao$cookies
        ) |>
        httr2::req_user_agent(.vigiar_ua()) |>
        httr2::req_body_raw(body_json) |>
        httr2::req_method("POST") |>
        httr2::req_timeout(timeout) |>
        httr2::req_perform()
    },
    max_tries = 3,
    context   = "queryData"
  )

  raw_body <- httr2::resp_body_raw(resp)
  raw_body <- .vigiar_gunzip(raw_body)

  result <- jsonlite::fromJSON(rawToChar(raw_body), simplifyVector = FALSE)

  # Check for API-level errors
  if (!is.null(result$error)) {
    stop(
      "Erro na API Power BI: ",
      result$error$message %||% "erro desconhecido"
    )
  }

  result
}
