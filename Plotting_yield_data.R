#program to plot observed vs predicted yield data
library(ggplot2)
library(readxl)
library(caret)
library(Metrics)

#path <- "C:/Users/kc.7/OneDrive - The Ohio State University/Cover Crops/Data analysis/Third chapter/New_updated_analysis_manuscript_review/validation_with_Matthew_data"
path <- "C:/Users/kc.7/OneDrive - The Ohio State University/Documents"
setwd(path)

corn_yield <- read.csv("SVM_corn.csv")
#corn_yield <- readxl::read_xlsx("corn_yield.xlsx")
#soybean_yield <- read.csv("MLR_soybean.csv")

#plot the data
ggplot(data = corn_yield, aes(x=Observed, y=Predicted)) + 
  geom_point(color = "goldenrod2")+#geom_smooth(method = lm, color = 'dark red') + 
  theme_bw() +
  xlim(9,14)+
  ylim(9,14)+
  theme(axis.text = element_text(size = 14), 
        axis.title = element_text(size =14),panel.grid.major = element_blank(), panel.grid.minor = element_blank()) +
  geom_abline(linetype = 2, color = "red3")+
  labs(x = "Observed yield (ton/ha)", y = "Predicted yield (ton/ha)")


mae_corn <- MAE(corn_yield$Predicted, corn_yield$Observed)
#mae_soybean <- MAE(soybean_yield$Predicted, soybean_yield$Observed)

#rmse_corn <- RMSE(corn_yield$Predicted, corn_yield$Observed)
rmse_corn <- RMSE(corn_yield$Observed, corn_yield$Predicted)
#rmse_soybean <- RMSE(soybean_yield$Predicted, soybean_yield$Observed)

R2_corn <- R2(corn_yield$Predicted, corn_yield$Observed)
#R2_soybean <- R2(soybean_yield$Predicted, soybean_yield$Observed)

