set -x
nOfParamsNeeded=1
if test $# -lt $nOfParamsNeeded
then
	echo "assumption: exists file <runsIDsFile> containing list of runIds"
    echo "usage: $0 </path/to/runsIDsFile> [<mainOutDir>]"
    exit 1
fi

runsIDsFile=$1
if test $# -gt $nOfParamsNeeded
then 
	mainOutDir=$2
	#remove eventual "/" at the end of the folder path
	mainOutDir=`echo $mainOutDir | sed s:/$::`
fi

logFile=$mainOutDir'/log.txt'
echo -e 'input file:' $runsIDsFile "\n" >$logFile

i=1
n=`cat $runsIDsFile | wc -l`

#cat $runsIDsFile | while read line
#do
while test $i -le $n
do
	line=`cat $runsIDsFile | head -n $i | tail -n 1`
	if ! test -z $line 
	then
		run=$line
		#remove eventual carriage return from dos files
		run=`echo $run | tr -d '\r'`
		currOutDir="$mainOutDir/$run"
		#start with new run
		echo "current run:" $run | tee -a $logFile
		mkdir $currOutDir
		#createInfoFile (to discover layout)
		echo "creating info file..." | tee -a $logFile
		infoFile="$currOutDir/run.info"
		./buildReadInfo.sh $run $infoFile
		#getLayout
		layout=`cat $infoFile | grep 'LibraryLayout' | cut -f2`
		#downloadRead
		echo "downloading run as fastq.gz..." | tee -a $logFile
		./downloadRead.sh "$run" "$layout" "$mainOutDir"
		#analyseRead
		echo "analysing run with Kraken2..." | tee -a $logFile
		./runKraken.sh "$currOutDir"
		echo "analysis done. Deleting fastq.gz file..." | tee -a $logFile
		#finds only: SRR$run.fastq.gz or SRR$run_1.fastq.gz or SRR$run_2.fastq.gz
		ls $currOutDir | egrep "$run(_[1,2])?\.fastq\.gz" | xargs -d"\n" rm
		echo -e "done:" $run "\n" | tee -a $logFile
	fi
	i=$[$i+1]
done

exit 0
