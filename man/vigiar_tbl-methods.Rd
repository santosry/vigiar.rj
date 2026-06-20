\name{vigiar_tbl-methods}
\alias{print.vigiar_tbl}
\alias{summary.vigiar_tbl}
\alias{validate.vigiar_tbl}
\title{S3 methods for vigiar_tbl objects}
\usage{
\method{print}{vigiar_tbl}(x, ...)
\method{summary}{vigiar_tbl}(object, ...)
\method{validate}{vigiar_tbl}(x, ...)
}
\arguments{
  \item{x, object}{A \code{vigiar_tbl} object.}
  \item{...}{Additional arguments (ignored).}
}
\value{
  \code{print} returns \code{x} invisibly.
  \code{summary} returns \code{object} invisibly.
  \code{validate} returns a list of issues (invisibly).
}
\description{
  S3 methods for typed VIGIAR data:
  \itemize{
    \item \code{print()} — displays table type, dimensions, and processing timestamp.
    \item \code{summary()} — reports dimensions, classes, and missing values.
    \item \code{validate()} — checks for required attributes and empty data.
  }
}
