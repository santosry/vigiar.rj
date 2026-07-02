# Manual online validation for Rio de Janeiro download completeness.
#
# This script intentionally requires internet access and is not run by CI.
# Outputs are written under data-raw/rj-download-completeness-output/, which is
# ignored by Git. Set VIGIAR_VALIDATION_RELEASE to the release tag when the
# report should be archived with a formal package release.

if (file.exists("DESCRIPTION") && requireNamespace("pkgload", quietly = TRUE)) {
  pkgload::load_all(".")
} else {
  library(vigiar)
}

release_id <- Sys.getenv(
  "VIGIAR_VALIDATION_RELEASE",
  unset = paste0("vigiar-", utils::packageVersion("vigiar"))
)
run_id <- paste(release_id, format(Sys.time(), "%Y%m%d-%H%M%S"), sep = "-")
out_dir <- file.path("data-raw", "rj-download-completeness-output", run_id)
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)
manifest <- list()

write_report <- function(x, name) {
  path <- file.path(out_dir, name)
  list_cols <- vapply(x, is.list, logical(1))
  x[list_cols] <- lapply(x[list_cols], function(col) {
    vapply(col, paste, collapse = "; ", FUN.VALUE = character(1))
  })
  utils::write.csv(x, path, row.names = FALSE)
  message("Wrote: ", normalizePath(path, winslash = "/", mustWork = FALSE))
}

print_absent <- function(dados, label, por = "geral") {
  missing <- vigiar_rj_municipios_ausentes(dados, por = por)
  message("\nAbsent municipalities for ", label, " (", por, "):")
  if (nrow(missing) == 0) {
    message("none")
  } else {
    print(missing)
  }
  invisible(missing)
}

manifest_row <- function(tab, dados, cobertura) {
  data.frame(
    run_id = run_id,
    release = release_id,
    checked_at = format(Sys.time(), "%Y-%m-%dT%H:%M:%S%z"),
    tabela = tab,
    n_rows = nrow(dados),
    n_cols = ncol(dados),
    checksum = vigiar_checksum(dados),
    n_municipios_presentes = cobertura$n_municipios_presentes[[1]],
    n_municipios_esperados = cobertura$n_municipios_esperados[[1]],
    cobertura_pct = cobertura$cobertura_pct[[1]],
    n_ausentes = cobertura$n_ausentes[[1]],
    possivel_truncamento = isTRUE(attr(dados, "vigiar_possivel_truncamento")),
    stringsAsFactors = FALSE
  )
}

vigiar_conectar()
on.exit(vigiar_desconectar(), add = TRUE)

tables <- c("df_muni", "df_anual", "df_mensal")

for (tab in tables) {
  message("\nChecking ", tab, "...")
  should_process <- tab %in% c("df_anual", "df_mensal")
  dados <- tryCatch(
    vigiar_baixar_rj(tab, validar_cobertura = TRUE, processar = should_process),
    error = function(e) {
      warning("Download failed for ", tab, ": ", conditionMessage(e), call. = FALSE)
      NULL
    }
  )

  if (is.null(dados)) {
    next
  }

  cov_general <- vigiar_rj_cobertura(dados)
  write_report(cov_general, paste0(tab, "-coverage-general.csv"))
  manifest[[tab]] <- manifest_row(tab, dados, cov_general)
  print_absent(dados, tab)

  if ("ano" %in% names(dados)) {
    cov_year <- vigiar_rj_cobertura(dados, por = "ano")
    write_report(cov_year, paste0(tab, "-coverage-year.csv"))
    print_absent(dados, tab, por = "ano")
  }

  if (all(c("ano", "mes") %in% names(dados))) {
    cov_year_month <- vigiar_rj_cobertura(dados, por = "ano_mes")
    write_report(cov_year_month, paste0(tab, "-coverage-year-month.csv"))
  }

  saveRDS(dados, file.path(out_dir, paste0(tab, "-rj.rds")))
}

if (length(manifest) > 0) {
  write_report(do.call(rbind, manifest), "manifest.csv")
}

message("\nValidation run archived under: ", normalizePath(out_dir, winslash = "/", mustWork = FALSE))
