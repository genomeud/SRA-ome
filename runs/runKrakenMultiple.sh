set -x
nOfParamsNeeded=1
if test $# -lt $nOfParamsNeeded
then
	echo "assumption: exists file <runsIDsFile> containing list of runIds"
    echo "usage: $0 </path/to/runsIDsFile> [<DB>]"
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
	mkdir $run
	cd $run
	#createInfoFile (to discover layout)
		#echo "creating info file..."
		#./buildReadInfo.sh $run 'run.info' #non funzionante
	#getLayout
		#layout=`cat 'run.info' | grep 'LibraryLayout' | cut -d'\t' -f2`
	#discover layout directly (brutal way)
	info=`esearch -db sra -query $run | efetch -format runinfo`
	echo $info >run.info
	layout='SINGLE' #default
	isSingle=`echo $info | grep $layout`
	if test -z "$isSingle"
	then
		#single not found ==> paired
		layout='PAIRED'
	fi
	cd ..
	#downloadRead
	echo "downloading run as fastq.gz..."
	./downloadRead.sh "$run" "$layout"
	#analyseRead
	echo "analysing run with Kraken2..."
	./runKraken.sh "./$run"

done < $runsIDsFile

exit 0
