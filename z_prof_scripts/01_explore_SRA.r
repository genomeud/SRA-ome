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

if(studyType!="metatranscriptomics") 
{
myq<-paste0("select * from study where study_type LIKE '",studyType,"'")
onlyq<-dbGetQuery(con,myq)
}
#To select metatranscriptomics we should not use the study type but library_strategy and lybrary source
if(studyType=="metatranscriptomics") 
{
onlyq <- dbGetQuery(con, paste( "SELECT * FROM experiment where library_strategy LIKE 'RNA-seq' AND library_source LIKE 'METATRANSCRIPTOMIC'", sep=""))
cat("Nrow before filtering",nrow(onlyq),"\n")
onlyq<-onlyq[!is.na(onlyq$experiment_accession)&onlyq$experiment_accession!="",]
onlyq$read_spec<-NULL
cat("Nrow after filtering",nrow(onlyq),"\n")
}
onlyq$downloaded<-onlyq$runs<-NA


write.table(onlyq,paste0(destFolder,gsub(" ","_",studyType),"_table.txt"),row.names=F,sep="\t",quote=F)
 
#DO not run the shit below!!!
explore<-FALSE
if(explore)
{ 

sra_tables <- dbListTables(con)



ttest<-allConv$run[allConv$submission%in%onlyq$submission_accession]


conversion<-sraConvert(onlyt$submission_accession[100],sra_con=con)

#Just in case... I noticed sometimes there's some duplicated run
myruns<-unique(conversion$run)
getSRAfile( c("SRX000122"), con, destDir=destFolder,fileType = 'fastq' )

#List all files associated to an accession number in SRA
listSRAfile('SRP026197',con)
#Get a list of DB tables available. These can then be further explored
sra_tables <- dbListTables(con)
#List fields in the "study" table
dbListFields(con,"study")
#Get SQL schema
dbGetQuery(con,'PRAGMA TABLE_INFO(study)')
colDesc <- colDescriptions(sra_con=con)
#SQL query: select first three occurrences of the study table
rs <- dbGetQuery(con,"select * from study limit 3")
#SQL query: Get the SRA study accessions and titles from SRA study that study type contains “Transcriptome”. 
#The “%” sign is used in combination with the “like” operator to do a “wildcard”
#search for the term “Transcriptome” with any number of characters after it.
rs <- dbGetQuery(con, paste( "select study_accession,
 study_title from study where",
 "study_description like 'Transcriptome%'",sep=" "))
#Actually paste was not needed
 rs <- dbGetQuery(con, "select study_accession,
 study_title from study where study_description like 'Transcriptome%'")

 #Count number of records in some tables
getTableCounts <- function(tableName,conn) {
	sql <- sprintf("select count(*) from %s",tableName)
	return(dbGetQuery(conn,sql)[1,1])
	}

do.call(rbind,sapply(sra_tables[c(2,4,5,11,12)],
	getTableCounts, con, simplify=FALSE))

#Count how many instances are there for each study type
rs <- dbGetQuery(con, paste( "SELECT study_type AS StudyType,
 count( * ) AS Number FROM `study` GROUP BY study_type order
 by Number DESC ", sep=""))

 


#Get fastq files
getSRAfile( c("SRP229029"), con, fileType = 'fastq' )
#Problem I get a fastq with this command, but the study actually has 12!!!!

#We can do this:
conversion<-sraConvert("SRP229029",sra_con=con)
myexp<-conversion$experiment
getSRAfile( conversion$experiment, con, fileType = 'fastq' )
#The above has some problems, probably because the experiment field is not always right.
#We can try this:
getSRAfile( unique(conversion$submission), con, fileType = 'fastq' )
#Both of them seems to download part of the files.
#However, this might be a problem due to the fact that the experiments we are fetching are old...
#I would insist in trying those...



#Random stuff...
pippo<-dbGetQuery(con,"select * from study where study_ID = 200")
dbGetQuery(con,"select * from study where study_alias = DRP000220")
 
 
#fasp is probably the fastest option; I will try to install it in the future. For the moment I stick to ftp. 
#I am lazy and I want to download fastq  
ciccio<-listSRAfile ( c("SRX000122"), con, fileType = 'fastq', srcType='fasp') 
#ciccio<-listSRAfile ( c("SRX000122"), con, fileType = 'fastq', srcType='fasp') 
ciccio<-getFASTQinfo( c("SRX000122"), con, srcType = 'ftp' ) 
getSRAfile( c("SRX000122"), con, fileType = 'fastq' )
getSRAfile( c("SRA115106"), con, fileType = 'fastq' )
}


}
explore_SRA(download=download,sqlfile=sqlfile,destFolder=destFolder,studyType=studyType)
