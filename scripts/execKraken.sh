#set -x
nOfParamsNeeded=1
if test $# -lt $nOfParamsNeeded
then
	echo "assumption: exists directory <runID> containing .fastq files"
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

#resultsDir=${dbName}_results
#mkdir $resultsDir

#for single
inputFile=${runID}.fastq
#for paired
inputFile1=${runID}_1.fastq
inputFile2=${runID}_2.fastq
#for both
outputFile=${runID}.kraken
reportFile=${runID}.kraken.report.txt
runFiles=""

if test -e "$inputFile"
then
	#single read
	runFiles="$inputFile"
else
	#paired read
	runFiles="--paired $inputFile1 $inputFile2"
fi

command="kraken2 \
--threads $nOfThreads \
--db $dbDir \
$runFiles \
--output $outputFile \
--report $reportFile"

#echo $command | sed s/--/"\n"--/g
echo $command

echo -n `$command`

exit 0
