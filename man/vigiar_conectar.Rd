\name{vigiar_conectar}
\alias{vigiar_conectar}
\title{Connect to the VIGIAR Power BI dashboard}
\usage{
vigiar_conectar(refresh = FALSE, timeout = 30, max_retries = 3)
}
\arguments{
  \item{refresh}{If \code{TRUE}, force a new session even if one exists.}
  \item{timeout}{Maximum time in seconds to establish the connection.}
  \item{max_retries}{Maximum number of retry attempts on transient failures.}
}
\value{
  Invisibly, a list of class \code{"vigiar_sessao"} with session data.
}
\description{
  Establishes an anonymous session with the public VIGIAR Power BI
  dashboard and fetches the conceptual schema (table and column metadata).
}
\examples{
\dontrun{
vigiar_conectar()
vigiar_conectar(refresh = TRUE, timeout = 60)
}
}
