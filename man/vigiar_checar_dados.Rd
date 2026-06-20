\name{vigiar_checar_dados}
\alias{vigiar_checar_dados}
\alias{vigiar_diagnostico}
\title{Validate downloaded VIGIAR data}
\usage{
vigiar_checar_dados(dados, tabela = NULL)
vigiar_diagnostico(amostra = 100)
}
\arguments{
  \item{dados}{A data frame returned by \code{vigiar_baixar()}.}
  \item{tabela}{Table name (for display).}
  \item{amostra}{Number of rows to sample per table in \code{vigiar_diagnostico()}.}
}
\value{
  \code{vigiar_checar_dados} invisibly returns a list of diagnostics.
  \code{vigiar_diagnostico} invisibly returns a named list of diagnostics per table.
}
\description{
  \code{vigiar_checar_dados} reports missing values, duplicate rows,
  and column types for a single downloaded table.
  \code{vigiar_diagnostico} samples every table and runs diagnostics
  to detect schema changes or data issues.
}
\examples{
\dontrun{
vigiar_conectar()
df <- vigiar_baixar("df_anual", limite = 100)
vigiar_checar_dados(df, "df_anual")
}
}
