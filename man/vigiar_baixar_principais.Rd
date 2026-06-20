\name{vigiar_baixar_principais}
\alias{vigiar_baixar_principais}
\title{Download main VIGIAR tables}
\usage{
vigiar_baixar_principais()
}
\value{
  Named list of tibbles.
}
\description{
  Convenience shortcut that downloads 14 key tables: PM2.5,
  population, health indicators, attributable fractions,
  indoor exposure, and municipality registry.
}
\examples{
\dontrun{
vigiar_conectar()
tudo <- vigiar_baixar_principais()
}
}
