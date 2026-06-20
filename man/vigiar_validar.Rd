\name{vigiar_validar_ibge}
\alias{vigiar_validar_ibge}
\alias{vigiar_validar_datas}
\alias{vigiar_validar_unidades}
\title{Validate VIGIAR data columns}
\usage{
vigiar_validar_ibge(dados, col_codigo = "cod_municipio")
vigiar_validar_datas(dados)
vigiar_validar_unidades(dados, col_pm25 = "pm25_media")
}
\arguments{
  \item{dados}{A data frame.}
  \item{col_codigo}{Name of the column containing IBGE municipality codes.}
  \item{col_pm25}{Name of the PM2.5 column.}
}
\value{
  The data frame (unchanged), with warnings on invalid values.
}
\description{
  \code{vigiar_validar_ibge} checks that municipality codes are
  6- or 7-digit integers in the range 110001--530010.

  \code{vigiar_validar_datas} checks that \code{ano} is between
  2000 and the current year, and \code{mes} between 1 and 12.

  \code{vigiar_validar_unidades} checks that PM2.5 values are
  within the plausible range 0--1000 µg/m³.
}
