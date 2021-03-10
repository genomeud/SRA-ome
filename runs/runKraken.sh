#set -x
nOfParamsNeeded=1
if test $# -lt $nOfParamsNeeded
then
	echo "assumption: exists directory <runID> containing fastq.gz files"
    echo "usage: $0 </path/to/runID> [</path/to/DB>]"
    exit 1
fi

nOfThreads=8
runIDDir=$1
runID=`basename $runIDDir`
dbDir=$HOME/databases/krakenDB16
if test $# -gt $nOfParamsNeeded
then 
	dbDir=$2 
fi
dbName=`basename $dbDir`
cd $runIDDir

resultsDir=${dbName}_results
mkdir $resultsDir

#for single
inputFile=${runID}.fastq.gz
#for paired
inputFile1=${runID}_1.fastq.gz
inputFile2=${runID}_2.fastq.gz
#for both
outputFile=${resultsDir}/${runID}.kraken
reportFile=${resultsDir}/${runID}.kraken.report.txt
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
echo -n `$command`

exit 0
