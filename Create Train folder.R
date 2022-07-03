# Script will import model 2 csv file and create the training directory

library(tidyverse)

dat.in<-read_csv("Model 2 labels.csv")

cats<-unique(dat.in$Model2)

cats<-cats[!is.na(cats)]


# all files
all.files<-list.files("/fastdata/test/",pattern="*.jpg",recursive=T)
all.files.long<-list.files("/fastdata/test/",pattern="*.jpg",recursive=T,full.names = T)

# Dest dir

for ( i in cats) {
        temp.images<-dat.in %>%
                filter(Model2 %in% i)
        
        dir.create(paste0("/fastdata/test/train/",i,"/"))
        
        loc<-match(temp.images$image,basename(all.files))
        for(j in 1:length(loc)){
        file.copy(from=all.files.long[loc[j]],
                  to=paste0("/fastdata/test/train/",i,"/"),recursive = T)
                
        }
}
