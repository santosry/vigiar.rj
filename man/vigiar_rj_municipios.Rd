\name{vigiar_rj_municipios}
\alias{vigiar_rj_municipios}
\alias{vigiar_rj_macrorregioes}
\alias{vigiar_rj_regioes_saude}
\title{Rio de Janeiro municipalities and health regions}
\usage{
vigiar_rj_municipios()
vigiar_rj_macrorregioes()
vigiar_rj_regioes_saude()
}
\value{
  \code{vigiar_rj_municipios} returns a data.frame with 92 municipalities
  (codigo_ibge, municipio, macrorregiao_saude, regiao_saude).

  \code{vigiar_rj_macrorregioes} returns the 9 health macro-regions.

  \code{vigiar_rj_regioes_saude} returns the health regions.
}
\description{
  Official registry of the 92 Rio de Janeiro municipalities
  with SES-RJ health macro-regions.
}
\examples{
vigiar_rj_municipios()
vigiar_rj_macrorregioes()
}
