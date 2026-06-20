\name{pipe-null}
\alias{\%||\%}
\title{NULL-coalescing operator}
\usage{
x \%||\% y
}
\arguments{
  \item{x}{A value.}
  \item{y}{A fallback value.}
}
\value{
  \code{x} if not \code{NULL}, otherwise \code{y}.
}
\description{
  Returns the left-hand side unless it is \code{NULL},
  in which case the right-hand side is returned.
}
\keyword{internal}
