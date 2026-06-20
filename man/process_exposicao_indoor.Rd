\name{process_exposicao_indoor}
\alias{process_exposicao_indoor}
\title{Process indoor exposure data}
\usage{
process_exposicao_indoor(dados, tipo = c("exposicao", "desfecho"), ...)
}
\arguments{
  \item{dados}{Raw data from \code{vigiar_baixar("df_indoor")} or \code{"df_indoor_desfecho"}.}
  \item{tipo}{One of \code{"exposicao"} or \code{"desfecho"}.}
  \item{...}{Additional arguments (ignored).}
}
\value{
  A \code{vigiar_indoor} tibble.
}
\description{
  Standardises household solid fuel exposure data.
}
\examples{
\dontrun{
vigiar_conectar()
indoor <- vigiar_baixar("df_indoor") |> process_exposicao_indoor()
}
}
