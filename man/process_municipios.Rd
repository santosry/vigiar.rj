\name{process_municipios}
\alias{process_municipios}
\title{Process municipality registry data}
\usage{
process_municipios(dados, ...)
}
\arguments{
  \item{dados}{Raw data from \code{vigiar_baixar("df_muni")}.}
  \item{...}{Additional arguments (ignored).}
}
\value{
  A \code{vigiar_municipios} tibble.
}
\description{
  Standardises the municipality registry: renames columns
  to Portuguese convention, converts coordinate types, and
  validates IBGE codes.
}
\examples{
\dontrun{
vigiar_conectar()
muni <- vigiar_baixar("df_muni") |> process_municipios()
}
}
