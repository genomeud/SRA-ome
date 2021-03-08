#set -x
nOfParamsNeeded=1
if test $# -lt $nOfParamsNeeded
then
	echo "assumption: exists file <runsIDsFile> containing list of expIds"
    echo "usage: $0 </path/to/runsIDsFile> [<DB>]"
    exit 1
fi

runsIDsFile=$1
dbDir=$HOME/databases/krakenDB16
if test $# -gt $nOfParamsNeeded
then 
	dbDir=$2 
fi
dbName=`basename $dbDir`

while read line
do
	
done < $runsIDsFile 

cd $runsIDDir

#for single
inputFile=${runID}.fastq.gz
#for paired
inputFile1=${runID}_1.fastq.gz
inputFile2=${runID}_2.fastq.gz
#for both
outputFile=${runID}.kraken
reportFile=${runID}.kraken.report.txt
getFiles=""

if test -e "$inputFile"
then
	#single read
	getFiles="$inputFile"
else
	#paired read
	getFiles="--paired $inputFile1 $inputFile2"
fi

command="kraken2 \
--threads $nOfThreads \
--gzip-compressed \
--db $dbDir \
$getFiles \
--output $outputFile \
--report $reportFile"

echo $command | sed s/--/"\n"--/g
echo `$command`

exit 0
