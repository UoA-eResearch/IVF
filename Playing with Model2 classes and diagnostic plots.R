# time as group predictor

library(RMariaDB)
library(tidyverse)
library(lubridate)
library(data.table)
library(randomForest)


con <- dbConnect(RMariaDB::MariaDB(), group = "IVF",
                 username = "root",
                 password = "embryo",
                 db = "IVF")
dbListTables(con)

images.read<-dbReadTable(con,"image")


model.fit<-randomForest(images.read[,c(2,8)],as.factor(images.read$Model2))
model.fit
varImpPlot(model.fit)

model.fit2<-glm(as.factor(images.read$Model2)~images.read$time,family=binomial)

boxplot(images.read$time~images.read$Model2)

images.read$Model2

tmp<-images.read$Label_D1

for ( i in 1:length(tmp)){
        if(!is.na(images.read$Label_S2[i]) & images.read$Label_S2[i] != "NA")  tmp[i]<-images.read$Label_S2[i]
        if(!is.na(images.read$Label_N2[i]) & images.read$Label_N2[i] != "NA")  tmp[i]<-images.read$Label_N2[i]
        if(!is.na(images.read$Label_D1[i]) & images.read$Label_D1[i] != "NA")  tmp[i]<-images.read$Label_D1[i]
        }
        
table(tmp)
 boxplot(images.read$time~ tmp)
 

 
 
 # Mapping values
 
 all.values<-c(images.read$Label_D1,images.read$Label_N2,images.read$Label_S2)
 unique(all.values)
 
 label.key <- c( "1 Cell-No_PN" = "Syngamy",
                 "1 Cell-Post_Syngamy" = "Syngamy",
                 "2 Cell" = "2 Cell",
                 "2pn" = "2pn",
                 "3 Cell" = "3 Cell",
                 "4 Cell" = "4 Cell",
                 "5 Cell" = "5 Cell",
                 "6-7Cell" = "6-7 Cell",
                 "8 Cell" = "8 Cell",
                 "9 Cell+" = "9+ Cell",
                 "Abnormal_Fert" = "NA",
                 "arrested" = "NA",
                 "bad" = "NA",
                 "Blast-1" = "Blast",
                 "Blast-2" = "Blast",
                 "Blast-3" = "Blast",
                 "Blast-4" = "Blast",
                 "Blast-5" = "Blast",
                 "Blast-6" = "Blast",
                 "Compacting" = "Compacting",
                 "degenerated" = "NA",
                 "Empty" = "Empty",
                 "unclear" = "NA",
                 "6 Cell" = "6-7 Cell",
                 "Compacting 8 cell" = "Compacting",
                 "Morula" = "Compacting",
                 "Cavitating morula" = "Compacting",
                 "Early blast" = "Blast",
                 "Blastocyst" = "Blast",
                 "Expanded Blastocyst" = "Blast",
                 "Hatching" = "Blast"
         )

test<-tmp %>%
        recode_factor(!!!label.key)

boxplot(images.read$time~ test)
 
images.read$Model2<-test
