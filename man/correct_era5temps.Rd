% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/correction_functions.R
\name{correct_era5temps}
\alias{correct_era5temps}
\title{Applies bias correction to UK era5 temperature data}
\usage{
correct_era5temps(era5hourly, era5correctmodels)
}
\arguments{
\item{era5hourly}{a stacked SpatRast of hourly ERA5 temperature data for any part
of the UK.}

\item{era5correctmodels}{a list of model correction coefficients for each UK
grid cell. Available: https://universityofexeteruk-my.sharepoint.com/:f:/g/personal/i_m_d_maclean_exeter_ac_uk/EjxJdJq0MClFqUU3LATlcnEBo1cGFiUAxqLQALNNxvdZaw?e=wLR2Rf
Zenodo link to be added dreckly.}
}
\value{
a SpatRast of bias corrected temperature data
}
\description{
The function \code{correct_era5temps} applies automatic bias correction to era5
temperature data data to correct for unaturally low diurnal temperature
fluctuations in coastal grid cells.
}
\details{
\code{era5correctmodels} was derived by applying \code{\link[=biascorrect]{biascorrect()}} to a 2018
dataset of era5 temperature data, calibrating against Met office data
}
\keyword{biascorrect}
