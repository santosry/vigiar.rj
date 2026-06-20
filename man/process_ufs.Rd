\name{process_ufs}
\alias{process_ufs}
\title{Process UF-level data}
\usage{
process_ufs(dados, contexto = "uf")
}
\arguments{
  \item{dados}{Raw data frame.}
  \item{contexto}{Description of the data context.}
}
\value{
  A \code{vigiar_uf} tibble.
}
\description{
  Generic processor for any UF-level VIGIAR data.
}
\examples{
\dontrun{
vigiar_conectar()
dados <- vigiar_baixar("aux_uf")
uf <- process_ufs(dados)
}
}
