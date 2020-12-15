# Run with --help flag for help.
# Modified 09/11/2020 by Fabio Marroni
# Very useful tutorial on the use of SRAdb: https://www.bioconductor.org/packages/release/bioc/vignettes/SRAdb/inst/doc/SRAdb.pdf


suppressPackageStartupMessages({
  library(optparse)
})

option_list = list(
  make_option(c("-S", "--sqlfile"), type="character", default="/projects/populus/ep/share/marroni/EOSC/SRAmetadb.sqlite",
              help="If download is FALSE, file in which the SRA db is already saved [default= %default]", metavar="character"),
  make_option(c("-I", "--infile"), type="character", default="/projects/populus/ep/share/marroni/EOSC/metatranscriptomics_table.txt",
              help="If download is TRUE, folder in which the SRA db is to be saved [default= %default]", metavar="character"),
  make_option(c("-D", "--how_many_sra"), type="numeric", default=2,
              help="How many SRA experiments should be downloaded [default= %default]", metavar="character"),
  make_option(c("-R", "--reverse"), type="logical", default=TRUE,
              help="Should we proceed in reverse order, i.e. from newest to older experiments? [default= %default]", metavar="character"),
  make_option(c("-F", "--destFolder"), type="character", default="/projects/populus/ep/share/marroni/EOSC/reads/Metatranscriptomics",
              help="Folder in which the downloaded reads are saved [default= %default]", metavar="character")
)

opt_parser = OptionParser(option_list=option_list);
opt = parse_args(opt_parser);

#print("USAGE: $ 01_small_RNA.r -I input dir/ -O summarized output file")


if (is.null(opt$sqlfile)) {
  stop("WARNING: No sqlfile specified with '-S' flag.")
} else {  cat ("sqlfile is ", opt$sqlfile, "\n")
  sqlfile <- opt$sqlfile  
  }

if (is.null(opt$infile)) {
  stop("WARNING: No infile specified with '-S' flag.")
} else {  cat ("infile is ", opt$infile, "\n")
  infile <- opt$infile  
  }

if (is.null(opt$reverse)) {
  stop("WARNING: No reverse specified with '-S' flag.")
} else {  cat ("reverse is ", opt$reverse, "\n")
  reverse <- opt$reverse  
  }

if (is.null(opt$how_many_sra)) {
  stop("WARNING: No how_many_sra specified with '-S' flag.")
} else {  cat ("how_many_sra is ", opt$how_many_sra, "\n")
  how_many_sra <- opt$how_many_sra  
  }

if (is.null(opt$destFolder)) {
  stop("WARNING: No destFolder specified with '-S' flag.")
} else {  cat ("destFolder is ", opt$destFolder, "\n")
  destFolder <- opt$destFolder  
  }

explore_SRA<-function(sqlfile,infile,destFolder,how_many_sra,reverse)
{
library("data.table")
library(SRAdb)
library("DBI")
#Estabilish connection with database
con = dbConnect(dbDriver("SQLite"),sqlfile)
for(dload in 1:how_many_sra)
{
cat("Round",dload,"\n")
#Dirty trick. If the file doesn't exists, it means that is being read by the other process, and we just wait 30 seconds
if(!file.exists(infile)) Sys.sleep(30)
onlyq<-fread(infile,data.table=F,quote="",fill=T)
#Only start where needed, do not repeat analysis
#If reverse is FALSE we start from the first NA, i.e. the older experiments for which we didn't attempt a download
#If reverse is TRUE we start from the last NA, i.e. the newer experiment for which we didn't attempt a download
#downloadMe<-min(which(is.na(onlyq$downloaded)))
mymax<-max(which(is.na(onlyq$downloaded)))
if(mymax=="-Inf") mymax<-nrow(onlyq)
mymin<-min(which(is.na(onlyq$downloaded)))
if(mymin=="Inf") mymin<-1
downloadMe<-ifelse(reverse,mymax,mymin)
#Get unique names of runs corresponding to the SRA accession
getMe<-unique(sraConvert(onlyq$experiment_accession[downloadMe],sra_con=con)$run)
cat("Attempting to download files", getMe,"\n")
onlyq$downloaded[downloadMe]<-"Attempted"
write.table(onlyq,infile,row.names=F,sep="\t",quote=F)
if(length(getMe)<1) 
{
cat ("No files found, going to next experiment\n")
next
}

#I use a system call to wget to avoid the problem of some fastq files being referred to several experiments and thus donwloaded several times, 
#causing delays in download
myd<-try(getFASTQinfo(onlyq$experiment_accession[downloadMe],con))
if(class(myd)=="try-error") next
myd<-myd[myd$experiment%in%onlyq$experiment_accession[downloadMe],]
#Check that we didn't already download the run (that's possible)
myd<-myd[!myd$run%in%onlyq$runs,]
if(nrow(myd)<1) next
for(aaa in 1:nrow(myd))
{
mycommand<-paste("wget --no-verbose -P",destFolder,myd$ftp[aaa])
dres<-try(system(mycommand))
}


#If download is FULLY completed, we set the SRA entry as "Yes", i.e. fully donwloaded
if(class(dres)!="try-error")
{
onlyq$downloaded[downloadMe]<-"Yes"
onlyq$runs[downloadMe]<-paste(getMe,collapse=";")
#After downloading rewrite file with updated fields
write.table(onlyq,infile,row.names=F,sep="\t",quote=F)
#List files (only for debugging)
print(dir(destFolder))
}
}


}
explore_SRA(sqlfile=sqlfile,infile=infile,destFolder=destFolder,how_many_sra=how_many_sra,reverse=reverse)
