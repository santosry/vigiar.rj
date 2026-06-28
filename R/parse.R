# R/parse.R
#
# DSR (Data Shape Response) parser for Power BI public endpoint.
#
# The Power BI queryData endpoint returns a compressed columnar format
# called DSR.  Each row in the DM0 array carries:
#   - "C": values for columns that CHANGED relative to the previous row
#   - "R": bitmask indicating which columns REPEAT from previous row
#          (bit i set => column i repeats).  R=3 (0b011) means cols 0,1
#          repeat; R=6 (0b110) means cols 1,2 repeat.
#   - ValueDicts: integer indices into a string dictionary (0-based).
#
# This is a reverse-engineered format -- no official specification exists.
# It may change without notice.  The parser validates structural
# assumptions and fails loudly on mismatch.

#' Parse a Power BI DSR response into a data.frame
#'
#' @param resposta Raw API response list from queryData endpoint.
#' @param tabela Table name for diagnostic messages.
#' @param raw If TRUE, return unprocessed rows list for debugging.
#' @param schema_check If TRUE, warn on column count mismatch.
#' @return A data.frame with decoded, type-converted columns.
#' @keywords internal
.vigiar_parse_dados <- function(resposta, tabela,
                                 raw = FALSE, schema_check = TRUE) {
  data_section <- resposta$results[[1L]]$result$data

  if (is.null(data_section$dsr)) {
    warning(sprintf("[%s] DSR ausente na resposta.", tabela))
    return(data.frame())
  }

  ds  <- data_section$dsr$DS[[1L]]
  ph  <- ds$PH[[1L]]
  dm0 <- ph$DM0

  if (is.null(dm0) || length(dm0) == 0L) {
    warning(sprintf("[%s] DM0 vazio.", tabela))
    return(data.frame())
  }

  # ---- Schema extraction ----
  descriptor <- data_section$descriptor
  col_names  <- vapply(descriptor$Select, `[[`, "", "Name", USE.NAMES = FALSE)
  n_cols     <- length(col_names)

  value_dicts <- ds$ValueDicts %||% list()

  # Extract dictionary names from the schema (first DM0 entry)
  first_entry <- dm0[[1L]]
  dict_names <- character(n_cols)
  if (!is.null(first_entry$S)) {
    for (j in seq_len(n_cols)) {
      dict_names[j] <- first_entry$S[[j]]$DN %||% ""
    }
  }

  # ---- Row reconstruction (bitmask-based) ----
  prev_row <- rep(NA, n_cols)
  rows     <- vector("list", length(dm0))
  out_idx  <- 0L

  for (i in seq_along(dm0)) {
    entry <- dm0[[i]]
    if (!is.list(entry)) next

    # Skip schema-only entries (no data values)
    if (is.null(entry$C) && !is.null(entry$S)) next

    repeat_mask <- as.integer(entry$R %||% 0L)
    # Power BI DSR uses unicode null-symbol as null-mask key.
    # detect it via known aliases: "S0" first, then "O" (ASCII alias)
    null_key <- "S0"
    if (!null_key %in% names(entry)) {
      null_key <- "O"
      if (!null_key %in% names(entry)) null_key <- character(0)
    }
    null_mask <- if (length(null_key) > 0) as.integer(entry[[null_key]] %||% 0L) else 0L
    changed     <- entry$C %||% list()

    row_vals <- vector("list", n_cols)
    cursor   <- 1L

    for (col in seq_len(n_cols)) {
      bit <- bitwShiftL(1L, col - 1L)
      repete <- bitwAnd(repeat_mask, bit) != 0L
      nulo   <- bitwAnd(null_mask, bit) != 0L

      if (repete) {
        if (i == 1L) {
          warning(sprintf("[%s] Linha 1 com mascara R=%d inesperada.",
                          tabela, repeat_mask))
          row_vals[[col]] <- NA
        } else {
          row_vals[[col]] <- prev_row[[col]]
        }
      } else if (nulo) {
        row_vals[[col]] <- NA
      } else if (cursor <= length(changed)) {
        val <- changed[[cursor]]
        cursor <- cursor + 1L
        # Resolve dictionary if applicable
        dn <- dict_names[col]
        if (nzchar(dn) && !is.null(value_dicts[[dn]])) {
          dict <- value_dicts[[dn]]
          if (is.numeric(val)) {
            idx <- as.integer(val) + 1L  # 0-based dict
            if (idx >= 1L && idx <= length(dict)) {
              val <- dict[[idx]]
            }
          }
        }
        row_vals[[col]] <- val
      } else {
        row_vals[[col]] <- NA
      }
    }

    prev_row     <- row_vals
    out_idx      <- out_idx + 1L
    rows[[out_idx]] <- row_vals
  }
  rows <- rows[seq_len(out_idx)]

  if (raw) return(rows)

  # ---- Build data.frame ----
  if (length(rows) == 0L) return(data.frame())

  n_rows <- length(rows)
  df <- as.data.frame(matrix(nrow = n_rows, ncol = n_cols),
                      stringsAsFactors = FALSE)
  names(df) <- col_names
  for (i in seq_len(n_rows)) {
    for (j in seq_len(n_cols)) {
      val <- rows[[i]][[j]]
      df[i, j] <- if (is.null(val)) NA else val
    }
  }

  # ---- Type conversion ----
  for (j in seq_len(n_cols)) {
    col_type <- descriptor$Select[[j]]$Type %||% 1L
    df[[j]] <- .vigiar_converter_coluna(df[[j]], col_type)
  }

  df
}

#' Convert a column to the appropriate R type
#' @param x Column vector.
#' @param type_code Power BI data type code.
#' @return Converted vector.
#' @keywords internal
.vigiar_converter_coluna <- function(x, type_code) {
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
    as.character(unlist(x))
  )
}
