#set -x
nOfParamsNeeded=6

if test $# -ne $nOfParamsNeeded
then
    echo "usage: $0 <AllRunsFile.csv> <ARF_filterColumnIdx> <ARF_columnOldValueIdx> <RunsToUpdateFile.csv> <RTUF_filterColumnIdx> <RTUF_columnNewValueIdx>"
    exit 1
fi

AllRunsFile=$1
ARF_filterColumnIdx=$2
ARF_columnOldValueIdx=$3

RunsToUpdateFile=$4
RTUF_filterColumnIdx=$5
RTUF_columnNewValueIdx=$6

cp "${AllRunsFile}" "${AllRunsFile}"_backup

i=1
n=`cat "$AllRunsFile" | wc -l`

outputFile="${AllRunsFile}"'_new.csv'
echo -n >$outputFile

while read ARF_line
do
    ARF_filterColumn=`echo "$ARF_line" | cut -d',' -f$ARF_filterColumnIdx`
    RTUF_filterColumn=`cat "$RunsToUpdateFile" | cut -d',' -f$RTUF_filterColumnIdx | grep -n "$ARF_filterColumn"`

    echo "$i of $n: $ARF_filterColumn"

    if test -z "$RTUF_filterColumn"
    then
        #this line has not changed, print it as original
        #echo NOT_UPDATE
        echo "$ARF_line">>$outputFile
    else
        #this line has changed, update column requested
        echo ----------------------UPDATE-----------------------------------
        RTUF_lineIdx=`echo "$RTUF_filterColumn" | cut -d':' -f1`
        RTUF_line=`cat "$RunsToUpdateFile" | head -n "$RTUF_lineIdx" | tail -n 1`

        #fields before column to update
        ARF_lineLeft=`echo "$ARF_line" | cut -d',' -f1-$[$ARF_columnOldValueIdx-1]`
        
        #field to update
        RTUF_columnNewValue=`echo "$RTUF_line" | cut -d',' -f$RTUF_columnNewValueIdx`

        #field after column to update
        ARF_lineRight=`echo "$ARF_line" | cut -d',' -f$[$ARF_columnOldValueIdx+1]-`

        ARF_newLine=''
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

        #update line to new file
        echo "$ARF_newLine" | tee -a $outputFile
        
    fi

    i=$[$i+1]

done <$AllRunsFile

cp $outputFile $AllRunsFile
rm $outputFile

exit 0