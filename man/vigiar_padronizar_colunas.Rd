\name{vigiar_padronizar_colunas}
\alias{vigiar_padronizar_colunas}
\title{Standardise VIGIAR column names}
\usage{
vigiar_padronizar_colunas(dados, tabela)
}
\arguments{
  \item{dados}{A data frame.}
  \item{tabela}{Table name used to look up the dictionary.}
}
\value{
  A data frame with standardised column names.
}
\description{
  Applies a standard naming convention to raw VIGIAR data using
  the internal variable dictionary.
}
\keyword{internal}
