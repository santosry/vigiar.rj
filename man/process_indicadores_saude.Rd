\name{process_indicadores_saude}
\alias{process_indicadores_saude}
\title{Process health indicators data}
\usage{
process_indicadores_saude(dados, agregacao = c("brasil", "uf", "municipio", "quartis"), ...)
}
\arguments{
  \item{dados}{Raw data from \code{vigiar_baixar("tb_brasil")}, \code{"tb_uf"}, \code{"tb_muni"}, or \code{"tb_quartis"}.}
  \item{agregacao}{Aggregation level.}
  \item{...}{Additional arguments (ignored).}
}
\value{
  A \code{vigiar_health} tibble.
}
\description{
  Standardises health indicator data: renames \code{Indicador} to
  \code{indicador}, \code{est} to \code{estimativa}, \code{low}/\code{high} to
  \code{ic_inferior}/\code{ic_superior}, and validates IBGE codes where applicable.
}
\examples{
\dontrun{
vigiar_conectar()
brasil <- vigiar_baixar("tb_brasil") |> process_indicadores_saude(agregacao = "brasil")
}
}
