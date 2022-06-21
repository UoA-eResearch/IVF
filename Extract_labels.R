# Script will extract Data Labels by checking directory structure of a given directory. 
library(data.table)
library(readr)

ExtractLabels<-function(dir.name,labeler) {

a<-list.files(dir.name, recursive = T)

b<-strsplit(a,"/",fixed=T)

class<-sapply(b,"[[",1)
file<-sapply(b,"[[",2)

loc<-grep("\\d_S",class)
# Remove Classes that have sample id in name as they are not labels
if(length(loc) != 0) {
        class<-class[-loc]
        file<-file[-loc]
}

# Check that file has proper extension and images are only one layer deep.

if(length(file) != length(grep("*.jpg",file))) stop("Some files are not jpg or are more than one level deep. Check data")

collectedLabels<-data.table(class,file,labeler)

print(paste0("Found ", length(unique(class)), " classes across ",length(file)," files."))

if(dir.exists("./labels")==FALSE) stop("labels directory is not a sub-directory from where you have called this function.",call. = FALSE)

write_csv(file=paste0("./labels/Labels-",Sys.Date(),"-",labeler,".csv"),collectedLabels)
}

# Test
ExtractLabels("/home/nick/dbox/EmbryoLabeling/Labelers/Four","Nick")
ExtractLabels("/home/nick/dbox/EmbryoLabeling/Labelers/One","Helen")
ExtractLabels("/home/nick/dbox/EmbryoLabeling/Labelers/Dorothy","Dorothy")
ExtractLabels("/home/nick/dbox/EmbryoLabeling/Labelers/SuYeon","Suyeon")
ExtractLabels("/home/nick/dbox/EmbryoLabeling/Labelers/train","Nick-Train")


