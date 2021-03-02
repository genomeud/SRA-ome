# Run with --help flag for help.
# Modified 07/11/2020 by Fabio Marroni
# Very useful tutorial on the use of SRAdb: https://www.bioconductor.org/packages/release/bioc/vignettes/SRAdb/inst/doc/SRAdb.pdf


suppressPackageStartupMessages({
  library(optparse)
})

option_list = list(
  make_option(c("-D", "--download"), type="logical", default=FALSE,
              help="Should SRA db be downloaded?", metavar="character"),
  make_option(c("-S", "--sqlfile"), type="character", default="",
              help="If download is FALSE, file in which the SRA db is already saved", metavar="character"),
  make_option(c("-F", "--destFolder"), type="character", default="",
              help="If download is TRUE, folder in which the SRA db is to be saved", metavar="character"),
  make_option(c("-T", "--studyType"), type="character", default="None", 
              help="Barplot kmers file name [default= %default]", metavar="character")
)

opt_parser = OptionParser(option_list=option_list);
opt = parse_args(opt_parser);

#print("USAGE: $ 01_small_RNA.r -I input dir/ -O summarized output file")

if (is.null(opt$download)) {
  stop("WARNING: No download file specified with '-D' flag.")
} else {  cat ("download is ", opt$download, "\n")
  download <- opt$download  
  }

if (is.null(opt$sqlfile)) {
  stop("WARNING: No sqlfile specified with '-S' flag.")
} else {  cat ("sqlfile is ", opt$sqlfile, "\n")
  sqlfile <- opt$sqlfile  
  }

if (is.null(opt$destFolder)) {
  stop("WARNING: No destFolder specified with '-S' flag.")
} else {  cat ("destFolder is ", opt$destFolder, "\n")
  destFolder <- opt$destFolder  
  }

if (is.null(opt$studyType)) {
  stop("WARNING: No studyType specified with '-S' flag.")
} else {  cat ("studyType is ", opt$studyType, "\n")
  studyType <- opt$studyType  
  }

 explore_SRA<-function(download,sqlfile,destFolder,studyType)
{
library("data.table")
library(SRAdb)
library("DBI")
#Download and uncompress SRA database file locally (default = in working directory). 
print("Reading connection...")
srafile<-ifelse(download,getSRAdbFile(destdir=destFolder),paste0(destFolder,sqlfile))
print("Connection read...")
con = dbConnect(dbDriver("SQLite"),srafile)

#Only select the desired study type
#onlyt<-dbGetQuery(con,"select * from study where study_type LIKE 'Transcriptome Analysis'")
#myq<-sprintf("select count(*) from study where study_type LIKE '%s",studyType,"'")


getSRAfile( c("SRR8845291"), con, destDir=destFolder,fileType = 'fastq' )
}
explore_SRA(download=download,sqlfile=sqlfile,destFolder=destFolder,studyType=studyType)
