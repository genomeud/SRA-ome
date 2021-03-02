#set -x
nOfParamsNeeded=2
if test $# -lt $nOfParamsNeeded
then
	echo "assumption: exists folder experimentID.kraken.reads containing fastq.gz files"
    echo "usage: $0 <nOfThreads> <experimentID> [<DB>]"
    exit 1
fi

dbDir=$HOME/databases/krakenDB16/
nOfThreads=$1
experimentID=$2

if test $# -gt $nOfParamsNeeded
then
    dbDir=$3
fi

resultsDir=${experimentID}.kraken.reads
cd $resultsDir

#for single
inputFile=${experimentID}.fastq.gz
#for paired
inputFile1=${experimentID}_1.fastq.gz
inputFile2=${experimentID}_2.fastq.gz
#for both
outputFile=${experimentID}.kraken
reportFile=${experimentID}.kraken.report.txt
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
