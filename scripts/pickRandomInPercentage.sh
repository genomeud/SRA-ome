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
mkdir $outputDir 2>/dev/null
#doneFieldIdx=$6        #done == NO
MAX_SIZE_MB=10000       #size [MB]
#for example: 0,5 ==> 0,5 / 100 = 0,005
percAsNumerator=3     #0 <= percAsNumerator <= 100

if test $# -gt $nOfParamsNeeded
then
    MAX_SIZE_MB=$7
fi

#cd $outputDir

#temp files
tmpCountUniqGroupingFile=$outputDir/tmpCountUniqGroupingFile.txt
tmpAllRunsSorted=$outputDir/tmpAllRunsSorted.txt
tmpPossibleRunsSorted=$outputDir/tmpPossibleRunsSorted.txt
echo -n >$tmpCountUniqGroupingFile
echo -n >$tmpAllRunsSorted
echo -n >$tmpPossibleRunsSorted

#output and log files
outputFile=$outputDir/'runs_list.csv'
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

#ALWAYS TRUE:
# i <= n + nOfEqualLines (NB: nOfEqualLines of last group, then exit while)

i=1 #current row

#boolean constants
FALSE=0
TRUE=1

while (( $i <= $n ))
do
    #first repetition of i-group
    #calculate values needed for all repetitions:
        #grouping, nOfEqualLines, repetitions
        
    #value of i-th group
    grouping=`cat $tmpPossibleRunsSorted \
    | head -n $i \
    | tail -n 1 \
    | cut -d$delimiter -f$groupingFieldIdx \
    | sed s/[^' 'a-zA-Z0-9]/'?'/g`
    
    #number of equal lines of i-th group
    nOfEqualLines=`cat $tmpCountUniqGroupingFile \
    | grep "^[0-9]* ""${grouping}""$" \
    | cut -d ' ' -f1`

    #number of repetitions that will be done for i-th group
    #repetitions = number of random lines that will be printed for i-th group
    #repetitions = 1 + ( nOfEqualLines % percentage )
    #repetitions=$(( $nOfEqualLines * $percAsNumerator / 100 + 1 ))
    repetitions_float=`echo "$nOfEqualLines $percAsNumerator" | awk '{ print ($1 * $2 / 100 + 1); }'`
    repetitions=${repetitions_float%.*}

    lastLine=$[$i + $nOfEqualLines - 1]
    echo "grouping lines: $grouping" | tee -a $logFile
    echo "first line: $i, last line: $lastLine, output expected: $repetitions" | tee -a $logFile

    #empty array
    indexesAlreadyPicked=()

    #k-th repetition of i-th group
    k=0

    #tentative of k-repetition of i-th row
    #always true: j <= MAX_NUM_OF_TENTATIVE 
        #NB: if (j == MAX_NUM_OF_TENTATIVE) ==> randIdx not found
    j=0

    while (( $k<$repetitions ))
    do

        randomIdx=$(( $(( $RANDOM % $nOfEqualLines )) + $i ))
        indexesAlreadyPicked[$k]=$randomIdx
        randomLine=`cat $tmpPossibleRunsSorted | head -n $randomIdx | tail -n 1`

        isIndexOK=$TRUE
        
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

        #check if size is less equal of maximum size
        sizeMB=`echo "$randomLine" | cut -d$delimiter -f$valueFieldIdx3`
        isIndexOK=$(($sizeMB <= $MAX_SIZE_MB))

        #if size is ok then check if index has not been already picked in the array
        h=0
        while [ \( "$h" -lt "$k" \) -a \( "$isIndexOK" -eq "$TRUE" \) ]
        do
            isIndexOK=$((${indexesAlreadyPicked[$h]} != $randomIdx))
            h=$[$h + 1]
        done

        if test $isIndexOK -eq $FALSE
        then
            if test $j -ge $MAX_NUM_OF_TENTATIVE
            then
                #CASE ONE: BAD
                #can't find a run not too large and not already picked, gonna skip this repetition
                echo "----- DIDN'T FIND A NOT TOO LARGE RUN, REPETITION SKIPPED --------" | tee -a $logFile
                indexesAlreadyPicked[$k]=-1
                k=$[$k+1]
            else
                #CASE TWO: MAYBE NOT BAD
                #try again on picking an index for this repetition
                j=$[$j+1]
            fi
        else
            #CASE THREE: GOOD
            #index found is ok, save it
            randomLineCutted=`echo $randomLine | cut -d$delimiter -f$valueFieldIdx1,$valueFieldIdx2,$valueFieldIdx3`
            echo -e "$randomIdx\t=>\t$randomLineCutted" | tee -a $logFile
            echo $randomLineCutted >>$outputFile
            k=$[$k+1]
        fi

    done
    
    found=0
    for ((k=0; k<$repetitions; k++ ))
    do
        #arr[i] = -1 ==> ERROR IN FINDING IDX
        if test ${indexesAlreadyPicked[$k]} -ne -1
        then
            found=$[$found+1]
        fi
    done

    indexesFoundPercentage=`echo "$found $repetitions" | awk '{ printf("%.4g", $1 / $2 * 100); }'`
    echo -e "indexes found: $indexesFoundPercentage%: $found of $repetitions\n" | tee -a $logFile
    unset indexesAlreadyPicked
    i=$[$i+$nOfEqualLines]


done

rm $tmpCountUniqGroupingFile
rm $tmpPossibleRunsSorted
rm $tmpAllRunsSorted

exit 0