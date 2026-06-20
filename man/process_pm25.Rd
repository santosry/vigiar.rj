\name{process_pm25}
\alias{process_pm25}
\title{Process PM2.5 air quality data}
\usage{
process_pm25(dados, tipo = c("anual", "mensal", "dias", "dias_conama"), ...)
}
\arguments{
  \item{dados}{Raw data frame from \code{vigiar_baixar()}.}
  \item{tipo}{One of \code{"anual"}, \code{"mensal"}, \code{"dias"}, or \code{"dias_conama"}.}
  \item{...}{Additional arguments (ignored).}
}
\value{
  A \code{vigiar_pm25} tibble with standardised columns.
}
\description{
  Standardises column names, converts types, validates IBGE codes,
  and adds metadata to PM2.5 data. Supports annual averages,
  monthly averages, and critical days (OMS and CONAMA).
}
\examples{
\dontrun{
vigiar_conectar()
pm25 <- vigiar_baixar("df_anual") |> process_pm25()
}
}
