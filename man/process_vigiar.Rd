\name{process_vigiar}
\alias{process_vigiar}
\title{Process VIGIAR data — generic dispatcher}
\usage{
process_vigiar(dados, tabela = NULL, ...)
}
\arguments{
  \item{dados}{A data frame returned by \code{vigiar_baixar()}.}
  \item{tabela}{Table name (auto-detected if \code{dados} has the attribute).}
  \item{...}{Additional arguments passed to specific processors.}
}
\value{
  A \code{vigiar_tbl} with standardised columns and metadata.
}
\description{
  Automatically detects the table type and applies the appropriate
  processing pipeline: standardises column names, converts types,
  validates IBGE codes, and adds metadata attributes.
}
\examples{
\dontrun{
vigiar_conectar()
dados <- vigiar_baixar("df_anual")
pm25 <- process_vigiar(dados, tabela = "df_anual")
}
}
