#set -x

nOfParamsNeeded=6

if test $# -lt $nOfParamsNeeded
then
    echo "assumption: file char separator ','"
    echo "usage: $0 <inputFile> <groupingFieldIdx> <valueFieldIdx:<run> <layout> <size>> <outputDir> [<MAX_SIZE_MB>]"
    echo "example: $0 metadata_filtered_small_todo.csv 9 8 14 17 /path/to/outputDir"
    exit 1
fi

inputFile=$1
groupingFieldIdx=$2     #scientific name
valueFieldIdx1=$3       #run
valueFieldIdx2=$4       #layout
valueFieldIdx3=$5       #size [MB]
outputDir=`echo "$6" | sed s:/$::`
mkdir $outputDir 2>>/dev/null
#doneFieldIdx=$6        #done == NO
MAX_SIZE_MB=5000        #size [MB]

if test $# -gt $nOfParamsNeeded
then
    MAX_SIZE_MB=$7
fi

#temp files
tmpCountUniqGroupingFile=tmpCountUniqGroupingFile.txt
tmpAllRunsSorted=tmpAllRunsSorted.txt
tmpPossibleRunsSorted=tmpPossibleRunsSorted.txt
echo -n >$tmpCountUniqGroupingFile
echo -n >$tmpAllRunsSorted
echo -n >$tmpPossibleRunsSorted

#output and log files
outputFile=$outputDir'/runs_list.csv'
logFile=$outputDir/'runs_list_log.txt'
echo -n >$outputFile
echo -n >$logFile

delimiter=','

#run this one for implementation of removing unacceptable lines
#cat "$inputFile" | sort -t$delimiter -k$groupingFieldIdx >$tmpAllRunsSorted

#run this one for implementation of trying again if line is unacceptable
MAX_NUM_OF_TENTATIVE=10
cat "$inputFile" | sort -t$delimiter -k$groupingFieldIdx >$tmpPossibleRunsSorted

#OTHER IMPLEMENTATION - START
#remove lines not to pick random
#while read line
#do
#    lineIsOk='TRUE'
#    sizeMB=`echo "$line" | cut -d$delimiter -f$valueFieldIdx3`
#    isDone=`echo "$line" | cut -d$delimiter -f$doneFieldIdx`
#    if test $sizeMB -gt $MAX_SIZE_MB
#    then
#        #discard: run is too big
#        lineIsOk=FALSE
#    fi
#    if ! test $isDone = 'NO'
#    then
#        #discard: run has already be done
#        #DISCARD if (done != NO) ==> accept only 'NO' values
#        #DISCARD if (done != OK) ==> accept 'NO' or 'ERR' values
#        lineIsOk=FALSE
#    fi
#    if test $lineIsOk = 'TRUE'
#    then
#        echo "$line">>$tmpPossibleRunsSorted
#    fi
#done <$tmpAllRunsSorted
#OTHER IMPLEMENTATION - END

#if RAND_MAX > n can't run
RAND_MAX=32767
n=`cat $tmpPossibleRunsSorted | wc -l`
if test $RAND_MAX -lt $n
then
    echo "file is too large"
    exit 2
fi

cat "$tmpPossibleRunsSorted" \
| cut -d$delimiter -f$groupingFieldIdx \
| uniq -c \
| sed s/^' '*// \
| sed s/[^' 'a-zA-Z0-9]/'?'/g \
>$tmpCountUniqGroupingFile

#sleep 100

i=1 #current row
j=1 #current tentative of i-row
while (( $i <= $n ))
do
    grouping=`cat $tmpPossibleRunsSorted \
    | head -n $i \
    | tail -n 1 \
    | cut -d$delimiter -f$groupingFieldIdx \
    | sed s/[^' 'a-zA-Z0-9]/'?'/g`
    
    nOfEqualLines=`cat $tmpCountUniqGroupingFile \
    | grep "^[0-9]* ""${grouping}""$" \
    | cut -d ' ' -f1`

    randomIdx=$(( $(( $RANDOM % $nOfEqualLines )) + $i ))
    randomLine=`cat $tmpPossibleRunsSorted | head -n $randomIdx | tail -n 1`
    
    #check if run is not too large in MB
    #if it is pick again a random line (till when it is ok)
    #pros:
        #implementation is efficient if most of runs (foreach grouping value) are under the max size
    #cons:
        #not potentially infinite: after MAX_NUM_OF_TENTATIVE goes to next one
        #is not guaranteed to find a small run even if it exists
            #20 large, 1 small ==> maybe after MAX_NUM_OF_TENTATIVE skip without finding the small
    
    #so:
    #if many runs are big:
        # - increase MAX_SIZE_MB
        # - change impl.: remove all runs too large an pick random only from acceptable ones
            #(all the code commented in lines between OTHER IMPLEMENTATION - START/END)
                #guarantees to end
                #pick random just one time for each grouping
                #commented because is very faster to pick random again (sometimes)
                #instead of read all the file and deleting unacceptable runs (if few)

    sizeMB=`echo "$randomLine" | cut -d$delimiter -f$valueFieldIdx3`
    if test $sizeMB -gt $MAX_SIZE_MB
    then
        #echo -n 'j=:'$j',' | tee -a $logFile
        if test $j -lt $MAX_NUM_OF_TENTATIVE
        then
            #try again on find a not too large run
            j=$[$j+1]
        else

            #can't find a not too large run, gonna skip this group
            echo -e "grouping lines:" "$grouping" | tee -a $logFile
            echo "first line:" $i", number of equal lines:" "$nOfEqualLines" | tee -a $logFile
            echo -e "----- DIDN'T FIND A NOT TOO LARGE RUN, GROUP SKIPPED --------\n" | tee -a $logFile
            i=$[$i+$nOfEqualLines]
            j=1
        fi
    else
        randomLineCutted=`echo $randomLine | cut -d$delimiter -f$valueFieldIdx1,$valueFieldIdx2,$valueFieldIdx3`

        echo "grouping lines:" "$grouping" | tee -a $logFile
        echo "first line:" $i", number of equal lines:" "$nOfEqualLines" | tee -a $logFile
        echo "random line:" "$randomIdx" | tee -a $logFile
        echo -e "corresponding value:" "$randomLineCutted" "\n" | tee -a $logFile
        echo $randomLineCutted >>$outputFile

        i=$[$i+$nOfEqualLines]
        j=1

    fi
done

rm $tmpCountUniqGroupingFile
rm $tmpPossibleRunsSorted
rm $tmpAllRunsSorted

exit 0