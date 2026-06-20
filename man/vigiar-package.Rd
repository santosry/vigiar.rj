\name{vigiar-package}
\alias{vigiar-package}
\alias{vigiar}
\docType{package}
\title{
  Download Data from the VIGIAR Environmental Health Surveillance
  Dashboard
}
\description{
  Provides a programmatic interface to download the complete dataset
  from Brazil's VIGIAR (Vigilância em Saúde Ambiental) public Power BI
  dashboard, maintained by the Brazilian Ministry of Health.
}
\details{
  \tabular{ll}{
    Package: \tab vigiar \cr
    Type:    \tab Package \cr
    Version: \tab 0.1.0 \cr
    License: \tab MIT \cr
  }

  Key functions:
  \itemize{
    \item \code{\link{vigiar_conectar}} — establish session
    \item \code{\link{vigiar_baixar}} — download a single table
    \item \code{\link{vigiar_baixar_tudo}} — download all tables
    \item \code{\link{vigiar_info}} — table catalogue
    \item \code{\link{vigiar_checar_dados}} — validate downloaded data
    \item \code{\link{vigiar_status}} — check dashboard status
  }
}
\author{
  \strong{Maintainer}: Ryan Santos \email{santosry@protonmail.com}
}
\keyword{package}
