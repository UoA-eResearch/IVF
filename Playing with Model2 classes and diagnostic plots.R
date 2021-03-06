# time as group predictor

library(RMariaDB)
library(tidyverse)
library(lubridate)
library(data.table)
library(randomForest)
library(naivebayes)
library(ggforce)
library(ggdist)
library(gghalves)


con <- dbConnect(RMariaDB::MariaDB(), group = "IVF",
                 username = "root",
                 password = "embryo",
                 db = "IVF")
dbListTables(con)
# pdb.in<-dbReadTable(con,"PDB")
images.read<-dbReadTable(con,"image")

images.read <- images.read %>%
        filter(PDBid != 22295) # Bad label by me. Not sure how this got in. Bad copy?


model.fit<-randomForest(images.read[,c(2,8)],as.factor(images.read$Model2))
model.fit
varImpPlot(model.fit)

bayes.data<-images.read %>%
        filter(Model2 != "NA") %>%
        filter(Model2 != "Empty")

bayes.data$Model<-as.factor(bayes.data$Model2) %>% droplevels()
model.bayes<-naive_bayes(Model~time,usekernel = T,data=bayes.data)
plot(model.bayes)

predict<-predict(model.bayes,bayes.data)
tableone<-table(predict,bayes.data$Model)
tableone
acc<-1-sum(diag(tableone)) / sum(tableone)
acc

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
 
g<- images.read %>%
        mutate(Cats=factor(Model2, levels=c("Syngamy","2pn","2 Cell", "3 Cell", "4 Cell", "5 Cell", "6-7 Cell", "8 Cell", "9+ Cell", "Compacting", "Blast", "Empty","NA"),ordered=T)) %>%
        filter(Cats != "NA") %>%
        droplevels()

g2<- ggplot(aes(y=time,x=Cats,fill=Model2),data=g) + 
        ggdist::stat_halfeye(adjust = .5, width = .3, .width = 0, justification = -.3, point_colour = NA) + 
        geom_boxplot(width = .1, outlier.shape = NA)
        
g2

images.read$Model2<-test


field.types = c(
        image_id = "int unsigned",
        image = "varchar(255)",
        Label_D1 = "varchar(255)",
        Label_N2 = "varchar(255)",
        Label_S2 = "varchar(255)",
        Model2 = "varchar(255)",
        time = "int",
        PDBid = "int unsigned"
)

dbWriteTable(con,"image",images.read,overwrite=T,
             field.types=field.types,
             row.names=F)
dbExecute(con,"  ALTER TABLE image
                           ADD CONSTRAINT FK_PDBid
                           FOREIGN KEY (PDBid) REFERENCES PDB(PDBid)
                           on delete set null
                           on update set null;")
dbExecute(con," CREATE INDEX idx_image ON image (image)")
dbExecute(con, "ALTER TABLE image ADD PRIMARY KEY (image_id);")

write_csv(file="Model 2 labels.csv",images.read)


