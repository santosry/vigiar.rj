\name{vigiar.rj-package}
\alias{vigiar.rj-package}
\alias{vigiar.rj}
\docType{package}
\title{VIGIAR Environmental Health Data for Rio de Janeiro}
\description{
  Specialized package to download, process, validate and analyse
  environmental health surveillance data from VIGIAR with focus
  on the state of Rio de Janeiro (92 municipalities).
}
\details{
  \tabular{ll}{
    Package: \tab vigiar.rj \cr
    Type:    \tab Package \cr
    Version: \tab 0.4.0 \cr
    License: \tab MIT \cr
  }

  Key functions:
  \itemize{
    \item \code{\link{vigiar_conectar}} — connect to dashboard
    \item \code{\link{vigiar_baixar_rj}} — download RJ data
    \item \code{\link{vigiar_rj_municipios}} — list 92 municipalities
    \item \code{\link{vigiar_rj_resumo}} — summarise by health region
    \item \code{\link{vigiar_validar_rj}} — validate RJ data
  }
}
\author{
  \strong{Maintainer}: Ryan Santos \email{ryan.paulo@gsuite.iff.edu.br}
}
\keyword{package}
