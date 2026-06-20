\name{process_fracao_atribuivel}
\alias{process_fracao_atribuivel}
\title{Process attributable fraction data}
\usage{
process_fracao_atribuivel(dados, ...)
}
\arguments{
  \item{dados}{Raw data from \code{vigiar_baixar("tb_fracao")}.}
  \item{...}{Additional arguments (ignored).}
}
\value{
  A \code{vigiar_attributable_fraction} tibble.
}
\description{
  Standardises attributable fraction data: renames columns,
  converts types, and adds metadata.
}
\examples{
\dontrun{
vigiar_conectar()
fracao <- vigiar_baixar("tb_fracao") |> process_fracao_atribuivel()
}
}
