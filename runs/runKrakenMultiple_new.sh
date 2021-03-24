#set -x
nOfParamsNeeded=2
if test $# -lt $nOfParamsNeeded
then
	echo "assumption: exists file <runsIDsFile> containing list of runIds"
    echo "usage: $0 </path/to/runsIDsFile> <mainOutDir> [<createInfoFile=<T/F>>]"
    exit 1
fi

runsIDsFile=$1
mainOutDir=$2
#remove eventual "/" at the end of the folder path
mainOutDir=`echo $mainOutDir | sed s:/$::`
createInfoFile='F'

if test $# -gt $nOfParamsNeeded
then 
	createInfoFile=$3
fi

logFile=$mainOutDir'/log.txt'
echo -e 'input file:' $runsIDsFile "\n" >$logFile
errorFile=$HOME/'ncbi_error_report.txt'
i=1
n=`cat $runsIDsFile | wc -l`

#cat $runsIDsFile | while read line
#do
while test $i -le $n
do
	line=`cat $runsIDsFile | head -n $i | tail -n 1` 2>>$logFile
	if ! test -z $line 
	then
		run=`echo $line | cut -d',' -f1`
		#remove eventual carriage return from dos files
		run=`echo $run | tr -d '\r'` 2>>$logFile
		currOutDir="$mainOutDir/$run"
		#start with new run
		echo "current run:" $run | tee -a $logFile
		mkdir $currOutDir 2>>$logFile
		if test $createInfoFile = 'T'
		then
			#createInfoFile (to discover layout)
			echo "creating info file..." | tee -a $logFile
			infoFile="$currOutDir/run.info"
			./buildReadInfo.sh $run $infoFile 2>>$logFile | tee -a $logFile
			#getLayout from infofile
			layout=`cat $infoFile | grep 'LibraryLayout' | cut -f2` 2>>$logFile
		else
			#get layout from input file (2nd field)
			layout=`echo $line | cut -d',' -f2`
		fi
		#downloadRead
		echo "downloading run as fastq.gz..." | tee -a $logFile
		./downloadRead.sh "$run" "$layout" "$mainOutDir" 2>>$logFile | tee -a $logFile
		#analyseRead
		echo "analysing run with Kraken2..." | tee -a $logFile
		./runKraken.sh "$currOutDir" 2>>$logFile | tee -a $logFile
		#check if some error came out (in this case don't delete files)
		if test -e "$errorFile"
		then
			errorFileName=`basename $errorFile`
			newErrorFile=${currOutDir}/${errorFileName}.xml
			>&2 echo "possible some errors while downloading!" | tee -a $logFile
			>&2 echo "check file" "$newErrorFile" | tee -a $logFile
			mv "$errorFile" "$newErrorFile"
		else
			#remove useless files
			#finds only: SRR$run.fastq.gz or SRR$run_1.fastq.gz or SRR$run_2.fastq.gz
			echo "analysis done. Deleting fastq.gz file..." | tee -a $logFile
			cd $currOutDir
			ls | egrep "$run(_[1,2])?\.fastq\.gz" | xargs -d"\n" rm 2>>../../$logFile
			cd 'krakenDB16_results'
			ls | grep "$run.kraken$" | xargs -d"\n" rm 2>>../../../$logFile
			cd ../../..
		fi
		#end
		echo -e "done:" $run "\n" | tee -a $logFile
	fi
	i=$[$i+1]
done

exit 0
