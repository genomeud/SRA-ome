#!/bin/bash
#set -x

nOfParamsNeeded=3

if test $# -lt $nOfParamsNeeded
then
	echo "assumption: exists file <runsIDsFile> containing list of runIds to download ad analyse"
    echo "usage: $0 <runsIDsFile> <outputDir> createInfoFile=<TRUE | FALSE> [<allRunsFile.csv>]"
	echo "example: $0 /path/.info/runs_list.csv /path/to/out/dir FALSE $HOME/SRA/metadata/metadata_filtered_small.csv"
    exit 1
fi

DIR_SCRIPT=$HOME/'SRA/scripts'
#scripts
buildReadInfo_script=$DIR_SCRIPT/'buildReadInfo.sh'
execFasterQDump_script=$DIR_SCRIPT/'execFasterQDump.sh'
execKraken_script=$DIR_SCRIPT/'execKraken.sh'
getFastqFileSize_script=$DIR_SCRIPT/'getFastqFileSize.sh'
updateAllRunsFile_script=$DIR_SCRIPT/'updateAllRunsFile.sh'

runsIDsFile=$1

DIR_OUTPUT_MAIN=`echo $2 | sed s:/$::`
#now=$(date '+%Y_%m_%d')
#DIR_OUTPUT_MAIN=$DIR_SCRIPT/'analysis'/"$now"
#remove eventual "/" at the end of the folder path
mkdir $DIR_OUTPUT_MAIN 2>>/dev/null

createInfoFile=$3

allRunsFile=''
if test $# -gt $nOfParamsNeeded
then
	allRunsFile=$4
fi

cd $DIR_OUTPUT_MAIN

#output info dir
DIR_OUTPUT_INFO=$DIR_OUTPUT_MAIN/'.info'
mkdir $DIR_OUTPUT_INFO 2>>/dev/null
#output info files
resultAllFile=$DIR_OUTPUT_INFO'/results_all.csv'
resultErrFile=$DIR_OUTPUT_INFO'/results_err.csv'
sizeOfFastqFile=$DIR_OUTPUT_INFO'/fastq_files_size.txt'
updatesFiles=$DIR_OUTPUT_INFO'/updates_log.txt'
logFile=$DIR_OUTPUT_INFO'/log.txt'
#create or clear files
echo -n >$resultAllFile
echo -n >$resultErrFile
echo -n >$sizeOfFastqFile
echo -n >$updatesFiles
echo -e 'input file:' $runsIDsFile "\n" >$logFile

#NCBIErrorFile=$HOME/'ncbi_error_report.txt'

i=1
n=`cat $runsIDsFile | wc -l`

#status constants
STATUS_OK='OK'
STATUS_ERR='ERR'
#status of current run
STATUS_CURR_RUN=$STATUS_OK

#cat $runsIDsFile | while read line
#do
while test $i -le $n
do
	STATUS_CURR_RUN=$STATUS_OK
	line=`cat $runsIDsFile | head -n $i | tail -n 1` 2>>/dev/null
	if ! test -z $line 
	then
		#get run from input file (first field)
		run=`echo $line | cut -d',' -f1`

		#remove eventual carriage return from dos files
		run=`echo $run | tr -d '\r'` 2>>$logFile

		#print current run
		echo "$i of $n" | tee -a $logFile
		echo "current run:" $run | tee -a $logFile

		#create run directory
		runDir="$DIR_OUTPUT_MAIN/$run"
		mkdir $runDir 2>>/dev/null

		#get run layout
		if test $createInfoFile = 'TRUE'
		then
			#createInfoFile (to discover layout)
			echo "creating info file..." | tee -a $logFile
			infoFile="$runDir/run.info"
			$buildReadInfo_script $run $infoFile 2>>$logFile | tee -a $logFile
			#getLayout from infofile
			layout=`cat $infoFile | grep 'LibraryLayout' | cut -f2` 2>>$logFile
		else
			#get layout from input file (2nd field)
			layout=`echo $line | cut -d',' -f2`
		fi

		#downloadRun
		echo "downloading run as .fastq..." | tee -a $logFile
		printToLogFile=`"$execFasterQDump_script" "$run" "$layout" "$runDir" 2>>$logFile | tee -a $logFile`
		downloadExitCode=${PIPESTATUS[0]}
			
		#download error
		if test $downloadExitCode -ne 0
		then
			STATUS_CURR_RUN=$STATUS_ERR
			echo "Error: Download caused error with exit code: $downloadExitCode"  | tee -a $logFile
		fi
		
		#save compressed size and actual size
		#compressed size MB: value stored in SRA DB (3rd parameter in RunsIDFile)
		#actual size: value obtained from getFastqFileSize (ls | grep | cut)
		compressedSizeMB=`echo $line | cut -d',' -f3`
		#print compressed size in output
		echo -e -n $run'\t'$compressedSizeMB'\t'>>$sizeOfFastqFile
		#calculate actual size
		totalSizeMB=`$getFastqFileSize_script $runDir $run $layout`
		#check if got some error (file not exists?)
		if test $? -eq 0
		then
			#print size in output
			echo $totalSizeMB >>$sizeOfFastqFile
		else
			#did not found any fastq files
			STATUS_CURR_RUN=$STATUS_ERR
			echo 'Error: Fastq file downloaded not found' | tee -a $logFile
			#print error instead of actual size in output
			echo 'NO_FASTQ_FOUND' >>$sizeOfFastqFile
		fi

		#check if some error came out (in this case don't run kraken)
		if test $STATUS_CURR_RUN = $STATUS_OK
		then
			#analyseRead
			echo "analysing run with Kraken2..." | tee -a $logFile
			"$execKraken_script" "$runDir" 2>>$logFile | tee -a $logFile
			#remove useless files
			echo "analysis done. Deleting .fastq file..." | tee -a $logFile
			cd $runDir
			#finds only: $run.fastq or $run_1.fastq or $run_2.fastq
			ls | egrep "$run(_[1,2])?\.fastq" | xargs -d"\n" rm 2>>$logFile
			cd ..
		fi

		#check if some error came out (in this case don't remove files)
		#NB: with fasterq-dump, temp files are removed from fasterq in any case in case of error.
		if test $STATUS_CURR_RUN = $STATUS_OK
		then
			cd $runDir
			#finds only: $run.kraken
			ls | grep "$run.kraken$" | xargs -d"\n" rm 2>>$logFile
			cd ..
			echo $run','$STATUS_OK >>$resultAllFile
		else
			echo $run','$STATUS_ERR >>$resultErrFile
			echo $run','$STATUS_ERR >>$resultAllFile
		fi

		#end
		echo -e "done: $run \n" | tee -a $logFile
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
	$updatesFiles \
	2>>$logFile | tee -a $logFile

	echo "update done" | tee -a $logFile
fi

echo -e "\n""end" | tee -a $logFile

exit 0
