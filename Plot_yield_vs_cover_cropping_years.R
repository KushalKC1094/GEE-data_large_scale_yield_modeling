#code to plot yield against number of cover cropping years
#this also include codes to plot histogram of cover cropping by number of cover cropping years
library(raster)
library(ggplot2)
library(BAMMtools)
library(scales)
library(tidyverse)

#read path

path1 <- "C:/Users/kc.7/OneDrive - The Ohio State University/Cover Crops/Data analysis/Third chapter/New_updated_analysis_manuscript_review/"
#path1 <- "D:/Kushal_onedrive/OneDrive - The Ohio State University/Cover Crops/Data analysis/Third chapter/New_updated_analysis_manuscript_review/"
path2 <- "C:/Users/kc.7/OneDrive - The Ohio State University/Cover Crops/Data analysis/Third chapter/New_updated_analysis_manuscript_review/Yield_model_prediction/prediction/"
#path2 <- "D:/Kushal_onedrive/OneDrive - The Ohio State University/Cover Crops/Data analysis/Third chapter/New_updated_analysis_manuscript_review/Yield_model_prediction/prediction/"

#read the cover crop history maps for 2012, 2015, 2016, 2018 and 2019
cc_history_2012 <- raster(paste0(path1,"CC_history/CC_history_2012_updated_new.tif"))
cc_history_2012[cc_history_2012 >4] <- NA

cc_history_2015 <- raster(paste0(path1,"CC_history/CC_history_2015.tif"))
cc_history_2015[cc_history_2015 >7] <- NA

cc_history_2016 <- raster(paste0(path1,"CC_history/CC_history_2016_updated_new.tif"))
cc_history_2016[cc_history_2016 >8] <- NA

cc_history_2018 <- raster(paste0(path1,"CC_history/CC_history_2018.tif"))
cc_history_2018[cc_history_2018 >10] <- NA

cc_history_2019 <- raster(paste0(path1,"CC_history/CC_history_2019_updated_new.tif"))
cc_history_2019[cc_history_2019 >11] <- NA

#read yield maps for the three years: 2012, 2016 and 2019
corn_yield_2012 <- raster(paste0(path2, "corn_yield/","2012_corn_yield.tif"))
soybean_yield_2012 <- raster(paste0(path2, "soybean_yield/","2012_soybean_yield.tif"))

corn_yield_2015 <- raster(paste0(path2,"corn_yield/","2015_corn_yield.tif"))
soybean_yield_2015 <- raster(paste0(path2,"soybean_yield/","2015_soybean_yield.tif"))

corn_yield_2016 <- raster(paste0(path2,"corn_yield/","2016_corn_yield.tif"))
soybean_yield_2016 <- raster(paste0(path2,"soybean_yield/","2016_soybean_yield.tif"))

corn_yield_2018 <- raster(paste0(path2,"corn_yield/","2018_corn_yield.tif"))
soybean_yield_2018 <- raster(paste0(path2,"soybean_yield/","2018_soybean_yield.tif"))

corn_yield_2019 <- raster(paste0(path2,"corn_yield/","2019_corn_yield.tif"))
soybean_yield_2019 <- raster(paste0(path2,"soybean_yield/","2019_soybean_yield.tif"))

#making stack
cc_corn_2012 <- stack(cc_history_2012, corn_yield_2012)
cc_soybean_2012 <- stack(cc_history_2012, soybean_yield_2012)

cc_corn_2015 <- stack(cc_history_2015, corn_yield_2015)
cc_soybean_2015 <- stack(cc_history_2015, soybean_yield_2015)

cc_corn_2016 <- stack(cc_history_2016, corn_yield_2016)
cc_soybean_2016 <- stack(cc_history_2016, soybean_yield_2016)

cc_corn_2018 <- stack(cc_history_2018, corn_yield_2018)
cc_soybean_2018 <- stack(cc_history_2018, soybean_yield_2018)

cc_corn_2019 <- stack(cc_history_2019, corn_yield_2019)
cc_soybean_2019 <- stack(cc_history_2019, soybean_yield_2019)

#Extract data as dataframe corresponding to two rasters

data_cc_corn_2012 <- na.omit(as.data.frame(values(cc_corn_2012)))
data_cc_corn_2015 <- na.omit(as.data.frame(values(cc_corn_2015)))
data_cc_corn_2016 <- na.omit(as.data.frame(values(cc_corn_2016)))
data_cc_corn_2018 <- na.omit(as.data.frame(values(cc_corn_2018)))
data_cc_corn_2019 <- na.omit(as.data.frame(values(cc_corn_2019)))

data_cc_soybean_2012 <- na.omit(as.data.frame(values(cc_soybean_2012)))
data_cc_soybean_2015 <- na.omit(as.data.frame(values(cc_soybean_2015)))
data_cc_soybean_2016 <- na.omit(as.data.frame(values(cc_soybean_2016)))
data_cc_soybean_2018 <- na.omit(as.data.frame(values(cc_soybean_2018)))
data_cc_soybean_2019 <- na.omit(as.data.frame(values(cc_soybean_2019)))


rem_outlier <- function(dat){
  Q <- quantile(dat, probs = c(0.25, 0.75), na.rm = FALSE)
  iqr <- IQR(dat) #interquartile range
  up <- Q[2] + 1.5*iqr #upper bound
  low <- Q[1] - 1.5*iqr #lower bound
  bounds <- list(low, up)
}

#get rid of outliers
#corn_2012
bnds_2012_c <- rem_outlier(data_cc_corn_2012$X2012_corn_yield)
clean_data_cc_corn_2012 <- subset(data_cc_corn_2012, data_cc_corn_2012$X2012_corn_yield > bnds_2012_c[[1]] & data_cc_corn_2012$X2012_corn_yield < bnds_2012_c[[2]])

#corn_2015
bnds_2015_c <- rem_outlier(data_cc_corn_2015$X2015_corn_yield)
clean_data_cc_corn_2015 <- subset(data_cc_corn_2015, data_cc_corn_2015$X2015_corn_yield > bnds_2015_c[[1]] & data_cc_corn_2015$X2015_corn_yield < bnds_2015_c[[2]])

#corn_2016
bnds_2016_c <- rem_outlier(data_cc_corn_2016$X2016_corn_yield)
clean_data_cc_corn_2016 <- subset(data_cc_corn_2016, data_cc_corn_2016$X2016_corn_yield > bnds_2016_c[[1]] & data_cc_corn_2016$X2016_corn_yield < bnds_2016_c[[2]])

#corn_2018
bnds_2018_c <- rem_outlier(data_cc_corn_2018$X2018_corn_yield)
clean_data_cc_corn_2018 <- subset(data_cc_corn_2018, data_cc_corn_2018$X2018_corn_yield > bnds_2018_c[[1]] & data_cc_corn_2018$X2018_corn_yield < bnds_2018_c[[2]])


#corn_2019
bnds_2019_c <- rem_outlier(data_cc_corn_2019$X2019_corn_yield)
clean_data_cc_corn_2019 <- subset(data_cc_corn_2019, data_cc_corn_2019$X2019_corn_yield > bnds_2019_c[[1]] & data_cc_corn_2019$X2019_corn_yield < bnds_2019_c[[2]])

#soybean_2012
bnds_2012_s <- rem_outlier(data_cc_soybean_2012$X2012_soybean_yield)
clean_data_cc_soybean_2012 <- subset(data_cc_soybean_2012, data_cc_soybean_2012$X2012_soybean_yield > bnds_2012_s[[1]] & data_cc_soybean_2012$X2012_soybean_yield < bnds_2012_s[[2]])

#soybean_2015
bnds_2015_s <- rem_outlier(data_cc_soybean_2015$X2015_soybean_yield)
clean_data_cc_soybean_2015 <- subset(data_cc_soybean_2015, data_cc_soybean_2015$X2015_soybean_yield > bnds_2015_s[[1]] & data_cc_soybean_2015$X2015_soybean_yield < bnds_2015_s[[2]])


#soybean_2016
bnds_2016_c <- rem_outlier(data_cc_soybean_2016$X2016_soybean_yield)
clean_data_cc_soybean_2016 <- subset(data_cc_soybean_2016, data_cc_soybean_2016$X2016_soybean_yield > bnds_2016_c[[1]] & data_cc_soybean_2016$X2016_soybean_yield < bnds_2016_c[[2]])

#soybean_2018
bnds_2018_s <- rem_outlier(data_cc_soybean_2018$X2018_soybean_yield)
clean_data_cc_soybean_2018 <- subset(data_cc_soybean_2018, data_cc_soybean_2018$X2018_soybean_yield > bnds_2018_s[[1]] & data_cc_soybean_2018$X2018_soybean_yield < bnds_2018_s[[2]])


#soybean_2019
bnds_2019_c <- rem_outlier(data_cc_soybean_2019$X2019_soybean_yield)
clean_data_cc_soybean_2019 <- subset(data_cc_soybean_2019, data_cc_soybean_2019$X2019_soybean_yield > bnds_2019_c[[1]] & data_cc_soybean_2019$X2019_soybean_yield < bnds_2019_c[[2]])

#get statistics by cover cropping year
first <- subset(clean_data_cc_corn_2019, clean_data_cc_corn_2019$CC_history_2019_updated_new>4)
#last <- subset(clean_data_cc_corn_2015, clean_data_cc_corn_2012$CC_history_2015_updated_new==4)
summary(first)
#summary(last)

first_soybean <- subset(clean_data_cc_soybean_2019, clean_data_cc_soybean_2019$CC_history_2019_updated_new>4)
summary(first_soybean)

#modify the 2019 data only to include 6 classes
#first convert ton/ha to bushel/acre
#clean_data_cc_corn_2012 <- mutate(clean_data_cc_corn_2019, corn_yield2019_bushel_acre = X2019_corn_yield *14.28)

#clean_data_cc_soybean_2012 <- mutate(clean_data_cc_soybean_2019, soybean_yield2019_bushel_acre = X2019_soybean_yield *14.28)

#clean_data_cc_corn_2019 <- mutate(clean_data_cc_corn_2019,
 #                     frequency = case_when(
  #                      CC_history_2019_updated_new  > 4 ~ '>4',
   #                     CC_history_2019_updated_new  ==0 ~ '0',
    #                    CC_history_2019_updated_new  ==1 ~ '1',
     #                   CC_history_2019_updated_new  ==2 ~ '2',
      #                  CC_history_2019_updated_new  ==3 ~ '3',
       #                 CC_history_2019_updated_new  ==4 ~ '4'
        #                
         #             ))



#clean_data_cc_corn_2019$frequency <- factor(clean_data_cc_corn_2019$frequency, levels = c("0", "1", "2", "3","4",">4"))

#clean_data_cc_soybean_2019 <- mutate(clean_data_cc_soybean_2019,
 #                           frequency = case_when(
  #                            CC_history_2019_updated_new  > 4 ~ '>4',
   #                           CC_history_2019_updated_new  ==0 ~ '0',
    #                          CC_history_2019_updated_new  ==1 ~ '1',
     #                         CC_history_2019_updated_new  ==2 ~ '2',
      #                        CC_history_2019_updated_new  ==3 ~ '3',
       #                       CC_history_2019_updated_new  ==4 ~ '4'
        #                      
         #                   ))

#clean_data_cc_soybean_2019$frequency <- factor(clean_data_cc_soybean_2019$frequency, levels = c("0", "1", "2", "3","4",">4"))

#randomly sample 50000 pixels
clean_data_cc_corn_2012_sample <- clean_data_cc_corn_2012 %>% group_by(CC_history_2012_updated_new) %>% sample_n(10000)
clean_data_cc_soybean_2012_sample <- clean_data_cc_soybean_2012 %>% group_by(CC_history_2012_updated_new) %>% sample_n(10000)


clean_data_cc_corn_2015_sample <- clean_data_cc_corn_2015 %>% group_by(CC_history_2015) %>% sample_n(10000)
clean_data_cc_soybean_2015_sample <- clean_data_cc_soybean_2015 %>% group_by(CC_history_2015) %>% sample_n(10000)

clean_data_cc_corn_2016_sample <- clean_data_cc_corn_2016 %>% group_by(CC_history_2016_updated_new) %>% sample_n(10000)
clean_data_cc_soybean_2016_sample <- clean_data_cc_soybean_2016 %>% group_by(CC_history_2016_updated_new) %>% sample_n(10000)

clean_data_cc_corn_2018_sample <- clean_data_cc_corn_2018 %>% group_by(CC_history_2018) %>% sample_n(10000)
clean_data_cc_soybean_2018_sample <- clean_data_cc_soybean_2018 %>% group_by(CC_history_2018) %>% sample_n(10000)

clean_data_cc_corn_2019_sample <- clean_data_cc_corn_2019 %>% group_by(CC_history_2019_updated_new) %>% sample_n(10000)
clean_data_cc_soybean_2019_sample <- clean_data_cc_soybean_2019 %>% group_by(CC_history_2019_updated_new) %>% sample_n(10000)


#statistics
first <- subset(clean_data_cc_soybean_2012, clean_data_cc_soybean_2012$CC_history_2012_updated_new==0)
mean(first$X2012_soybean_yield)

second <- subset(clean_data_cc_soybean_2012, clean_data_cc_soybean_2012$CC_history_2012_updated_new==4)
mean(second$X2012_soybean_yield)
  
_updated_new

#plotting yield vs number of cover cropping years
ggplot(data = clean_data_cc_corn_2019_sample,aes(x = factor(CC_history_2019_updated_new), y = clean_data_cc_corn_2019_sample$X2019_corn_yield)) + 
  geom_boxplot(outlier.shape = NA)+
  stat_boxplot(geom='errorbar', width = 0.8)+
  stat_summary(fun = mean, geom = "point", position = position_dodge(.9), shape = 21, size = 3, color = "black", fill = "black")+
  theme_bw()+
 scale_y_continuous(limits = c(0,20))+
  labs(title = "corn yield in 2019 growing season", y = "Corn yield (ton/ha)", x = "Number of cover cropping years")+
  theme(axis.text = element_text(size=25),
        axis.title = element_text(size = 25))

  
#_updated_new

#corn
ggplot(data = clean_data_cc_soybean_2019_sample, mapping = aes(x = factor(CC_history_2019_updated_new), y = clean_data_cc_soybean_2019_sample$X2019_soybean_yield))+ 
  stat_boxplot(geom='errorbar', width = 0.8)+

  geom_boxplot(outlier.shape = NA)+
  stat_summary(fun = mean, geom = "point", position = position_dodge(.9), shape = 21, size = 3, color = "black", fill = "black")+
  #ylim(0,20)+
  theme_bw()+
  scale_y_continuous(limits = c(2,5))+
  labs( y = "Soybean yield (ton/ha)", x = "Number of cover cropping years")+
  theme(axis.text = element_text(size=25),
        axis.title = element_text(size = 25))

#CC_history_2015_updated_new

#Histogram corn
ggplot(data = clean_data_cc_corn_2015_sample, mapping = aes(x=CC_history_2015))+
geom_bar() + theme_bw()+
scale_y_continuous(labels=label_number(suffix="M", scale=1e-6),
                   sec.axis = sec_axis(~.*0.22, name = "Area (acres)", labels=label_number(suffix="K", scale=1e-3)))+
labs(title = "Total number of pixels: soybean 2015", x = "Number of cover croping years", y = "Frequency")+
  theme(axis.text = element_text(size=16),
        axis.title = element_text(size = 16))



#Histogram soybean
ggplot(data = clean_data_cc_soybean_2018, mapping = aes(x=CC_history_2018))+
  geom_bar() + theme_bw()+
  scale_y_continuous(labels=label_number(suffix="M", scale=1e-6))+
  labs(title = "Total number of pixels: Soybean 2018", x = "Number of cover croping years", y = "Frequency")+
  theme(axis.text = element_text(size=16),
        axis.title = element_text(size = 16))

#Jenks natural break for yield data
#getJenksBreaks(data_cc_corn_2012$X2012_corn_yield_updated, 3)



#plotting two axes: one yield and other histogram at single graph
#in ggplot there is no direct plotting such as dual axes. One axis is basically the transformation of other. 
#So, we need to transform the second variable using first variable and change the labels accordingly


g <- ggplot(data = clean_data_cc_corn_2015) + 
  geom_boxplot(aes(x = factor(CC_history_2015), y = X2015_corn_yield),outlier.shape = NA)+
  stat_boxplot(aes(x = factor(CC_history_2015), y = X2015_corn_yield),geom='errorbar', width = 0.8)+
  stat_summary(aes(x = factor(CC_history_2015), y = X2015_corn_yield),fun = mean, geom = "point", position = position_dodge(.9), shape = 21, size = 3, color = "black", fill = "black")+
  scale_y_continuous(
    sec.axis = dup_axis(~.*100000000)
  )+
  theme_bw()+
  labs(title = "Corn yield in 2015 growing season", x = "Number of cover cropping years")+
  theme(axis.text = element_text(size=18),
        axis.title = element_text(size = 18))

g + geom_bar(aes(x = CC_history_2015))
  

#looking at the data with 11 years of cover cropping history
cc_11_years <- subset(clean_data_cc_corn_2019, clean_data_cc_corn_2019$CC_history_2019_updated_new == 11)


