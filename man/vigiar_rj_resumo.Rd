\name{vigiar_rj_resumo}
\alias{vigiar_rj_resumo}
\alias{vigiar_rj_series}
\alias{vigiar_validar_rj}
\title{Analyse and validate Rio de Janeiro VIGIAR data}
\usage{
vigiar_rj_resumo(dados, agregacao = c("municipio", "macrorregiao",
  "regiao_saude"))
vigiar_rj_series(dados, agregacao = c("macrorregiao", "regiao_saude"))
vigiar_validar_rj(dados, col_muni = NULL)
}
\arguments{
  \item{dados}{A processed VIGIAR tibble with municipality codes.}
  \item{agregacao}{Aggregation level.}
  \item{col_muni}{Name of the municipality code column (auto-detected).}
}
\value{
  \code{vigiar_rj_resumo} returns a tibble with summary statistics
  aggregated by the chosen level.

  \code{vigiar_rj_series} is an alias for \code{vigiar_rj_resumo}.

  \code{vigiar_validar_rj} invisibly returns a list with validation
  results (n_rj, n_fora_rj, codigos_fora_rj, valido).
}
\description{
  \code{vigiar_rj_resumo} aggregates VIGIAR data by municipality,
  health macro-region, or health region.

  \code{vigiar_validar_rj} checks that all municipality codes belong
  to the state of Rio de Janeiro.
}
\examples{
\dontrun{
vigiar_conectar()
pm25 <- vigiar_baixar_rj("df_anual") |> process_vigiar(tabela = "df_anual")
vigiar_rj_resumo(pm25, "macrorregiao")
vigiar_validar_rj(pm25)
}
}
