#set -x
nOfParamsNeeded=1
if test $# -lt $nOfParamsNeeded
then
	echo "assumption: exists folder ./experimentID.kraken.reads containing fastq.gz files"
    echo "usage: $0 <experimentID> [</path/to/DB>]"
    exit 1
fi

nOfThreads=8
experimentID=$1
dbDir=$HOME/databases/krakenDB16
if test $# -gt $nOfParamsNeeded
then
    dbDir=$2
fi
dbName=`basename $dbDir`

fastqDir=${experimentID}.kraken.reads
cd $fastqDir

resultsDir=${dbName}_results
mkdir $resultsDir

#for single
inputFile=${experimentID}.fastq.gz
#for paired
inputFile1=${experimentID}_1.fastq.gz
inputFile2=${experimentID}_2.fastq.gz
#for both
outputFile=${resultsDir}/${experimentID}.kraken
reportFile=${resultsDir}/${experimentID}.kraken.report.txt
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
