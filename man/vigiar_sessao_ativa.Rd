\name{vigiar_sessao_ativa}
\alias{vigiar_sessao_ativa}
\title{Check if a VIGIAR session is active}
\usage{
vigiar_sessao_ativa()
}
\value{
  \code{TRUE} if a session exists, \code{FALSE} otherwise.
}
\description{
  Returns whether a connection to the VIGIAR Power BI dashboard
  is currently established.
}
\examples{
\dontrun{
vigiar_conectar()
vigiar_sessao_ativa()
}
}
