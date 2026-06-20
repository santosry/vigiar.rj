\name{process_populacao_exposta}
\alias{process_populacao_exposta}
\title{Process population exposure data}
\usage{
process_populacao_exposta(dados, ...)
}
\arguments{
  \item{dados}{Raw data frame from \code{vigiar_baixar("pop")}.}
  \item{...}{Additional arguments (ignored).}
}
\value{
  A \code{vigiar_population} tibble.
}
\description{
  Standardises population data: renames columns to Portuguese
  convention, converts types, and validates IBGE codes.
}
\examples{
\dontrun{
vigiar_conectar()
pop <- vigiar_baixar("pop") |> process_populacao_exposta()
}
}
