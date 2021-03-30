set -x
nOfParamsNeeded=2
if test $# -lt $nOfParamsNeeded
then
	echo "assumption: exists file <runsIDsFile> containing list of runIds"
    echo "usage: $0 </path/to/runsIDsFile> <mainOutDir> [createInfoFile=<TRUE | dflt=FALSE>]"
    exit 1
fi

runsIDsFile=$1
mainOutDir=$2
#remove eventual "/" at the end of the folder path
mainOutDir=`echo $mainOutDir | sed s:/$::`
createInfoFile='FALSE'

if test $# -gt $nOfParamsNeeded
then 
	createInfoFile=$3
fi

logFile=$mainOutDir'/log.txt'
echo -e 'input file:' $runsIDsFile "\n" >$logFile
NCBIErrorFile=$HOME/'ncbi_error_report.txt'
i=1
n=`cat $runsIDsFile | wc -l`

#results constants
YES='YES'
ERROR='ERR'
#results files
resultAllFile='results_all.txt'
resultErrFile='result_err.txt'

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
		echo "downloading run as fastq.gz..." | tee -a $logFile
		./downloadRead.sh "$run" "$layout" "$mainOutDir" 2>>$logFile | tee -a $logFile
		#check if some error came out (in this case don't run kraken)
		newErrorFile=''
		if test -e "$NCBIErrorFile"
		then
			NCBIErrorFileName=`basename $NCBIErrorFile`
			newErrorFile=${currOutDir}/${NCBIErrorFileName}.xml
			echo "possible some errors while downloading!" | tee -a $logFile
			echo "check file" "$newErrorFile" | tee -a $logFile
			mv "$NCBIErrorFile" "$newErrorFile"
		else
			#analyseRead
			echo "analysing run with Kraken2..." | tee -a $logFile
			./runKraken.sh "$currOutDir" 2>>$logFile | tee -a $logFile
		fi
		#remove useless files
		echo "analysis done. Deleting fastq.gz file..." | tee -a $logFile
		cd $currOutDir
		#finds only: $run.fastq.gz or $run_1.fastq.gz or $run_2.fastq.gz
		ls | egrep "$run(_[1,2])?\.fastq\.gz" | xargs -d"\n" rm 2>>../../$logFile
		if test -z "../$newErrorFile"
		then
			cd 'krakenDB16_results'
			#finds only: $run.kraken
			ls | grep "$run.kraken$" | xargs -d"\n" rm 2>>../../../$logFile
			cd ..
			echo $run','$ERROR >>$resultErrFile
			echo $run','$ERROR >>$resultAllFile
		else
			echo $run','$YES >>$resultAllFile
		fi
		cd ../..
		#end
		echo -e "done:" $run "\n" | tee -a $logFile
	fi
	i=$[$i+1]
done

exit 0
