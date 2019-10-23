library(rgeos)
library(raster)
library(rgdal)
library(RColorBrewer)

setwd("D:/Google Drive/Data Incubator/Capstone")

pred <- read.csv("data/predictions.csv", header = TRUE)

stack <- raster("data/pak_stack.tif")

#pakistan boundary
boundary <- readOGR("data/boundaries/PAK_adm0.shp")
buffer <- raster::buffer(x=boundary, width=0.2)

x <- raster(extent(boundary), res = res(stack), crs="+proj=longlat +datum=WGS84 +no_defs +ellps=WGS84 +towgs84=0,0,0")

predicted_raster <- rasterize(pred[, c('longitude','latitude')], x, pred[, 'pred'])
predicted_raster <- mask(x=predicted_raster, mask=buffer)

actual_raster <- rasterize(pred[, c('longitude','latitude')], x, pred[, 'actual'])
actual_raster <- mask(x=actual_raster, mask=buffer)

cols <- brewer.pal(5, "Reds")

par(mfrow=c(1,2))

plot(actual_raster,axes = F,box = F,main="True", legend = F, col = cols)
plot(boundary, add=T)
plot(predicted_raster,axes = F,box = F,main="Predicted", col = cols)
plot(boundary, add=T)
