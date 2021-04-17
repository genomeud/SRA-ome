#set -x
nOfParamsNeeded=2

if test $# -ne $nOfParamsNeeded
then
    echo "usage: $0 <AllRunsFile.csv> <DoneIdx>"
    echo "example: $0 'metadata_filtered_small.csv' 19"
    exit 1
fi

AllRunsFile=$1      #metadata/metadata_filtered_small.csv
doneIdx=$2          #19: DONE = <OK | NO | ERR>

#get file extension
AllRunsFileExt='.'`echo $AllRunsFile | sed 's/.*\.//'`
#get path/to/file without extension
AllRunsPathWithNameFileNoExt=`echo $AllRunsFile | sed 's/\.[^\.]*$//'`

#file useless if update has failed, delete them
AllRunsFileTemp="$AllRunsPathWithNameFileNoExt"'_temp'"$AllRunsFileExt"
AllRunsBackUpFile="$AllRunsPathWithNameFileNoExt"'_backup'"$AllRunsFileExt"
rm $AllRunsFileTemp 2>/dev/null
rm $AllRunsBackUpFile 2>/dev/null

#output files
AllRunsDoneFile="$AllRunsPathWithNameFileNoExt"'_done'"$AllRunsFileExt"
AllRunsToDoFile="$AllRunsPathWithNameFileNoExt"'_todo'"$AllRunsFileExt"
#clear output files
echo -n >$AllRunsDoneFile
echo -n >$AllRunsToDoFile

i=1
n=`cat "$AllRunsFile" | wc -l`

while read ARF_line
do
    if test $(( $i % 500 )) -eq 0
    then
        echo "running... $i of $n"
    fi

    isLineDone=`echo "$ARF_line" | cut -d',' -f$[$doneIdx] | grep 'OK'`
    
    if test -z $isLineDone
    then
        #line has not been done already with success
        #put to todo file
        echo "$ARF_line">>$AllRunsToDoFile
    else
        #line has been done already with success
        #put to ok file
        echo "$ARF_line">>$AllRunsDoneFile
    fi

    i=$[$i+1]

done <$AllRunsFile

exit 0