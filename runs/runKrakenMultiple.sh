#set -x

nOfParamsNeeded=3
if test $# -lt $nOfParamsNeeded
then
	echo "assumption: exists file <runsIDsFile> containing list of runIds to download ad analyse"
    echo "usage: $0 <runsIDsFile> <outDirectory> createInfoFile=<TRUE | FALSE> [<allRunsFile.csv>]"
    exit 1
fi

runsIDsFile=$1
mainOutDir=$2
createInfoFile=$3
allRunsFile=''
#remove eventual "/" at the end of the folder path
mainOutDir=`echo $mainOutDir | sed s:/$::`

if test $# -gt $nOfParamsNeeded
then
	allRunsFile=$4
fi

#output files
resultAllFile=$mainOutDir'/results_all.csv'
resultErrFile=$mainOutDir'/results_err.csv'
logFile=$mainOutDir'/log.txt'
echo -e 'input file:' $runsIDsFile "\n" >$logFile
echo -n >$resultAllFile
echo -n >$resultErrFile
NCBIErrorFile=$HOME/'ncbi_error_report.txt'
i=1
n=`cat $runsIDsFile | wc -l`

#status constants
OK_STATUS='OK'
ERR_STATUS='ERR'
#status of current run
RUN_STATUS=$OK_STATUS

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
		echo "$i of $n" | tee -a $logFile
		echo "current run:" $run | tee -a $logFile
		mkdir $currOutDir 2>>$logFile
		if test $createInfoFile = 'TRUE'
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
		echo "downloading run as .fastq..." | tee -a $logFile
		printToLogFile=`./downloadRead.sh "$run" "$layout" "$mainOutDir" 2>>$logFile`
		if test $? -ne 0
		then
			RUN_STATUS=$ERR_STATUS
		fi
		#can't do: tee -a $logFile, would lose exit status of ./downloadRead.sh
		echo $printToLogFile>>$logFile
		#check if some error came out (in this case don't run kraken)
		if test $RUN_STATUS = $ERR_STATUS
		then
			#NCBIErrorFileName=`basename $NCBIErrorFile`
			#newErrorFile=${currOutDir}/${NCBIErrorFileName}.xml
			echo "possible some errors while downloading!" | tee -a $logFile
			#mv "$NCBIErrorFile" "$newErrorFile"
			#echo "check file" "$newErrorFile" | tee -a $logFile
		else
			#analyseRead
			echo "analysing run with Kraken2..." | tee -a $logFile
			./runKraken.sh "$currOutDir" 2>>$logFile | tee -a $logFile
		fi
		#remove useless files
		echo "analysis done. Deleting .fastq file..." | tee -a $logFile
		cd $currOutDir
		#finds only: $run.fastq.gz or $run_1.fastq.gz or $run_2.fastq.gz
		ls | egrep "$run(_[1,2])?\.fastq" | xargs -d"\n" rm 2>>../../$logFile
		if test $RUN_STATUS = $OK_STATUS
		then
			cd 'krakenDB16_results'
			#finds only: $run.kraken
			ls | grep "$run.kraken$" | xargs -d"\n" rm 2>>../../../$logFile
			cd ..
			echo $run','$OK_STATUS >>../../$resultAllFile
		else
			echo $run','$ERR_STATUS >>../../$resultErrFile
			echo $run','$ERR_STATUS >>../../$resultAllFile
		fi
		cd ../..
		#end
		echo -e "done:" $run "\n" | tee -a $logFile
	fi
	i=$[$i+1]
done

hasErrors=`cat $resultErrFile`
if test -z $hasErrors
then
	#no errors detected
	rm $resultErrFile
fi

if ! test -z "$allRunsFile"
then
	#update run files
	allRunsFile_Run_Idx=8
	allRunsFile_Done_Idx=19
	resultsAllFile_Run_Idx=1
	resultsAllFile_Done_Idx=2
	echo "updating runs file" | tee -a $logFile

	#call script
	../metadata/updateAllRunsFile.sh \
	$allRunsFile \
		$allRunsFile_Run_Idx \
		$allRunsFile_Done_Idx \
	$resultAllFile \
		$resultsAllFile_Run_Idx \
		$resultsAllFile_Done_Idx \
	2>>$logFile | tee -a $logFile

	echo "update done" | tee -a $logFile
fi

exit 0
