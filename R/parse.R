# Package: vigiar.rj
# Robust DSR (Data Shape Response) parser
#
# Decodes Power BI's proprietary compressed format:
#   DM0  – array of data blocks with schema (S), references (R), and values (C)
#   Dict – ValueDicts for text column compression (0-based indices)
#   Gzip – transparent decompression

#' Parse a Power BI DSR response into a data.frame
#'
#' Handles the compressed Data Shape Response format used by
#' Power BI's queryData endpoint.  Supports standard (R=3)
#' and ORDER BY variants (R=4/R=6).
#'
#' @param resposta Raw API response list.
#' @param tabela Table name for diagnostics.
#' @param raw If TRUE, returns unprocessed rows list for debugging.
#' @param schema_check If TRUE, warns on schema mismatch vs expected columns.
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
  first_entry <- dm0[[1L]]
  if (is.null(first_entry$S)) {
    warning(sprintf("[%s] Schema (S) ausente no primeiro bloco DM0.", tabela))
    return(data.frame())
  }

  schema     <- first_entry$S
  n_cols     <- length(schema)
  col_names  <- vapply(data_section$descriptor$Select, `[[`, "",
                       "Name", USE.NAMES = FALSE)

  if (schema_check && length(col_names) != n_cols) {
    warning(sprintf(
      "[%s] Descriptor tem %d colunas mas schema tem %d.",
      tabela, length(col_names), n_cols
    ))
    col_names <- vapply(schema, `[[`, "", "N", USE.NAMES = FALSE)
  }

  col_types <- lapply(schema, function(s) {
    list(type = s$T, dn = s$DN %||% NULL)
  })
  value_dicts <- ds$ValueDicts %||% list()

  # ---- Row reconstruction ----
  rows     <- .vigiar_reconstruct_rows(dm0, n_cols, tabela)
  if (raw) return(rows)

  # ---- Dictionary resolution ----
  for (j in seq_len(n_cols)) {
    dn <- col_types[[j]]$dn
    if (is.null(dn) || is.null(value_dicts[[dn]])) next
    dict <- value_dicts[[dn]]
    for (i in seq_along(rows)) {
      val <- rows[[i]][[j]]
      if (is.numeric(val) && val >= 0 && val < length(dict)) {
        rows[[i]][[j]] <- dict[[as.integer(val) + 1L]]
      }
    }
  }

  # ---- Build data.frame ----
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
    df[[j]] <- .vigiar_converter_coluna(df[[j]], col_types[[j]]$type)
  }

  df
}

#' Reconstruct rows from DM0 entries
#'
#' Handles standard (R < n_cols), ORDER BY (R >= n_cols),
#' and plain C entries.
#'
#' @param dm0 DM0 array from Power BI response.
#' @param n_cols Number of columns expected.
#' @param tabela Table name for warnings.
#' @return List of rows (each row is a list of values).
#' @keywords internal
.vigiar_reconstruct_rows <- function(dm0, n_cols, tabela) {
  prev_row <- NULL
  rows     <- vector("list", length(dm0))
  out_idx  <- 0L

  for (i in seq_along(dm0)) {
    entry <- dm0[[i]]

    if (!is.null(entry$S)) {
      # Schema-carrying entry — always a full row
      values <- entry$C
    } else if (!is.null(entry$R)) {
      r        <- entry$R
      new_vals <- entry$C
      keep     <- as.integer(r) - 1L

      if (is.null(prev_row)) {
        values <- new_vals
      } else if (r >= as.integer(n_cols)) {
        # Compressed format used with ORDER BY queries.
        # R >= n_cols: C provides values for positions 0..len(C)-1
        # and column (n_cols-1).  Intermediate columns repeat.
        values <- prev_row
        n_new  <- length(new_vals)
        if (n_cols == 4L && n_new == 2L) {
          values[[1L]] <- new_vals[[1L]]       # muni
          values[[4L]] <- new_vals[[2L]]       # PM2.5
        } else if (n_cols == 4L && n_new == 3L) {
          values[[1L]] <- new_vals[[1L]]
          values[[2L]] <- new_vals[[2L]]
          values[[4L]] <- new_vals[[3L]]
        } else {
          for (k in seq_len(min(n_new, n_cols))) {
            values[[k]] <- new_vals[[k]]
          }
        }
      } else if (keep > 0L) {
        values <- c(prev_row[seq_len(keep)], new_vals)
      } else {
        values <- new_vals
      }
    } else if (!is.null(entry$C)) {
      values <- entry$C
    } else {
      next
    }

    # Pad or truncate
    len_val <- length(values)
    if (len_val < n_cols) {
      values <- c(values, rep(list(NA), n_cols - len_val))
    } else if (len_val > n_cols) {
      values <- values[seq_len(n_cols)]
    }

    prev_row     <- values
    out_idx      <- out_idx + 1L
    rows[[out_idx]] <- values
  }

  rows[seq_len(out_idx)]
}
