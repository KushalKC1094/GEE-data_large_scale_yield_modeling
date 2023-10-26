#load packages
library(raster)
library(sp)
library(caret)
library(e1071)
library(randomForest)
library(crossval)
library(xgboost)
library(splitTools)
library(MLmetrics)

#set working directory
path <- 'C:/Users/kc.7/OneDrive - The Ohio State University/Cover Crops/Data analysis/Third chapter/New_updated_analysis_manuscript_review/Yield_model_prediction/model'
setwd(path)


#load the data
mydata_corn <- read.csv('regression_in_R_corn.csv')

#split data into training and testing data
set.seed(123)

validation_index <- createDataPartition(mydata_corn$Value_ton_ha, p = 0.8, list = F)

#select 20% for validation
test_data_c <- mydata_corn[-validation_index,]

#remaining 80% of the data for training the model
train_data_c <- mydata_corn[validation_index,]

formula <- Value_ton_ha~mean.NDVI+mean.EVI2+mean_aug_temp+mean_aug_ppt

#At first comparison of models based on their performance in 10-fold cross validation

#10-fold cross validation on the training data using linear regression
model1_corn <- train(formula, train_data_c,
                method = "lm")
                #trControl = trainControl(method = "cv",
                #                         number = 10,
                  #                       verboseIter = F))



#for soybean
mydata_soybean <- read.csv('regression_in_R_soybean.csv')
#split data into training and testing data
validation_index2 <- createDataPartition(mydata_soybean$Value_ton_ha, p = 0.8, list = F)

#select 20% for validation
test_data_s <- mydata_soybean[-validation_index2,]

#remaining 80% of the data for training the model
train_data_s <- mydata_soybean[validation_index2,]

#10-fold cross validation on the training data using linear regression
model1_soybean <- train(formula, train_data_s,
                     method = "lm")
                     #trControl = trainControl(method = "cv",
                      #                        number = 10,
                       #                       verboseIter = F))




saveRDS(model1_corn, 'corn_final_model.rds')
saveRDS(model1_soybean, 'soybean_final_model.rds')

#best model: linear regression

'''
'''
#10-fold cross validation of random forest
#first we need to tune and find optimal parameters
'''
model2_rf1_corn <- train(Value ~ mean.NDVI + mean.EVI2 + mean_aug_temp + mean_aug_ppt,
                data = train_data_c,
                method = "rf",
                tuneGrid = data.frame(mtry = c(2:10)), #tuning mtry
                trControl = trainControl(method = "cv",
                                         number = 10,
                                         search = "grid"))
best_mtry <- model2_rf1_corn$bestTune$mtry

tuneGrid = expand.grid(.mtry = best_mtry)

#tuning best maxnodes
store_maxnode <- list()
for (maxnodes in c(5:15)){
  set.seed(123)
  rf_maxnode <- train(Value ~ mean.NDVI + mean.EVI2 + mean_aug_temp + mean_aug_ppt,
                      data = train_data_s,
                      method = "rf",
                      tuneGrid = tuneGrid,
                      trControl = trainControl(method = "cv",
                                               number = 10,
                                               search = "grid"),
                      maxnodes = maxnodes,
                      ntree = 300)
  current_iteration <- toString(maxnodes)
  store_maxnode[[current_iteration]] <- rf_maxnode
}

results_mtry <- resamples(store_maxnode)
summary(results_mtry)

#tuning ntree
store_maxtrees <- list()
for (ntree in c(200,300,400,500, 600,700,800)){
  #set.seed(132)
  rf_maxtrees <- train(Value ~ mean.NDVI + mean.EVI2 + mean_aug_temp + mean_aug_ppt,
                      data = train_data_s,
                      method = "rf",
                      tuneGrid = tuneGrid,
                      trControl = trainControl(method = "cv",
                                               number = 10,
                                               search = "grid"),
                      maxnodes = 15,
                      ntree = ntree)
  key <- toString(ntree)
  store_maxtrees[[key]] <- rf_maxtrees
}
results_ntree <- resamples(store_maxtrees)
summary(results_ntree)
'''

#best rf model for corn parameters: maxnode=14; ntree=800, mtry = 2
#best rf model for soybean parameters: maxnode=14; ntree=300, mtry = 6

#train 10-fold rf for corn
model2_rf1_corn <- train(formula,
                         data = train_data_c,
                         method = "rf",
                         tuneGrid = data.frame(mtry = 2), #tuning mtry,
                         ntree = 800,
                         maxnodes = 14,
                         trControl = trainControl(method = "cv",
                                                  number = 10,
                                                  search = "grid"))


model2_rf1_soybean <- train(formula,
                         data = train_data_s,
                         method = "rf",
                         tuneGrid = data.frame(mtry = 6), #tuning mtry,
                         ntree = 300,
                         maxnodes = 14,
                         trControl = trainControl(method = "cv",
                                                  number = 10,
                                                  search = "grid"))


##10-fold cross validation on the training data using linear regression
model3_svm_corn <- train(formula,
                   data = train_data_c,
                   method = "svmRadial",
                   preProcess = c("center", "scale"),
                   trControl = trainControl(method = "cv",
                                            number = 10))

model3_svm_soybean <- train(formula,
                        data = train_data_s,
                        method = "svmRadial",
                        preProcess = c("center", "scale"),
                        trControl = trainControl(method = "cv",
                                                 number = 10))

#Result of 10-fold cross validation: Linear Regression performs better than RF and SVM


#test with independent validation dataset and evaluate accuracy metrics
pred_corn <- predict(model1_corn, test_data_c)
pred_soybean <- predict(model1_soybean, test_data_s)

#for corn model
data.frame(R2 = R2(pred_corn, test_data_c$Value_ton_ha),
           RMSE = RMSE(pred_corn, test_data_c$Value_ton_ha),
           MAE = MAE(pred_corn, test_data_c$Value_ton_ha))

plot_data_c <- data.frame(predicted = pred_corn, observed = test_data_c$Value_ton_ha)
plot_data_s <- data.frame(predicted = pred_soybean, observed = test_data_s$Value_ton_ha)

#plot observed vs predicted data
ggplot(data = plot_data_c, aes(x=observed, y=predicted)) + 
  geom_point(color = "chartreuse4")+geom_smooth(method = lm, color = 'dark red') + 
  theme_bw() +
  xlim(8,14)+
  ylim(8,14)+
  theme(axis.text = element_text(size = 14), 
        axis.title = element_text(size =14),panel.grid.major = element_blank(), panel.grid.minor = element_blank()) +
  labs(x = "Observed yield (ton/ha)", y = "Predicted yield (ton/ha)")


#for soybean model
data.frame(R2 = R2(pred_soybean, test_data_s$Value_ton_ha),
           RMSE = RMSE(pred_soybean, test_data_s$Value_ton_ha),
           MAE = MAE(pred_soybean, test_data_s$Value_ton_ha))

# for corn xgboost tuned parameters: max_depth:1, colsample:0.8, subsample:1, nrounds:100 with Rsq:0.70, RMSE:13.9, MAE:12.31
# for soybean nrounds = 50, max_depth = 3, eta = 0.3, gamma = 0, colsample_bytree = 0.8, min_child_weight = 1 and subsample = 0.5.
'''

#load existing model
model1_corn <- readRDS("Corn_final_model.rds")
model2_soybean <- readRDS("Soybean_final_model.rds")

'''



#read the NDVI and EVI index data
NDVI1 <- raster('corn_meanNDVIEVI_2019.tif', band=1)
EVI1 <- raster('corn_meanNDVIEVI_2019.tif', band=2)

NDVI2 <- raster('soybean_meanNDVIEVI_2019.tif', band=1)
EVI2 <- raster('soybean_meanNDVIEVI_2019.tif', band=2)

#read weather data
ppt <- raster('2019_ppt_aug.tif')
temp <- raster('2019_temp_aug.tif')

#matching resolution and extent
ppt_resampled <-resample(ppt, NDVI1)
temp_resampled <-resample(temp, NDVI1)


#crop ton only include corn/corn fields
ppt_cropped1 <- mask(ppt_resampled, NDVI1)
temp_cropped1 <- mask(temp_resampled, NDVI1)

#crop ton only include corn/corn fields
ppt_cropped2 <- mask(ppt_resampled, NDVI2)
temp_cropped2 <- mask(temp_resampled, NDVI2)

stacked_layers1 <-stack(NDVI1, EVI1,temp_cropped1, ppt_cropped1)
stacked_layers2 <-stack(NDVI2, EVI2,temp_cropped2, ppt_cropped2)

names(stacked_layers1)[1] <-"mean.NDVI"
names(stacked_layers1)[2] <-"mean.EVI2"
names(stacked_layers1)[3] <-"mean_aug_temp"
names(stacked_layers1)[4] <-"mean_aug_ppt"

names(stacked_layers2)[1] <-"mean.NDVI"
names(stacked_layers2)[2] <-"mean.EVI2"
names(stacked_layers2)[3] <-"mean_aug_temp"
names(stacked_layers2)[4] <-"mean_aug_ppt"

predicted_corn <- predict(stacked_layers1, model1_corn)
predicted_soybean <- predict(stacked_layers2, model1_soybean)

filter_pred1 <- predicted_corn
filter_pred2 <- predicted_soybean

filter_pred1[predicted_corn<=0]<-0
filter_pred2[predicted_soybean <=0]<-0

#plot(filter_pred, main="2019 corn yield")
location <-  "C:/Users/kc.7/OneDrive - The Ohio State University/Cover Crops/Data analysis/Third chapter/New_updated_analysis_manuscript_review/Yield_model_prediction/prediction"
writeRaster(filter_pred1, filename = file.path(location,"2019_corn_yield.tif"))
writeRaster(filter_pred2, filename = file.path(location,"2019_soybean_yield.tif"))


saveRDS(model2_rf1_corn, 'corn_rf_model.rds')
saveRDS(model2_rf1_soybean, 'soybean_rf_model.rds')


saveRDS(model3_svm_corn, 'corn_svm_model.rds')
saveRDS(model3_svm_soybean, 'soybean_svm_model.rds')



#For Corn
model_train_lr_corn <- train(formula, train_data_c,
                     method = "lm")

model_train_rf_corn <- train(formula,
                         data = train_data_c,
                         method = "rf",
                         tuneGrid = data.frame(mtry = 2), #tuning mtry,
                         ntree = 800,
                         maxnodes = 14)

model3_train_svm_corn <- train(formula,
                         data = train_data_c,
                         method = "svmRadial",
                         preProcess = c("center", "scale"))

#check accuracy
#test with independent validation dataset and evaluate accuracy metrics
pred_corn <- predict(model3_train_svm_corn, test_data_c)

#for corn model
data.frame(R2 = R2(pred_corn, test_data_c$Value_ton_ha),
           RMSE = RMSE(pred_corn, test_data_c$Value_ton_ha),
           MAE = MAE(pred_corn, test_data_c$Value_ton_ha))
          # MAPE = MAPE(pred_corn, test_data_c$Value_ton_ha))


#For Soybean
model_train_lr_soybean <- train(formula, train_data_s,
                        method = "lm")

model_train_rf_soybean <- train(formula,
                            data = train_data_s,
                            method = "rf",
                            tuneGrid = data.frame(mtry = 6), #tuning mtry,
                            ntree = 300,
                            maxnodes = 14)

model_train_svm_soybean <- train(formula,
                            data = train_data_s,
                            method = "svmRadial",
                            preProcess = c("center", "scale"),
                            trControl = trainControl(method = "cv",
                                                     number = 10))

#check accuracy
#test with independent validation dataset and evaluate accuracy metrics
pred_soybean <- predict(model_train_lr_soybean, test_data_s)

#for soybean model
data.frame(R2 = R2(pred_soybean, test_data_s$Value_ton_ha),
           RMSE = RMSE(pred_soybean, test_data_s$Value_ton_ha),
           MAE = MAE(pred_soybean, test_data_s$Value_ton_ha),
           MAPE = MAPE(pred_soybean, test_data_s$Value_ton_ha))




plot_data_c <- data.frame(predicted = pred_corn, observed = test_data_c$Value_ton_ha)



#plot observed vs predicted data
ggplot(data = plot_data_c, aes(observed, y=predicted)) + 
  geom_point(color = "chartreuse4")+#geom_smooth(method = lm, color = 'dark red') + 
  theme_bw() +
  xlim(8,14)+
  ylim(8,14)+
  theme(axis.text = element_text(size = 14), 
        axis.title = element_text(size =14),panel.grid.major = element_blank(), panel.grid.minor = element_blank()) +
  labs(x = "Observed yield (ton/ha)", y = "Predicted yield (ton/ha)")+
  geom_abline(linetype = 2, color = "red3")






plot_data_s <- data.frame(predicted = pred_soybean, observed = test_data_s$Value_ton_ha)



#plot observed vs predicted data
ggplot(data = plot_data_s, aes(observed, y=predicted)) + 
  geom_point(color = "chartreuse4")+#geom_smooth(method = lm, color = 'dark red') + 
  theme_bw() +
 # xlim(8,14)+
  #ylim(8,14)+
  theme(axis.text = element_text(size = 14), 
        axis.title = element_text(size =14),panel.grid.major = element_blank(), panel.grid.minor = element_blank()) +
  labs(x = "Observed yield (ton/ha)", y = "Predicted yield (ton/ha)")+
  xlim(2,4.5)+
  ylim(2,4)+
  geom_abline(linetype = 2, color = "red3")


#function to calculate coefficient of determination
COD <- function(obs, pred){
  ss_t = 0
  ss_r = 0
  
  val_count = length(obs)
  for ( i in 1:val_count){
    ss_t = ss_t + (obs[[i]]-mean(pred))**2
    ss_r = ss_r + (pred[[i]]-obs[[i]])**2
    r2 = 1 - (ss_r/ss_t)
  }
  return(r2)
}

COD(test_data_s$Value_ton_ha,pred_soybean)

#save trained models
saveRDS(model_train_lr_corn, 'corn_mlr_model1.rds')
saveRDS(model_train_rf_corn, 'corn_rf_model2.rds')
saveRDS(model3_train_svm_corn, 'corn_svm_model3.rds')


saveRDS(model_train_lr_soybean, 'soybean_mlr_model1.rds')
saveRDS(model_train_rf_soybean, 'soybean_rf_model2.rds')
saveRDS(model_train_svm_soybean, 'soybean_svm_model3.rds')



#plot observed vs predicted data
ggplot(data = mydata_corn, aes(x=mydata_corn$mean_aug_temp, y=mydata_corn$Value_ton_ha)) + 
  geom_point(color = "chartreuse4", size = 3)+
  geom_smooth(method = lm, color = 'dark red') + 
  theme_bw() +
  # xlim(8,14)+
  #ylim(8,14)+
  theme(axis.text = element_text(size = 22), 
        axis.title = element_text(size =22),panel.grid.major = element_blank(), panel.grid.minor = element_blank()) +
  labs(x = "Mean temperature (Degree Celsius)", y = "Yield (ton/ha)")
  #xlim(2,4.5)+
  #ylim(2,4)
  #geom_abline(linetype = 2, color = "red3")



#check correlation or correlation test
cor.test(mydata_corn$mean_aug_temp, mydata_corn$Value_ton_ha, method = "pearson")





