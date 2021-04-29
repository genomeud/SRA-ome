#set -x
nOfParamsNeeded=2

if test $# -ne $nOfParamsNeeded
then
    echo "usage: $0 <AllRunsFile.csv> <DoneIdx>"
    echo "example: $0 'metadata_filtered_small.csv' 19"
    exit 1
fi

script_dir=$HOME'/SRA/scripts'

AllRunsFile=$1      #metadata/metadata_filtered_small.csv
doneIdx=$2          #19: DONE = <OK | TO_DO | IGNORE | ERR>

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
AllRunsErrFile="$AllRunsPathWithNameFileNoExt"'_err'"$AllRunsFileExt"
AllRunsIgnoreFile="$AllRunsPathWithNameFileNoExt"'_ignore'"$AllRunsFileExt"
#clear output files
echo -n >$AllRunsDoneFile
echo -n >$AllRunsToDoFile
echo -n >$AllRunsErrFile
echo -n >$AllRunsIgnoreFile

i=1
n=`cat "$AllRunsFile" | wc -l`

while read ARF_line
do
    if test $(( $i % 500 )) -eq 0
    then
        echo "running... $i of $n"
    fi

    #NB: update also update script!!!
    #grep OK, test -z ==> NO,ERR in todo, OK in done
    #grep NO, test -n ==> NO in todo, OK,ERR in todo

    lineStatus=`echo "$ARF_line" | cut -d',' -f$[$doneIdx]`

    $script_dir/updateOneMetadataRow.sh "$ARF_line" "$lineStatus" $AllRunsToDoFile $AllRunsErrFile $AllRunsDoneFile $AllRunsIgnoreFile

    if test $? -ne 0
    then
        #row update failed ==> quit
        exit 2
    fi

    i=$[$i+1]

done <$AllRunsFile

exit 0