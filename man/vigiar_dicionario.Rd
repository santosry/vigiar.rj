\name{vigiar_dicionario}
\alias{vigiar_dicionario}
\alias{vigiar_variaveis}
\alias{vigiar_descrever_variavel}
\alias{vigiar_convencoes}
\alias{vigiar_schema}
\title{Query the VIGIAR variable dictionary}
\usage{
vigiar_dicionario()
vigiar_variaveis(dominio = c("pm25", "populacao_exposta", "indicadores_saude",
  "fracao_atribuivel", "exposicao_indoor", "municipios", "all"))
vigiar_descrever_variavel(dominio, variavel)
vigiar_convencoes()
vigiar_schema(dominio = "all")
}
\arguments{
  \item{dominio}{Data domain. One of \code{"pm25"}, \code{"populacao_exposta"},
    \code{"indicadores_saude"}, \code{"fracao_atribuivel"},
    \code{"exposicao_indoor"}, \code{"municipios"}, or \code{"all"}.}
  \item{variavel}{Standard variable name.}
}
\value{
  \code{vigiar_dicionario} returns the complete variable dictionary as a tibble.

  \code{vigiar_variaveis} returns a subset for a specific domain.

  \code{vigiar_descrever_variavel} prints details for one variable.

  \code{vigiar_schema} returns a schema overview for a domain.
}
\description{
  Functions to explore the VIGIAR data dictionary, which documents
  every variable: original name, standardised name, type, description,
  unit, allowed values, and processing rules.
}
\examples{
\dontrun{
vigiar_dicionario()
vigiar_variaveis("pm25")
vigiar_descrever_variavel("pm25", "pm25_media_anual")
vigiar_schema("indicadores_saude")
}
}
