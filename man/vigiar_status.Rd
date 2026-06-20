\name{vigiar_status}
\alias{vigiar_status}
\title{Check VIGIAR dashboard status}
\usage{
vigiar_status()
}
\value{
  Invisibly, a list with \code{online} and \code{tables_ok} flags.
}
\description{
  Verifies that the Power BI dashboard is reachable and that the
  conceptual schema is consistent with the cached version.
}
\examples{
\dontrun{
vigiar_conectar()
vigiar_status()
}
}
