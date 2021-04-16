#set -x
nOfParamsNeeded=7

if test $# -ne $nOfParamsNeeded
then
    echo "usage: $0 <AllRunsFile.csv> <ARF_filterColumnIdx> <ARF_columnValueIdx> <RunsToUpdateFile.csv> <RTUF_filterColumnIdx> <RTUF_columnValueIdx> <updatesLog.txt>"
    echo "example: $0 'metadata_filtered_small.csv' 8 19 'results_all.csv' 1 2 'updatesLog.txt'"
    exit 1
fi

AllRunsFile=$1           #metadata/metadata_filtered_small.csv
ARF_filterColumnIdx=$2   #8:  RUN
ARF_columnValueIdx=$3    #19: DONE = <OK | NO | ERR>

RunsToUpdateFile=$4      #yyyy_mm_gg_analysis/results_all.csv
RTUF_filterColumnIdx=$5  #1: RUN
RTUF_columnValueIdx=$6   #2: DONE = <OK | NO | ERR>

#get file extension
AllRunsFileExt='.'`echo $AllRunsFile | sed 's/.*\.//'`
#get path/to/file without extension
AllRunsPathWithNameFileNoExt=`echo $AllRunsFile | sed 's/\.[^\.]*$//'`

updatesLog=$7
echo -n >$updatesLog

i=1
n=`cat "$AllRunsFile" | wc -l`

#temp file
AllRunsFileTemp="$AllRunsPathWithNameFileNoExt"'_temp'"$AllRunsFileExt"
#output files
AllRunsDoneFile="$AllRunsPathWithNameFileNoExt"'_done'"$AllRunsFileExt"
AllRunsToDoFile="$AllRunsPathWithNameFileNoExt"'_todo'"$AllRunsFileExt"
AllRunsBackUpFile="$AllRunsPathWithNameFileNoExt"'_backup'"$AllRunsFileExt"

echo -n >$AllRunsFileTemp
echo -n >$AllRunsDoneFile
echo -n >$AllRunsToDoFile
echo -n >$AllRunsBackUpFile

while read ARF_line
do
    ARF_filterColumn=`echo "$ARF_line" | cut -d',' -f$ARF_filterColumnIdx`
    RTUF_filterColumn=`cat "$RunsToUpdateFile" | cut -d',' -f$RTUF_filterColumnIdx | grep -n "$ARF_filterColumn"`
    ARF_newLine=''

    if test $(( $i % 500 )) -eq 0
    then
        echo "running... $i of $n"
    fi
    
    if test -z "$RTUF_filterColumn"
    then
        #this line has not changed, print it as original
        #echo NOT_UPDATE
        ARF_newLine=`echo $ARF_line`
        echo "$ARF_newLine">>$AllRunsFileTemp
    else
        #this line has changed, update column requested
        echo -e "\n"'----------------------UPDATE-----------------------------------'
        echo "$i of $n: $ARF_filterColumn"
        RTUF_lineIdx=`echo "$RTUF_filterColumn" | cut -d':' -f1`
        RTUF_line=`cat "$RunsToUpdateFile" | head -n "$RTUF_lineIdx" | tail -n 1`
        #fields before column to update
        ARF_lineLeft=`echo "$ARF_line" | cut -d',' -f1-$[$ARF_columnValueIdx-1]`
        #field to update
        RTUF_columnNewValue=`echo "$RTUF_line" | cut -d',' -f$RTUF_columnValueIdx`
        #field after column to update
        ARF_lineRight=`echo "$ARF_line" | cut -d',' -f$[$ARF_columnValueIdx+1]-`

        #field after column to update
        if test -n "$ARF_lineLeft"
        then
            #if not first field attach left part
            ARF_newLine="$ARF_lineLeft"','
        fi
        ARF_newLine="$ARF_newLine""$RTUF_columnNewValue"
        if test -n "$ARF_lineRight"
        then
            #if not last field attach right part
            ARF_newLine="$ARF_newLine"','"$ARF_lineRight"
        fi

        #print update done
        ARF_columnOldValue=`echo "$ARF_line" | cut -d',' -f$ARF_columnValueIdx`
        echo -e "$ARF_filterColumn"':' "$ARF_columnOldValue"' -> '"$RTUF_columnNewValue" | tee -a $updatesLog
        #update line to new file
        echo "$ARF_newLine" >>$AllRunsFileTemp
    fi

    isLineDone=`echo "$ARF_newLine" | cut -d',' -f$[$ARF_columnValueIdx] | grep 'OK'`
    if test -z $isLineDone
    then
        #line has not been done already with success
        #put to todo file
        echo "$ARF_newLine">>$AllRunsToDoFile
    else
        #line has been done already with success
        #put to ok file
        echo "$ARF_newLine">>$AllRunsDoneFile
    fi

    i=$[$i+1]

done <$AllRunsFile

mv $AllRunsFile $AllRunsBackUpFile
mv $AllRunsFileTemp $AllRunsFile

exit 0