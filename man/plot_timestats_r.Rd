% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/graph_functions.R
\name{plot_timestats_r}
\alias{plot_timestats_r}
\title{Plot timeseries plots of spatial mean, min and max values by various timesteps}
\usage{
plot_timestats_r(
  r,
  v,
  idx = c("years", "months", "week", "doy", "yearmonths", "yearweeks", "7days", "hour"),
  lgd = FALSE
)
}
\arguments{
\item{r}{stack of spatrasters with time values}

\item{idx}{time index indicating whether summary plots by year, month, week, day of year etc}

\item{lgd}{whether to include legend}

\item{var}{variable name used in plot titles}
}
\value{
NA plots series of timeploat
}
\description{
Plot timeseries plots of spatial mean, min and max values by various timesteps
}
\keyword{graph}
