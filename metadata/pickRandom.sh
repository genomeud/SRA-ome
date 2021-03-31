#set -x

if test $# -lt 6
then
    echo "assumption: file char separator \',\'"
    echo "usage: $0 <inputFile> <groupingFieldIdx> <valueFieldIdx:<1> <2> <3>> <doneFieldIdx> [<maxSizeMB>]"
    exit 1
fi

inputFile=$1
groupingFieldIdx=$2     #scientific name
valueFieldIdx1=$3       #run
valueFieldIdx2=$4       #layout
valueFieldIdx3=$5       #size [MB]
doneFieldIdx=$6         #done == NO
maxSizeMB=5000          #size [MB]

if test $# -gt 6
then
    maxSizeMB = $7
fi

#temp files
tmpCountUniqGroupingFile=tmpCountUniqGroupingFile.txt
tmpAllRunsSorted=tmpAllRunsSorted.txt
tmpPossibleRunsSorted=tmpPossibleRunsSorted.txt
echo -n >$tmpCountUniqGroupingFile
echo -n >$tmpAllRunsSorted
echo -n >$tmpPossibleRunsSorted

#output and log files
outputFile=runs_list.csv
logFile=runs_list_log.txt
echo -n >$outputFile
echo -n >$logFile

delimiter=','

cat "$inputFile" | sort -t$delimiter -k$groupingFieldIdx >$tmpAllRunsSorted

#remove lines not to pick random
while read line
do
    lineIsOk='TRUE'
    sizeMB=`echo "$line" | cut -d$delimiter -f$valueFieldIdx3`
    isDone=`echo "$line" | cut -d$delimiter -f$doneFieldIdx`
    if test $sizeMB -gt $maxSizeMB
    then
        #discard: run is too big
        lineIsOk=FALSE
    fi
    if ! test $isDone = 'NO'
    then
        #discard: run has already be done
        #DISCARD if (done != NO) ==> accept only 'NO' values
        #DISCARD if (done != OK) ==> accept 'NO' or 'ERR' values
        lineIsOk=FALSE
    fi
    if test $lineIsOk = 'TRUE'
    then
        echo "$line">>$tmpPossibleRunsSorted
    fi
done <$tmpAllRunsSorted

#if RAND_MAX > n can't run
RAND_MAX=32767
n=`cat $tmpPossibleRunsSorted | wc -l`
if test $RAND_MAX -lt $n
then
    echo "file is too large"
    exit 2
fi

cat "$tmpPossibleRunsSorted" | cut -d$delimiter -f$groupingFieldIdx | uniq -c | sed s/^' '*// | sed s/[^' 'a-zA-Z0-9]/?/g >$tmpCountUniqGroupingFile

#sleep 100

i=1
while (( $i <= $n ))
do
    grouping=`cat $tmpPossibleRunsSorted | head -n $i | tail -n 1 | cut -d$delimiter -f$groupingFieldIdx | sed s/[^' 'a-zA-Z0-9]/?/g`
    nOfEqualLines=`cat $tmpCountUniqGroupingFile | grep "^[0-9]* ""${grouping}""$" | cut -d ' ' -f1`

    randomLine=$(( $(( $RANDOM % $nOfEqualLines )) + $i ))
    value=`cat $tmpPossibleRunsSorted | head -n $randomLine | tail -n 1 | cut -d$delimiter -f$valueFieldIdx1,$valueFieldIdx2,$valueFieldIdx3`

    echo "grouping lines:" "$grouping" | tee -a $logFile
    echo "first line:" $i", number of equal lines:" "$nOfEqualLines" | tee -a $logFile
    echo "random line:" "$randomLine" | tee -a $logFile
    echo -e "corresponding value:" "$value" "\n" | tee -a $logFile

    echo $value >>$outputFile

    i=$[$i+$nOfEqualLines]
done

rm $tmpCountUniqGroupingFile
rm $tmpPossibleRunsSorted
rm $tmpAllRunsSorted

exit 0