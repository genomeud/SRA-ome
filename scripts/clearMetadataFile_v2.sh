#set -x

inputFile=$1
delimiter="$2"

if test $# -ne 2
then
    echo "usage: $0 <inputFile> <delimiter>"
fi

cleanFile='clean_temp'
echo -n >$cleanFile

cp $inputFile ${inputFile}_backup

i=1
n=`cat $inputFile | wc -l`

while read line
do
    #change " to '
    convertDoubleQuoteToSingle=`echo "$line" | tr \" \'`
    hasSingleQuote=`echo "$convertDoubleQuoteToSingle" | grep \'`
    nOfSingleQuote=`echo "$convertDoubleQuoteToSingle" | sed s/[^\']//g | wc -c`
    nOfSingleQuote=$(($nOfSingleQuote - 1))

    newLine=$convertDoubleQuoteToSingle

    if ! test -z "$hasSingleQuote"
    then
        nOfRepetitions=$(($nOfSingleQuote - 1))
        for ((j=1; j<=$nOfRepetitions; j++))
        do
            startOfLineIdx=$j
            problematicFieldIdx=$(($j + 1))
            endOfLineIdx=$(($j + 2))

            startOfLine=`echo $newLine | cut -d\' -f1-$startOfLineIdx`
            endOfLine=`echo $newLine | cut -d\' -f$endOfLineIdx-`
            problematicField=`echo $newLine | cut -d\' -f$problematicFieldIdx`
            hasDelimiters=`echo $problematicField | grep ','`
            if ! test -z "$hasDelimiters"
            then
                nOfDelimiters=`echo $problematicField | sed s/[^',']//g | wc -c`
                nOfDelimiters=$(($nOfDelimiters - 1))
                if test $nOfDelimiters -eq 1
                then
                    problematicField=`echo $problematicField | tr "$delimiter" '.'`
                fi
            fi
            newLine="$startOfLine"
            if ! test -z "$problematicField"
            then
                newLine=$newLine\'"$problematicField"
            fi 
            if ! test -z "$endOfLine"
            then
                newLine=$newLine\'"$endOfLine"
            fi 
            
        done
    fi
    

    #sleep 5

    echo "$newLine">>$cleanFile

    divisor=500
    remainder=$(($i%$divisor))
    if test $remainder -eq 0
    then
        echo "$i of $n"
    fi
    i=$[$i+1]

done <$inputFile

cp $cleanFile $inputFile
rm $cleanFile
