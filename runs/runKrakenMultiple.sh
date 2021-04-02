set -x

nOfParamsNeeded=3
if test $# -lt $nOfParamsNeeded
then
	echo "assumption: exists file <runsIDsFile> containing list of runIds to download ad analyse"
    echo "usage: $0 <runsIDsFile> <outputDir> createInfoFile=<TRUE | FALSE> [<allRunsFile.csv>]"
    exit 1
fi

DIR_SCRIPT_ANALYSIS=$HOME/'SRA/runs'
DIR_SCRIPT_METADATA=$HOME/'SRA/metadata'
#scripts
buildReadInfo_script=$DIR_SCRIPT_ANALYSIS/'buildReadInfo.sh'
downloadRead_script=$DIR_SCRIPT_ANALYSIS/'downloadRead.sh'
runKraken_script=$DIR_SCRIPT_ANALYSIS/'runKraken.sh'
updateAllRunsFile_script=$DIR_SCRIPT_METADATA/'updateAllRunsFile.sh'

runsIDsFile=$1

DIR_OUTPUT_MAIN=`echo $2 | sed s:/$::`
#now=$(date '+%Y_%m_%d')
#DIR_OUTPUT_MAIN=$DIR_SCRIPT_ANALYSIS/'analysis'/"$now"
#remove eventual "/" at the end of the folder path

createInfoFile=$3

allRunsFile=''
if test $# -gt $nOfParamsNeeded
then
	allRunsFile=$4
fi

#output info dir
DIR_OUTPUT_INFO=$DIR_OUTPUT_MAIN/'.info'
#output info files
resultAllFile=$DIR_OUTPUT_MAIN'/results_all.csv'
resultErrFile=$DIR_OUTPUT_MAIN'/results_err.csv'
logFile=$DIR_OUTPUT_MAIN'/log.txt'
#clear files
echo -e 'input file:' $runsIDsFile "\n" >$logFile
echo -n >$resultAllFile
echo -n >$resultErrFile

#NCBIErrorFile=$HOME/'ncbi_error_report.txt'

i=1
n=`cat $runsIDsFile | wc -l`

#status constants
STATUS_OK='OK'
STATUS_ERR='ERR'
#status of current run
STATUS_CURR_RUN=$STATUS_OK

cd $DIR_OUTPUT_MAIN

#cat $runsIDsFile | while read line
#do
while test $i -le $[$n+1]
do
	line=`cat $runsIDsFile | head -n $i | tail -n 1` 2>>/dev/null
	if ! test -z $line 
	then
		run=`echo $line | cut -d',' -f1`
		#remove eventual carriage return from dos files
		run=`echo $run | tr -d '\r'` 2>>$logFile
		currOutDir="$DIR_OUTPUT_MAIN/$run"
		#start with new run
		echo "$i of $n" | tee -a $logFile
		echo "current run:" $run | tee -a $logFile
		mkdir $currOutDir 2>>/dev/null
		if test $createInfoFile = 'TRUE'
		then
			#createInfoFile (to discover layout)
			echo "creating info file..." | tee -a $logFile
			infoFile="$currOutDir/run.info"
			$buildReadInfo_script $run $infoFile 2>>$logFile | tee -a $logFile
			#getLayout from infofile
			layout=`cat $infoFile | grep 'LibraryLayout' | cut -f2` 2>>$logFile
		else
			#get layout from input file (2nd field)
			layout=`echo $line | cut -d',' -f2`
		fi
		#downloadRead
		echo "downloading run as .fastq..." | tee -a $logFile
		printToLogFile=`"$downloadRead_script" "$run" "$layout" "$DIR_OUTPUT_MAIN" 2>>$logFile`
		if test $? -ne 0
		then
			STATUS_CURR_RUN=$STATUS_ERR
		fi
		#can't do: tee -a $logFile, would lose exit status of ./downloadRead.sh
		echo $printToLogFile>>$logFile
		#check if some error came out (in this case don't run kraken)
		if test $STATUS_CURR_RUN = $STATUS_ERR
		then
			#NCBIErrorFileName=`basename $NCBIErrorFile`
			#newErrorFile=${currOutDir}/${NCBIErrorFileName}.xml
			echo "possible some errors while downloading!" | tee -a $logFile
			#mv "$NCBIErrorFile" "$newErrorFile"
			#echo "check file" "$newErrorFile" | tee -a $logFile
		else
			#analyseRead
			echo "analysing run with Kraken2..." | tee -a $logFile
			"$runKraken_script" "$currOutDir" 2>>$logFile | tee -a $logFile
		fi
		#remove useless files
		echo "analysis done. Deleting .fastq file..." | tee -a $logFile
		cd $currOutDir
		#finds only: $run.fastq.gz or $run_1.fastq.gz or $run_2.fastq.gz
		ls | egrep "$run(_[1,2])?\.fastq" | xargs -d"\n" rm 2>>$logFile
		cd ..

		if test $STATUS_CURR_RUN = $STATUS_OK
		then
			cd $currOutDir/'krakenDB16_results'
			#finds only: $run.kraken
			ls | grep "$run.kraken$" | xargs -d"\n" rm 2>>$logFile
			cd ../..
			echo $run','$STATUS_OK >>$resultAllFile

		else
			echo $run','$STATUS_ERR >>$resultErrFile
			echo $run','$STATUS_ERR >>$resultAllFile
		fi
		#end
		echo -e "done:" $run "\n" | tee -a $logFile
	fi
	i=$[$i+1]
done

hasErrors=`cat "$resultErrFile"`
if test -z "$hasErrors"
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
	$updateAllRunsFile_script \
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
