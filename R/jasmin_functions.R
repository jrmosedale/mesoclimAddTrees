
#' @title Get HadUK data from ceda archive on jasmine
#'
#' @param startdate - POSIXlt value indicating start date for data required
#' @param enddate - POSIXlt value indicating end date for data required
#' @param dtmc - spatraster to which data will be resampled/cropped
#' @param filepath - dir where HADUK source files located
#' @param varn  variable required, one or more of: 'rainfall','tasmax','tasmin' available at daily time steps
#'
#' @return spatRaster
#' @export
#' @importFrom terra crop extend rast project same.crs
#' @importFrom mesoclim .resample
#' @keywords jasmin
#' @seealso [download_hadukdaily()]
#' \dontrun{
#'
#' }
addtrees_hadukdata<-function(startdate, enddate, dtmc, filepath="/badc/ukmo-hadobs/data/insitu/MOHC/HadOBS/HadUK-Grid/v1.2.0.ceda/1km/rainfall/day/latest",
                             var=c('rainfall','tasmax','tasmin')) {
  # Checks
  varn<-match.arg(var)
  if (any(!var %in% c("rainfall","tasmax","tasmin")) ) stop("Chosen variables are not available as daily data!!" )
  if(class(startdate)[1]!="POSIXlt" | class(enddate)[1]!="POSIXlt") stop("Date parameters NOT POSIXlt class!!")

  # Derive months of data required
  dateseq<-seq(as.Date(startdate) + 1, as.Date(enddate) + 1, by = "1 months") - 1
  yrs<-year(dateseq)
  mnths<-month(dateseq)

  # Get date text used in file names
  mtxt<-ifelse(mnths<10,paste0("0",mnths),paste0("",mnths))
  daysofmonth<-c(31,28,31,30,31,30,31,31,30,31,30,31)
  mdays<-daysofmonth[mnths]
  mdays<-ifelse((yrs%%4==0 & mnths==2),29,mdays)
  files<-paste0(var,"_hadukgrid_uk_1km_day_",yrs,mtxt,"01-",yrs,mtxt,mdays,".nc")

  # Get aoi in projection of HadUK data OS projection and extend by one cell
  r<-terra::rast(file.path(filepath,files[1]))
  if(!terra::same.crs(dtmc,r)) dtmc<-terra::project(dtmc,r)
  dtmc_ext<-terra::crop(terra::extend(dtmc,1),dtmc)

  # Load all monthly files to spatRaster then resample
  r_list<-list()
  n<-1
  for (f in files){
    r<-rast(file.path(filepath,f))
    #terra::crs(r)<-'epsg:27700'
    e<-terra::crop(terra::extend(terra::crop(r[[1]],dtmc,snap='out'),1),r[[1]])
    r<-terra::crop(r,e)
    r<-mesoclim::.resample(r,dtmc,msk=TRUE)
    r_list[[n]]<-r
    n<-n+1
  }
  rout<-rast(r_list)
  return(rout)
}


#' @title Get ukcp18 RCM 12km DTM from ceda archive
#'
#' @param aoi - used to cut dtm
#' @param ukcpdtm_file - full path to UKCP18RCM orography/dtm file
#'
#' @return spatrast object cropped to extended aoi
#' @export
#' @importFrom terra vect rast ext crs project crop extend
#' @import units
#' @keywords jasmin
#' @examples
#' \dontrun{
#' dtmc<-get_ukcp_dtm(aoi, ukcpdtm_file=orog_filepath)
#' }
get_ukcp_dtm<-function(aoi, ukcpdtm_file){
  if(!class(aoi)[1] %in% c("SpatRaster","SpatVector","sf") ) stop("aoi parameter is NOT a SpatRaster, SpatVector or sf object!!!")
  if(class(aoi)[1] =="sf") aoi<-terra::vect(aoi)

  # Load orography
  #fname<-"orog_land-rcm_uk_12km_osgb.nc"
  #path<-file.path(basepath,"badc/ukcp18/data/land-rcm/ancil/orog")
  dtmc<-terra::rast(ukcpdtm_file)
  #terra::crs(dtmc)<-'epsg:27700'

  # Convert aoi to dtmc projection and if a vector convert to bounding box vect
  aoiproj<-terra::project(aoi,terra::crs(dtmc))
  if(class(aoi)[1]=='SpatVector'){
    aoiproj<-terra::vect(terra::ext(aoiproj))
    terra::crs(aoiproj)<-terra::crs(dtmc)
  }
  # Crop dtmc to AOI then add a cell to all surrounds (if within original dtmc)
  dtmc_ext<-terra::crop(terra::extend(terra::crop(dtmc,aoiproj,snap='out'),1),dtmc)
  dtmc_out<-terra::crop(dtmc,dtmc_ext)
  units(dtmc)<-'m'
  names(dtmc)<-'Elevation'
  return(dtmc_out)
}

#' @title Calculate medium extent dtm (holding function)
#'
#' @param dtmc - coarse dtm spatraster of area of inputs
#' @param dtmuk - uk wide fine resolution dtm spatraster
#' @param coast_v - coastal terra vector of whole area covered by dmtuk
#'
#' @return spatraster object matching resolution of dtmuk and extent of dtmc
#' @export
#' @importFrom terra res mask crop aggregate
#' @keywords preprocess
#' @examples
#' \dontrun{
#' dtmm<-get_dtmm(dtmc,dtmuk)
#' }
get_dtmm<-function(dtmc,dtmuk,coast_v){
  #dtmm_res<-round(exp( ( log(terra::res(dtmc)[1]) + log(terra::res(dtmf)[1]) ) / 2 ))
  dtmm<-terra::mask(terra::crop(terra::crop(dtmuk, dtmc), dtmuk), coast_v)
  return(dtmm)
}

#' @title Source UKCP files from ceda archive and preprocess
#'
#' @param dtmc dtm at resolution of UKCP data (12km) covering area to be preprocessed, as returned by `get_ukcp_dtm`
#' @param startdate POSIXlt class defining start date of required timeseries
#' @param enddate POSIXlt class defining end date of required timeseries
#' @param collection text string defining UKCP18 collection, either 'land-gcm' or 'land-rcm'
#' @param domain text string defining UKCP18 domain, either 'uk' or 'eur'(land-rcm collection only) or 'global'
#' @param member string defining the climate model member to be used for the timeseries. Available members vary between UKCP18 collections.
#' @param basepath - "" for jasmin use
#' @param wsalbedo - white sky albedo value
#' @param bsalbedo - black sky albedo value
#' @param ukcp_vars UKCP18 variable names to be extracted DO NOT CHANGE
#' @param ukcp_units units of the UKCP18 variables extracted DO NOT CHANGE
#' @param output_units units required for output DO NOT CHANGE CHECK CORRECT
#' @param toArrays logical determining if climate data returned as list of arrays. If FALSE returns list of Spatrasts.
#' @param sampleplot if TRUE plots examples of interpolated dates when converting from 360 to 366 day years
#'
#' @return a list of the following:
#' \describe{
#'    \item{dtm}{Digital elevation of downscaled area in metres (as Spatraster)}
#'    \item{tme}{POSIXlt object of times corresponding to climate observations}
#'    \item{windheight_m}{Height of windspeed data in metres above ground (as numeric)}
#'    \item{tempheight_m}{Height of temperature data in metres above ground (as numeric)}
#'    \item{temp}{Temperature (deg C)}
#'    \item{relhum}{Relative humidity (Percentage)}
#'    \item{pres}{Sea-level atmospheric pressure (kPa)}
#'    \item{swrad}{Total downward shortwave radiation (W/m^2)}
#'    \item{difrad}{Downward diffuse radiation (W / m^2)}
#'    \item{lwrad}{Total downward longwave radiation (W/m^2)}
#'    \item{windspeed}{At `windheight_m` above ground` (m/s)}
#'    \item{winddir}{Wind direction (decimal degrees)}
#'    \item{prec}{Precipitation (mm)}
#'  }
#' @export
#' @import terra
#' @import units
#' @import mesoclim
#' @keywords jasmin
#' @seealso [ukcp18toclimarray()]
#' @examples
#' \dontrun{
#' climdata<-addtrees_climdata(aoi,ftr_sdate,ftr_edate,collection='land-rcm',domain='uk',member='01',basepath=ceda_basepath)
#' }
addtrees_climdata <- function(dtmc, startdate, enddate,
                              collection=c('land-gcm','land-rcm'),
                              domain=c('uk','eur','global'),
                              member=c('01','02','03','04','05','06','07','08','09','10','11','12','13','14','15',
                                       '16','17','18','19','20','21','22','23','24','25','26','27','28'),
                              basepath="",
                              wsalbedo=0.19, bsalbedo=0.22,
                              ukcp_vars=c('clt','hurs','pr','psl','rls','rss',
                                          'tasmax','tasmin','uas','vas'),
                              ukcp_units=c('%','%','mm/day','hPa','watt/m^2','watt/m^2',
                                           'degC','degC','m/s','m/s'),
                              output_units=c('%','%','mm/day','kPa','watt/m^2','watt/m^2',
                                             'degC','degC','m/s','m/s'),
                              temp_hgt=1.5, wind_hgt=10, # heights in UKCP data
                              toArrays=TRUE, sampleplot=FALSE){
  # Parameter check
  collection<-match.arg(collection)
  domain<-match.arg(domain)
  ukcp_vars<-match.arg(ukcp_vars,several.ok=TRUE)
  ukcp_units<-match.arg(ukcp_units,several.ok=TRUE)
  output_units<-match.arg(output_units,several.ok=TRUE)
  if(class(startdate)[1]!="POSIXlt" | class(enddate)[1]!="POSIXlt") stop("Date parameters NOT POSIXlt class!!")
  if(!class(dtmc)[1] %in% c("SpatRaster") ) stop("dtmc parameter is NOT a SpatRaster!!!")

  # Check dtmc in correct EPSG for UK rcm!!
  if(terra::crs(dtmc) !="EPSG:27700"){
    warning("Crs of dtmc parameter to addtrees_climdata if NOT EPSG:27700 - converting!!")
    dtmc<-project(dtmc,"EPSG:27700")
  }

  # Check member in chosen collection
  member<-match.arg(member)
  if(collection =='land-rcm' &
     !member %in% c('01','02','03','04','05','06','07','08','09','10','11','12','13','14','15')) stop(paste("Model member",member,"NOT available in land-rcm collection - ignoring!!"))

  # Add rcp and collection resolution
  rcp<-'rcp85'
  if(collection=='land-gcm') collres<-'60km' else collres<-'12km'

  # Identify which decades are required
  decades<-mesoclim::.find_ukcp_decade(collection,startdate,enddate)

  # Jasmin basepath
  basepath<-file.path(basepath,"badc","ukcp18","data",collection,domain,collres,rcp)

  # Function to restrict to dates requested
  filter_times<-function(x,startdate,enddate) x[[which(date(time(x)) >= startdate & date(time(x))  <= enddate)]]

  # Load spatrasters from ukcp.nc file, crop to dtmc, convert to normal calendar and add to output list
  clim_list<-list()
  for (n in 1:length(ukcp_vars)){
    v<-ukcp_vars[n]
    filepath<-file.path(basepath,member,v,'day','latest')
    ukcp_u<-ukcp_units[n]
    out_u<-output_units[n]
    var_r<-terra::rast()
    for (d in decades){
      filename<-paste0(v,'_rcp85_',collection,'_',domain,'_',collres,'_',member,'_day_', d,".nc")
      ncfile<-file.path(filepath, filename)
      message(paste("Loading",ncfile))

      # Load and crop data in native crs then project to dtmc crs and recrop
      r <- terra::rast(ncfile, subds=v)
      if(collection=="land-rcm" & domain=="uk") crs(r)<-"EPSG:27700"
      r<-terra::crop(r,dtmc)

      # If requested then convert to real calendar dates and fill missing dates
      ukcp_dates<-mesoclim::.get_ukcp18_dates(ncfile)
      real_dates<-mesoclim::.correct_ukcp_dates(ukcp_dates)
      r<-mesoclim::.fill_calendar_data(r, real_dates, testplot=sampleplot)

      # Correct units
      terra::units(r)<-ukcp_u

      # PROBLEM with u v wind vectors in global data - based on DIFFERENT grid to other variables!!!
      if(round(terra::ext(r),2)!=round(terra::ext(dtmc),2)){
        message("Extents of input data DIFFERENT - correcting!!")
        r<-terra::resample(r,dtmc)
      }
      # Join if multiple decades of data
      terra::add(var_r)<-r
    }
    # Filter times
    var_r<-filter_times(var_r,startdate,enddate)

    # Check & convert units, check all rasters geoms are same
    if(ukcp_u!=out_u) var_r<-mesoclim::.change_rast_units(var_r, out_u)
    if(!terra::compareGeom(dtmc,var_r)) warning(paste(v,"Spatrast NOT comparable to DTM!!") )
    clim_list[[v]]<-var_r
  }

  # Calculate derived variables: wind
  windspeed<-sqrt(as.array(clim_list$uas)^2+as.array(clim_list$vas)^2)
  windspeed<-mesoclim:::.windhgt(windspeed,zi=wind_hgt,zo=wind_hgt)
  clim_list$windspeed<-mesoclim:::.rast(windspeed,dtmc) # Wind speed (m/s)
  clim_list$winddir<-mesoclim:::.rast(as.array((terra::atan2(clim_list$uas,clim_list$vas)*180/pi+180)%%360),dtmc) # Wind direction (deg from N - from)
  units(clim_list$windspeed)<-'m/s'
  units(clim_list$winddir)<-'deg'
  terra::time(clim_list$windspeed)<-terra::time(clim_list$uas)
  terra::time(clim_list$winddir)<-terra::time(clim_list$uas)
  names(clim_list$windspeed)<-terra::time(clim_list$windspeed)
  names(clim_list$winddir)<-terra::time(clim_list$winddir)

  # Calculate derived variables: longwave downward
  tme<-as.POSIXlt(time(clim_list$tasmax),tz="UTC")
  tmean<-mesoclim:::.hourtoday(temp_dailytohourly(clim_list$tasmin, clim_list$tasmax, tme),mean)
  lwup<-terra::app(tmean, fun=mesoclim::.lwup)
  clim_list$lwdown<-clim_list$rls+lwup

  # Calculate derived variables: shortwave downward from white & black sky albedo as rast timeseries or fixed land and sea values
  clim_list$swdown<-mesoclim::.swdown(clim_list$rss, clim_list$clt, dtmc, wsalbedo, bsalbedo)

  # Select and rename climate output rasts MIGHT NEED TO CHANGE THESE TO MATCH THOSE USED BY MESOCLIM FUNCTIONS
  clim_list<-clim_list[c("clt","hurs","pr","psl","lwdown","swdown","tasmax","tasmin", "windspeed","winddir")]
  names(clim_list)<-c('cloud','relhum','prec','pres','lwrad','swrad','tmax','tmin','windspeed','winddir')

  ### Create output list
  output_list<-list()
  output_list$dtm<-dtmc
  output_list$tme<-as.POSIXlt(time(clim_list[[1]]),tz="UTC")
  output_list$windheight_m<-wind_hgt # ukcp windspeed at 10 metres height
  output_list$tempheight_m<-temp_hgt # ukcp air temp at 1.5 metres height

  # Convert climate data to arrays if required
  if(toArrays) clim_list<-lapply(clim_list,as.array)

  output_list<-c(output_list,clim_list)
  return(output_list)
}


#' @title Create UKCP sea surface temperature rast stack from ceda archive
#'
#' @param startdate start date as POSIXlt
#' @param enddate end date as POSIXlt
#' @param dtmc SpatRaster defining area of interest to crop data. NA no cropping occurs
#' @param members model members to be included
#' @param v = SST sea surface temperature
#' @param basepath - "" for jasmin use
#'
#' @return Spatraster timeseris of sea surface temperatures in original projection
#' @export
#' @import terra
#' @import lubridate
#' @keywords jasmin
#' @seealso [create_ukcpsst_data()]
#' @examples
#' \dontrun{
#' sstdata<-addtrees_sstdata(ftr_sdate,ftr_edate,aoi=climdata$dtm,member='01',basepath=ceda_basepath)
#' }
addtrees_sstdata<-function(
    startdate,
    enddate,
    dtmc,
    member=c('01','02','03','04','05','06','07','08','09','10','11','12','13','14','15') ,
    basepath="",
    v='SST' ){
  # Check parameters
  member<-match.arg(member)
  if(class(startdate)[1]!="POSIXlt" | class(enddate)[1]!="POSIXlt") stop("Date parameters NOT POSIXlt class!!")
  all_land<-FALSE

  # Derive months of data required - will output month before and after start and end dates for interpolation
  start<-startdate %m-% months(1)
  end<-enddate %m+% months(1)
  yrs<-unique(c(year(start):year(end)))

  # Get member ID used in file names from mesoclim lookup table
  # Ref: https://www.metoffice.gov.uk/binaries/content/assets/metofficegovuk/pdf/research/ukcp/ukcp18-guidance-data-availability-access-and-formats.pdf
  modelid<-ukcp18lookup$PP_ID[which(ukcp18lookup$Member_ID == member)]
  if("" %in% modelid) stop(paste("Model NOT available for sea surface temperature!!"))

  # Get filepaths and names of sst data required
  filepath<-file.path(basepath,'badc/deposited2023/marine-nwsclim/NWSPPE',modelid,'annual')
  ncfiles<-do.call(paste0, c(expand.grid('NWSClim_NWSPPE_',modelid,'_',yrs,'_gridT.nc') ))
  ncfiles<-file.path(filepath,ncfiles)
  not_present<-which(!file.exists(ncfiles))
  if (length(not_present)>0) stop(paste("Input .nc files required are NOT present: ",ncfiles[not_present]," ") )

  # Get spatrast stack
  var_r<-terra::rast()
  for(f in ncfiles){
    r<- rast(f, subds = v, drivers="NETCDF")
    if(!inherits(dtmc,"logical")) r<-mesoclim:::.sea_to_coast(sst.r=r,aoi.r=dtmc)
    units(r)<-'degC'
    # Join if multiple decades of data
    terra::add(var_r)<-r
  }
  # Select relevant months
  tme<-terra::time(var_r)
  var_r<-var_r[[which(terra::time(var_r) %within%  interval(start-month(1), end+month(1)) ) ]]
  names(var_r)<-terra::time(var_r)
  # If no valid sea temperatures (eg all land area) return NA
  if(all(is.na(values(var_r[[1]])))){
    message("No valid sea cells found in area requested!!")
    var_r<-NA
  }
  return(var_r)
}
