#set -x
nOfParamsNeeded=1
if test $# -lt $nOfParamsNeeded
then
	echo "assumption: exists file <runsIDsFile> containing list of runIds"
    echo "usage: $0 </path/to/runsIDsFile> [<DB>] [<outputDir>]"
    exit 1
fi

runsIDsFile=$1
dbDir=$HOME/databases/krakenDB16
if test $# -gt $nOfParamsNeeded
then 
	dbDir=$2
fi

while read run
do
	#remove carriage return from dos files
	run=`echo $run | tr -d '\r'`
	#start with new run
	echo "current run:" $run
	mkdir $runsIDsFile
	#createInfoFile (to discover layout)
	echo "creating info file..."
	infoFile="$run/run.info"
	./buildReadInfo.sh $run $infoFile #non funzionante
	#getLayout
	layout=`cat $infoFile | grep 'LibraryLayout' | cut -f2`
	#downloadRead
	echo "downloading run as fastq.gz..."
	./downloadRead.sh "$run" "$layout"
	#analyseRead
	echo "analysing run with Kraken2..."
	./runKraken.sh "./$run"

done < $runsIDsFile

exit 0
