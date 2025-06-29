% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/jasmin_functions.R
\name{addtrees_hadukdata}
\alias{addtrees_hadukdata}
\title{Get HadUK data from ceda archive on jasmine}
\usage{
addtrees_hadukdata(
  startdate,
  enddate,
  dtmc,
  filepath =
    "/badc/ukmo-hadobs/data/insitu/MOHC/HadOBS/HadUK-Grid/v1.2.0.ceda/1km/rainfall/day/latest",
  var = c("rainfall", "tasmax", "tasmin")
)
}
\arguments{
\item{startdate}{\itemize{
\item POSIXlt value indicating start date for data required
}}

\item{enddate}{\itemize{
\item POSIXlt value indicating end date for data required
}}

\item{dtmc}{\itemize{
\item spatraster to which data will be resampled/cropped
}}

\item{filepath}{\itemize{
\item dir where HADUK source files located
}}

\item{varn}{variable required, one or more of: 'rainfall','tasmax','tasmin' available at daily time steps}
}
\value{
spatRaster
}
\description{
Get HadUK data from ceda archive on jasmine
}
\seealso{
\code{\link[=download_hadukdaily]{download_hadukdaily()}}
\dontrun{

}
}
\keyword{jasmin}
