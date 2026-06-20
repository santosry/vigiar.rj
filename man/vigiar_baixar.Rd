\name{vigiar_baixar}
\alias{vigiar_baixar}
\title{Download data from a single VIGIAR table}
\usage{
vigiar_baixar(tabela, colunas = NULL, ordenar_por = NULL,
               limite = NULL, timeout = 120, uf = NULL)
}
\arguments{
  \item{tabela}{Table name (use \code{vigiar_tabelas()} to list).}
  \item{colunas}{Optional character vector of column names. \code{NULL} = all.}
  \item{ordenar_por}{Column to sort by (optional).}
  \item{limite}{Maximum number of rows (optional).}
  \item{timeout}{Timeout in seconds for the HTTP request.}
  \item{uf}{Optional UF filter (e.g. \code{"RJ"}). Filters client-side after download.}
}
\value{
  A \code{\link[tibble]{tibble}} with the downloaded data.
}
\description{
  Queries the Power BI API and returns a single table as a tidy tibble.
}
\examples{
\dontrun{
vigiar_conectar()
df_anual <- vigiar_baixar("df_anual")
df_mensal <- vigiar_baixar("df_mensal",
  colunas = c("ano", "UF", "pm25"))
}
}
