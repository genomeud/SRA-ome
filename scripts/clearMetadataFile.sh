set -x

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

    if ! test -z $hasSingleQuote
    while test $nOfSingleQuote -gt 0
    do
        if test $nOfSingleQuote -eq 1
        then
            #newLine=`echo $newLine | tr \' ' '`
            nOfSingleQuote=$(($nOfSingleQuote - 1))
        else
            #line has escapers so we assume delimiter is also in the mid of a field
            startOfLine=`echo $newLine | cut -d\' -f1`
            endOfLine=`echo $newLine | cut -d\' -f3-`
            problematicField=`echo $newLine | cut -d\' -f2 | tr -d "$delimiter"`
            newLine="$startOfLine"\'"$problematicField"\'"$endOfLine"
            nOfSingleQuote=$(($nOfSingleQuote - 2))
        fi
    done

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
