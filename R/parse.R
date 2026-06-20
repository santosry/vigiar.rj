# Package: vigiar
# DSR (Data Shape Response) parser
#
# Decodes the Power BI compressed data format:
#   - DM0: array of data blocks.  First block carries the schema (S)
#          and the first row (C).  Subsequent blocks carry reference
#          count (R, 1-based) + new column values (C).
#   - ValueDicts: string dictionaries (index -> text) for Text columns.
#   - Gzip: response body may be gzipped (already handled by api.R).

#' Parse a queryData response into a data.frame
#'
#' Power BI returns data in the DSR (Data Shape Response) format.
#' Consecutive rows that share leading column values are compressed
#' via a reference index (`R`).  Text columns may use dictionary
#' encoding (`ValueDicts`).
#'
#' @param resposta API response list from `queryData`.
#' @param tabela  Table name (for warning messages).
#' @return A `data.frame` with decoded, type-converted columns.
#' @keywords internal
.vigiar_parse_dados <- function(resposta, tabela) {
  data_section <- resposta$results[[1L]]$result$data

  if (is.null(data_section$dsr)) {
    warning("Tabela '", tabela, "' nao contem dados (dsr ausente).")
    return(data.frame())
  }

  ds  <- data_section$dsr$DS[[1L]]
  ph  <- ds$PH[[1L]]
  dm0 <- ph$DM0

  if (is.null(dm0) || length(dm0) == 0L) {
    warning("Tabela '", tabela, "': DM0 vazio.")
    return(data.frame())
  }

  first_entry <- dm0[[1L]]
  schema      <- first_entry$S
  n_cols      <- length(schema)

  if (n_cols == 0L) {
    warning("Tabela '", tabela, "': schema vazio.")
    return(data.frame())
  }

  descriptor <- data_section$descriptor
  col_names  <- vapply(descriptor$Select, `[[`, "", "Name",
                        USE.NAMES = FALSE)

  if (length(col_names) != n_cols) {
    warning(
      "Tabela '", tabela, "': descriptor tem ", length(col_names),
      " colunas mas schema tem ", n_cols, ". Usando nomes do schema."
    )
    col_names <- vapply(schema, `[[`, "", "N", USE.NAMES = FALSE)
  }

  col_types <- lapply(schema, function(s) {
    list(type = s$T, dn = s$DN %||% NULL)
  })

  value_dicts <- ds$ValueDicts %||% list()

  # -- Row reconstruction --------------------------------------------------
  prev_row <- NULL
  rows     <- vector("list", length(dm0))

  for (i in seq_along(dm0)) {
    entry <- dm0[[i]]

    if (!is.null(entry$S)) {
      # First / schema-carrying entry -- full row
      values <- entry$C
    } else {
      r        <- entry$R        # 1-based: keep (R - 1) columns from prev
      new_vals <- entry$C
      keep     <- as.integer(r) - 1L

      if (is.null(prev_row)) {
        warning(sprintf("Tabela '%s': DM0[%d] tem R mas sem linha anterior.",
                        tabela, i))
        values <- new_vals
      } else {
        if (keep > 0L) {
          values <- c(prev_row[seq_len(keep)], new_vals)
        } else {
          values <- new_vals
        }
      }
    }

    # Pad / truncate to expected column count
    len_val <- length(values)
    if (len_val < n_cols) {
      values <- c(values, rep(list(NA), n_cols - len_val))
    } else if (len_val > n_cols) {
      values <- values[seq_len(n_cols)]
    }

    # Resolve text dictionaries
    for (j in seq_len(n_cols)) {
      values[[j]] <- .vigiar_resolve_dict(values[[j]], j, col_types, value_dicts)
    }

    prev_row  <- values
    rows[[i]] <- values
  }

  # -- Build data.frame ----------------------------------------------------
  n_rows <- length(rows)
  df <- as.data.frame(
    matrix(nrow = n_rows, ncol = n_cols),
    stringsAsFactors = FALSE
  )
  names(df) <- col_names

  for (i in seq_len(n_rows)) {
    for (j in seq_len(n_cols)) {
      val <- rows[[i]][[j]]
      df[i, j] <- if (is.null(val)) NA else val
    }
  }

  # Apply column types
  for (j in seq_len(n_cols)) {
    df[[j]] <- .vigiar_converter_coluna(df[[j]], col_types[[j]]$type)
  }

  df
}

#' Resolve a single dictionary-encoded value
#' @keywords internal
.vigiar_resolve_dict <- function(val, col_idx, col_types, value_dicts) {
  dn <- col_types[[col_idx]]$dn
  if (is.null(dn)) return(val)
  dict <- value_dicts[[dn]]
  if (is.null(dict)) return(val)
  if (is.numeric(val) && val >= 0 && val < length(dict)) {
    return(dict[[as.integer(val) + 1L]])
  }
  val
}

#' Convert a column to the appropriate R type
#' @param x Column vector.
#' @param type_code Power BI data type code.
#' @return Converted vector.
#' @keywords internal
.vigiar_converter_coluna <- function(x, type_code) {
  # Replace NULL with NA
  x <- lapply(x, function(v) if (is.null(v)) NA else v)

  switch(as.character(type_code),
    `1` = as.character(unlist(x)),
    `2` = as.numeric(unlist(x)),
    `3` = as.numeric(unlist(x)),
    `4` = as.integer(unlist(x)),
    `5` = as.logical(unlist(x)),
    `6` = as.Date(unlist(x)),
    `7` = as.POSIXct(unlist(x), origin = "1970-01-01", tz = "UTC"),
    `8` = as.numeric(unlist(x)),
    as.character(unlist(x))  # fallback
  )
}
