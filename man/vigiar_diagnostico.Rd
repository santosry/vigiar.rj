\name{vigiar_diagnostico}
\alias{vigiar_diagnostico}
\title{Diagnostic summary of all tables}
\usage{
vigiar_diagnostico(amostra = 100)
}
\arguments{
  \item{amostra}{Number of rows to sample per table.}
}
\value{
  Invisibly, a named list of diagnostics per table.
}
\description{
  Downloads a small sample from every table and reports basic
  diagnostics to detect schema changes or data issues.
}
\examples{
\dontrun{
vigiar_conectar()
vigiar_diagnostico(amostra = 50)
}
}
