library(ggplot2)
library(rgdal)
library(rasterVis)
library(RColorBrewer)
library(raster)
library(sp)
library(maptools)
library(latticeExtra)
library(exactextractr)
path <- 'C:/Users/kc.7/OneDrive - The Ohio State University/Cover Crops/Data analysis/Third chapter/New_updated_analysis_manuscript_review/Yield_model_prediction/prediction/soybean_yield'
#plot(maumee)
setwd(path)
maumee <- readOGR('Maumee_WGS84_UTM17.shp')

all_rasters <- list.files(pattern = "*.tif$")

yield_2009 <- raster(all_rasters[1])
yield_2010 <- raster(all_rasters[2])
yield_2011 <- raster(all_rasters[3])
yield_2012 <- raster(all_rasters[4])
yield_2013 <- raster(all_rasters[5])
yield_2014 <- raster(all_rasters[6])
yield_2015 <- raster(all_rasters[7])
yield_2016 <- raster(all_rasters[8])
yield_2017 <- raster(all_rasters[9])
yield_2018 <- raster(all_rasters[10])
yield_2019 <- raster(all_rasters[11])

'''
#plotting average corn yield
average_corn_yield <- raster("average_corn_yield.tif")
plot(average_corn_yield, scales = list(draw = FALSE))
cols_ppt <- colorRampPalette(brewer.pal(4,"RdYlGn"))
p.strip <- list(cex=1.3, lines=1)
ckey <- list(labels = list(cex=1.3))

levelplot(average_corn_yield, margin = FALSE, col.regions = cols_ppt, par.strip.text=p.strip, colorkey = ckey, main = "Average corn yield (ton/ha) 2009 - 2019", scales = list(draw = FALSE)) + latticeExtra::layer(sp.polygons(maumee, col = "grey"))

'''

raster_stack <- stack(yield_2009, yield_2010, yield_2011, yield_2012, yield_2013, yield_2014, yield_2015, yield_2016, yield_2017, yield_2018, yield_2019)

#calc(raster_stack, fun = mean, filename = 'average_corn_yield.tif', na.rm = TRUE)


years <- list('Y2009', 'Y2010', 'Y2011', 'Y2012', 'Y2013', 'Y2014', 'Y2015', 'Y2016', 'Y2017', 'Y2018', 'Y2019')

names(raster_stack)<-years

cols <- colorRampPalette(brewer.pal(4,"RdYlGn"))

#cols <- colorRampPalette(brewer.pal(9, "YlGn"))

p.strip <- list(cex = 1.2, lines =1, col = "black")

levelplot(raster_stack, main = list("Soybean yield predicted (ton/ha)", cex=1.5), par.strip.text = p.strip, col.regions = cols, scales = list(draw=FALSE))

average_yield <- exact_extract(raster_stack, maumee, 'mean')

#cols_ppt <- colorRampPalette(brewer.pal(9,"Blues"))
cols_ppt <- colorRampPalette(brewer.pal(4,"RdYlGn"))

p.strip <- list(cex=1.3, lines=1)
ckey <- list(labels = list(cex=1.3))
#x.scale <- list(cex=1.2, alternating=1)
#y.scale <- list(cex=1.2, alternating=1)

#detach("package:ggplot2", unload=TRUE)

latticeExtra::layer(sp.polygons(maumee))

#levelplot(spring_stack, main = "Growing Degree Days in Spring (January to April)")
levelplot(raster_stack, main = "Corn yield predicted (ton/ha)", col.regions = cols_ppt, par.strip.text=p.strip, colorkey = ckey, scales = list(draw = FALSE)) + latticeExtra::layer(sp.polygons(maumee, col = "grey"))

