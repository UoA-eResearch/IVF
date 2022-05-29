# Script import Python CSV export and creates a database to query.

library(tidyverse)
library(RSQLite)
library("lubridate")

# Read in list of files
files.in<-read_csv("PDB_database_summary.csv")


first=F
if(first) {
# Save list down as SQLite DB
con <- dbConnect(RSQLite::SQLite(), "PDBdatabase.db")
dbWriteTable(con, "LocalPDB", files.in)
dbDisconnect(con)
}
# Select 100 wells for labelling

slide.list<-unique(files.in$Slide)

set.seed(55845)
who<-sample(slide.list,10)

write.csv(who,file=paste0( "./slides/" ,today()," samples selected.csv"),row.names=F)

con <- dbConnect(RSQLite::SQLite(), "PDBdatabase.db")

sql.code<-paste0("SELECT DISTINCT Location FROM LocalPDB WHERE Slide IN (",paste0(who,collapse=','),")")

out<-dbGetQuery(con,sql.code)
setwd("/mnt/embryo/scripts")
for (i in 1:nrow(out)){
        py.call <- paste0("python3 PDBextract.py -i ",out$Location[i]," -f 0 -o /fastdata/test -m 20")
        print(paste0(round(i/nrow(out)*100,2)," ",py.call))
        system(py.call)
}

#system('python3 PDBextract.py -i ../embryo/2020/776/D2020.03.05_S00711_I0776_D.pdb -f 0 -o /data/test -m 10')
