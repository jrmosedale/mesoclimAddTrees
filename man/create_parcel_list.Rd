% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/parcel_functions.R
\name{create_parcel_list}
\alias{create_parcel_list}
\title{Calculates climate timeseries for vector parcels}
\usage{
create_parcel_list(
  climdata,
  parcels,
  id = "gid",
  output_tmean = TRUE,
  output_spechum = FALSE
)
}
\arguments{
\item{climdata}{\itemize{
\item list of SpatRasters of downscaled mesoclimate variables as output by \code{spatialdownscale}
}}

\item{parcels}{\itemize{
\item sf or vect describing polygons for which climate data is required
}}

\item{id}{\itemize{
\item string of variable name in parcels corresponding to parcel identification field
}}

\item{output_tmean}{\itemize{
\item output tmean to parcel file -  must be among climdata variables
}}

\item{output_spechum}{\itemize{
\item if TRUE also outputs specific humidity
}}
}
\value{
list of dataframes of climate variable timeseries by parcel.
}
\description{
Calculates timeseries of climate variables for each polygon in parcels using weighted means of overlapping grid cells.
}
\details{
Output variables, order and names:
"tmax", "tmin","swdown","lwdown","spchum","pres","prec", "windspeed" and
if requested using output_spechum, "spchum"
}
\keyword{"tmin","swdown","lwdown","spchum","pres","prec",}
\keyword{"tmin","swrad","lwrad","relhum","pres","prec",}
\keyword{"windspeed")}
\keyword{"windspeed"),}
\keyword{#'}
\keyword{)}
\keyword{@examples}
\keyword{\dontrun{}
\keyword{data}
\keyword{input_names=c("tmax",}
\keyword{output_names=c("tmax",}
\keyword{plist<-create_parcel_list_v2(mesoclimate,parcels_v,id='gid',}
\keyword{postprocess}
\keyword{}}
