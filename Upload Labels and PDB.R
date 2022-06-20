# Script will connect to IVF Database and update the tables

library(RMariaDB)
library(tidyverse)
library(lubridate)
library(data.table)

con <- dbConnect(RMariaDB::MariaDB(), group = "IVF",
                 username = "root",
                 password = "embryo",
                 db = "IVF")
dbListTables(con)
pdb.up=F
if(pdb.up==T) {
        # read in pdb data
        dat.in <- read_csv(file = "PDB_database_summary.csv")
        
        a <- strsplit(dat.in$FileName, "_")
        b <- sapply(a, "[[", 1)
        c <- strsplit(b, "D")
        d <- sapply(c, "[[", 2)
        pdb.date <- as_date(d)
        
        dat.in$Date <- pdb.date # Add date into main data table
        
        dbExecute(
                con,
                "INSERT INTO PDB(pdb,Machine,Slide,Well,Date) VALUES (?,?,?,?,?)",
                params = list(
                        dat.in$FileName,
                        dat.in$Machine,
                        dat.in$Slide,
                        dat.in$Well,
                        dat.in$Date
                )
        )
}

file.in<-"./labels/Labels-2022-06-20-Nick-Train.csv"

update.image.labels<-function(file.in,label.in){

        con <- dbConnect(RMariaDB::MariaDB(), group = "IVF",
                         username = "root",
                         password = "embryo",
                         db = "IVF")
        
        label.opts<-c("Label_D1","Label_N2","Label_S2","Model2")
        if(!label.in %in% label.opts) stop("Label provided is not a current option.",call. = F)
        
        # Read in data
        pdb.read<-dbReadTable(con,"PDB")
        images.read<-dbReadTable(con,"image")
        
        # Read in file provided
        tmp.data<-read_csv(file.in,col_types = cols())
        
        # link up file with Machine and Slide from PDB table
        
        img.file<-strsplit(tmp.data$file,"_")
        
        machine<-sapply(img.file,"[[",1)
        slide<-sapply(img.file,"[[",2)
        time<-sapply(img.file,"[[",5)
        time<-gsub('.{4}$', '', time)
        time<-as.integer(time)
        
        # Clean up for matching 
        machine<-as.numeric(gsub("M","",machine))
        slide<-as.numeric(gsub("S","", slide))
        
        
        tmp<-paste0(pdb.read$Machine,"_",pdb.read$Slide)
        
        pdb.read$combloc<-tmp
        
        img.ms<-paste0(machine,"_",slide)
        
        loc<-match(img.ms,tmp)
        
        linked.for.update<-cbind(tmp.data,pdb.read[loc,"pdb"],time)
        colnames(linked.for.update)<-c("class", "file", "labeler","pdb","time")
        
        # Split data into matched and unmatched for update
        
        # Matched data only updates label in matching rows
        
        file.match<-match(linked.for.update$file,images.read$image) %>% 
                na.omit %>%
                as.integer()
        
       
        
        images.match<-match(images.read$image,linked.for.update$file) %>%
                na.omit() %>%
                as.integer()
        
                
                b<-linked.for.update[images.match,] %>% # Update column where they match
                        arrange(file)
                c<-images.read[file.match,] %>% 
                        arrange(image)
                
                c[label.in]<-b$class
         
        file.match.reverse<-(images.read$image %in% c$image)
        images.read[file.match.reverse,]<-c
                
                
        # Un-matched data
        unmatched.loc<-!(linked.for.update$file %in% c$image) 
        unmatched.data<-linked.for.update[unmatched.loc,]
        
        if(nrow(unmatched.data) != 0){
                
                unmatched.data<-cbind(1,linked.for.update$pdb[unmatched.loc],linked.for.update$file[unmatched.loc],NA,NA,NA,NA,linked.for.update$time[unmatched.loc])
                colnames(unmatched.data)<-c("image_id","pdb","image","Label_D1","Label_N2","Label_S2","Model2","time")
                unmatched.data[,label.in]<-linked.for.update$class[unmatched.loc]
                unmatched.data<-as.data.frame(unmatched.data)
                unmatched.data$image_id<-as.integer(unmatched.data$image_id)
                unmatched.data$time<-as.integer(unmatched.data$time)
                
        }
        
        if(nrow(unmatched.data != 0)) {
        
        compiled.data.for.table<-bind_rows(images.read,unmatched.data) %>%
                mutate(image_id=row_number()) 
        } else {
                compiled.data.for.table<-images.read %>%
                        mutate(image_id=row_number())    
        }
        
        # Old code to make first run work
        # linked.for.update<-cbind(tmp.data,pdb.read[loc,"pdb"],time) %>%
        #         mutate(id=row_number())
        # colnames(linked.for.update)<-c("class", "file", "labeler","pdb","time","id")
        # 
        # update.data<-cbind(linked.for.update$id,linked.for.update$pdb,linked.for.update$file,NA,NA,NA,linked.for.update$class,linked.for.update$time)
        # colnames(update.data)<-c("image_id","pdb","image","Label_D1","Label_N2","Label_S2","Model2","time")
        # 
        # update.data<-as.data.frame(update.data)
        # 
        # dbWriteTable(con,"image",out,overwrite=T)
        #return(compiled.data.for.table)
        rows.added<-nrow(compiled.data.for.table)-nrow(images.read)
        
        print(paste0("Added ",rows.added, " images"))
        dbWriteTable(con,"image",compiled.data.for.table,overwrite=T)
        dbDisconnect(con)
}


dd<-update.image.labels("./labels/Labels-2022-06-20-Dorothy.csv","Label_D1")
ee<-update.image.labels("./labels/Labels-2022-06-20-Suyeon.csv","Label_S2")
ff<-update.image.labels("./labels/Labels-2022-06-20-Nick.csv","Label_N2")
