library(rgeos)
library(raster)
library(rgdal)
library(gdalUtils)

setwd("D:/Google Drive/Data Incubator/Capstone")

# data file with y labels
acled <- read.csv("data/conflict/1900-01-01-2019-10-17-Pakistan.csv")

#Pakistan boundary
boundary <- readOGR("data/boundaries/PAK_adm0.shp")
buffer <- raster::buffer(x=boundary, width=0.001)


#### Raster stack for Pakistan for prediction


## population
pop <- raster("data/population/pak_ppp_2015.tif")
pop <- aggregate(pop, fact=1000, fun=sum)
pop <- crop(pop, extent(buffer))
pop <- mask(x=pop, mask=buffer)

## poverty
pov <- raster("data/poverty/pak07povmpi.tif") 
pov <- aggregate(pov, fact=100, fun=mean)
pov <- crop(pov, extent(buffer))
pov <- mask(x=pov, mask=buffer)
pov <- projectRaster(pov, pop)

## nightlights
lights <- raster("data/lights/F182013.v4c_web.stable_lights.avg_vis.tif")
lights <- crop(lights, extent(buffer))
lights <- mask(x=lights, mask=buffer)
lights <- aggregate(lights, fact=100, fun=mean)
lights <- projectRaster(lights, pop)

## temperature
quads <- list.files("data/temperature", pattern = "\\.tif$")
temp <- stack()
for (i in 1:length(quads)){
  r <- stack(paste0("data/temperature/",quads[i]))
  r <- crop(r, extent(buffer))
  r <- mask(x=r, mask=buffer)
  temp <- stack(temp,r)
}
temp <- stackApply(temp, indices =  rep(1,nlayers(temp)), fun = "mean", na.rm = T)
temp <- aggregate(temp, fact=100, fun=mean)
temp <- projectRaster(temp, pop)

## elevation
quads <- list.files("data/elevation", pattern = "\\.tif$")
# Read in a quad 
elev <- raster(paste0("data/elevation/",quads[1])) 
# Repeat for other quads 
for (i in 2:length(quads)){
  r <- raster(paste0("data/elevation/",quads[i]))
  elev <- merge(elev, r)
}

# Clip to national boundaries
elev <- aggregate(elev, fact=1000, fun=mean)
elev <- crop(elev, extent(buffer))
elev <- mask(x=elev, mask=buffer)
elev <- projectRaster(elev, pop)
elev[elev<0] <- 0

pak_stack <- stack(pop,pov,lights,temp,elev)
writeRaster(pak_stack, filename="data/pak_stack.tif", options="INTERLEAVE=BAND", overwrite=TRUE)

pak_df <- as.data.frame(pak_stack, xy=TRUE, row.names=NULL, optional=FALSE)
write.csv(pak_df, file="data/pak_df.csv")


#### conflict data process

xmin = extent(pop)[1]
ymin = extent(pop)[3]
res = res(pop)

acled$latitude = ymin + (floor((acled$latitude - ymin)/res[2]) * res[2]) + (res[2] / 2)
acled$longitude = xmin + (floor((acled$longitude - xmin)/res[1]) * res[1]) + (res[1] / 2)
write.csv(acled, file="data/conflict.csv")
