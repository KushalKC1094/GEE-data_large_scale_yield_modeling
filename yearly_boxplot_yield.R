library(dplyr)
library(raster)
library(rgdal)
library(ggplot2)
library(exactextractr)
library(tidyverse)

path <- "C:/Users/kc.7/OneDrive - The Ohio State University/Cover Crops/Data analysis/Third chapter/New_updated_analysis_manuscript_review/Yield_model_prediction/prediction/corn_yield"

setwd(path)

#read yield maps 
corn_yield_2009 <- raster("2009_corn_yield.tif")
corn_yield_2010 <- raster("2010_corn_yield.tif")
corn_yield_2011 <- raster("2011_corn_yield.tif")
corn_yield_2012 <- raster("2012_corn_yield.tif")
corn_yield_2013 <- raster("2013_corn_yield.tif")
corn_yield_2014 <- raster("2014_corn_yield.tif")
corn_yield_2015 <- raster("2015_corn_yield.tif")
corn_yield_2016 <- raster("2016_corn_yield.tif")
corn_yield_2017 <- raster("2017_corn_yield.tif")
corn_yield_2018 <- raster("2018_corn_yield.tif")
corn_yield_2019 <- raster("2019_corn_yield.tif")

#read cover crop maps
cc_2009 <- raster("2008_reclassified.tif")
cc_2010 <- raster("2009_reclassified.tif")
cc_2011 <- raster("2010_reclassified.tif")
cc_2012 <- raster("2011_reclassified.tif")
cc_2013 <- raster("2012_reclassified.tif")
cc_2014 <- raster("2013_reclassified.tif")
cc_2015 <- raster("2014_reclassified.tif")
cc_2016 <- raster("2015_reclassified.tif")
cc_2017 <- raster("2016_reclassified.tif")
cc_2018 <- raster("2017_reclassified.tif")
cc_2019 <- raster("2018_reclassified.tif")

#function to pivot
pivot_fun <- function(dat){
  data_pivoted <- pivot_longer(data = dat,
                               everything(),
                               names_to = c(".value","year"),
                               names_sep = "_",
                               values_to = "Year"
  )
}

#extract data
corn_stack_2009 <- stack(corn_yield_2009, cc_2009)
corn_2009 <- na.omit(as.data.frame(corn_stack_2009))
names(corn_2009) <- list("Corn_2009", "CC_2009")
corn_2009_data <- pivot_fun(corn_2009)
corn_2009_data_sample <- corn_2009_data %>% group_by(CC) %>% sample_n(50000)


corn_stack_2010 <- stack(corn_yield_2010, cc_2010)
corn_2010 <- na.omit(as.data.frame(corn_stack_2010))
names(corn_2010) <- list("Corn_2010", "CC_2010")
corn_2010_data <- pivot_fun(corn_2010)
corn_2010_data_sample <- corn_2010_data %>% group_by(CC) %>% sample_n(50000)

corn_stack_2011 <- stack(corn_yield_2011, cc_2011)
corn_2011 <- na.omit(as.data.frame(corn_stack_2011))
names(corn_2011) <- list("Corn_2011", "CC_2011")
corn_2011_data <- pivot_fun(corn_2011)
corn_2011_data_sample <- corn_2011_data %>% group_by(CC) %>% sample_n(50000)

corn_stack_2012 <- stack(corn_yield_2012, cc_2012)
corn_2012 <- na.omit(as.data.frame(corn_stack_2012))
names(corn_2012) <- list("Corn_2012", "CC_2012")
corn_2012_data <- pivot_fun(corn_2012)
corn_2012_data_sample <- corn_2012_data %>% group_by(CC) %>% sample_n(50000)

corn_stack_2013 <- stack(corn_yield_2013, cc_2013)
corn_2013 <- na.omit(as.data.frame(corn_stack_2013))
names(corn_2013) <- list("Corn_2013", "CC_2013")
corn_2013_data <- pivot_fun(corn_2013)
corn_2013_data_sample <- corn_2013_data %>% group_by(CC) %>% sample_n(50000)

corn_stack_2014 <- stack(corn_yield_2014, cc_2014)
corn_2014 <- na.omit(as.data.frame(corn_stack_2014))
names(corn_2014) <- list("Corn_2014", "CC_2014")
corn_2014_data <- pivot_fun(corn_2014)
corn_2014_data_sample <- corn_2014_data %>% group_by(CC) %>% sample_n(50000)

corn_stack_2015 <- stack(corn_yield_2015, cc_2015)
corn_2015 <- na.omit(as.data.frame(corn_stack_2015))
names(corn_2015) <- list("Corn_2015", "CC_2015")
corn_2015_data <- pivot_fun(corn_2015)
corn_2015_data_sample <- corn_2015_data %>% group_by(CC) %>% sample_n(50000)

corn_stack_2016 <- stack(corn_yield_2016, cc_2016)
corn_2016 <- na.omit(as.data.frame(corn_stack_2016))
names(corn_2016) <- list("Corn_2016", "CC_2016")
corn_2016_data <- pivot_fun(corn_2016)
corn_2016_data_sample <- corn_2016_data %>% group_by(CC) %>% sample_n(50000)

corn_stack_2017 <- stack(corn_yield_2017, cc_2017)
corn_2017 <- na.omit(as.data.frame(corn_stack_2017))
names(corn_2017) <- list("Corn_2017", "CC_2017")
corn_2017_data <- pivot_fun(corn_2017)
corn_2017_data_sample <- corn_2017_data %>% group_by(CC) %>% sample_n(50000)

corn_stack_2018 <- stack(corn_yield_2018, cc_2018)
corn_2018 <- na.omit(as.data.frame(corn_stack_2018))
names(corn_2018) <- list("Corn_2018", "CC_2018")
corn_2018_data <- pivot_fun(corn_2018)
corn_2018_data_sample <- corn_2018_data %>% group_by(CC) %>% sample_n(50000)

corn_stack_2019 <- stack(corn_yield_2019, cc_2019)
corn_2019 <- na.omit(as.data.frame(corn_stack_2019))
names(corn_2019) <- list("Corn_2019", "CC_2019")
corn_2019_data <- pivot_fun(corn_2019)
corn_2019_data_sample <- corn_2019_data %>% group_by(CC) %>% sample_n(50000)

all_data <- bind_rows(corn_2009_data_sample, corn_2010_data_sample, corn_2011_data_sample, corn_2012_data_sample, corn_2013_data_sample, corn_2014_data_sample, corn_2015_data_sample, corn_2016_data_sample, corn_2017_data_sample, corn_2018_data_sample, corn_2019_data_sample)
write.csv(all_data, "final_data_yield_cc.csv")


dat <- read.csv("final_data_yield_cc.csv")

dat_pivoted <- mutate(dat,
                       cover = case_when(
                         CC == 1 ~ 'cover',
                         CC == 0 ~ 'not covered'
                       ))

#yearly stat

dat1 <- na.omit(dat)

dat2 <- subset(dat1, dat1$year==2018)

t1 <- subset(dat2, dat2$CC==1)
t2 <- subset(dat2, dat2$CC==0)

mean(t1$Corn)
mean(t2$Corn)

#box plot
ggplot(data = dat_pivoted, aes(x = factor(year), y = Corn, fill = cover)) +
  stat_boxplot(geom = 'errorbar', width = 0.7) +
  geom_boxplot(outlier.shape = NA)+
  stat_summary(fun = mean, geom = "point", aes(group=cover), position = position_dodge(.9),shape = 21, size =3, color = "black", fill = "black")+
  labs(x = "Year", y = "Corn yield (mton/ha)")+
  scale_fill_manual(values = c("#1B9205", "#F43911"))+
  #scale_fill_discrete(name = "Cover Type")+
  theme_bw()+
  theme(axis.text = element_text(size = 21),
        axis.title = element_text(size = 21), panel.grid.major = element_blank(), panel.grid.minor = element_blank())+
  theme(legend.position = "top", legend.text = element_text(size = 21))



t <- subset(dat_pivoted, dat_pivoted$year==2009)
t <- na.omit(t)
t1 <- subset(t, t$CC==1)
t2 <- subset(t, t$CC==1)

mean(t1)
mean(t)

