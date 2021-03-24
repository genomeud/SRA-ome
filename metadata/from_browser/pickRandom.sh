#set -x

if test $# -lt 3
then
    echo "assumption: file char separator \',\'"
    echo "usage: $0 <inputFile> <groupingFieldIdx> [list <valueFieldIdx1> <valueFieldIdx2>]"
    exit 1
fi

inputFile=$1
groupingFieldIdx=$2
valueFieldIdx1=$3
valueFieldIdx2=$4

tmpCountUniqGroupingFile=tmpCountUniqGroupingFile.txt
tmpInputFile=tmpInputFile.txt

outputFile=randomOutput.txt
logFile=randomLog.txt

echo -n >$outputFile
echo -n >$logFile

RAND_MAX=32767
n=`cat $inputFile | wc -l`

if test $RAND_MAX -lt $n
then
    echo "file is too large"
    exit 2
fi

delimiter=','

cat "$inputFile" | sort -t$delimiter -k$groupingFieldIdx >$tmpInputFile
cat "$tmpInputFile" | cut -d$delimiter -f$groupingFieldIdx | uniq -c | sed s/^' '*// | sed s/[^' 'a-zA-Z0-9]/?/g >$tmpCountUniqGroupingFile

i=1
while (( $i <= $n ))
do
    grouping=`cat $tmpInputFile | head -n $i | tail -n 1 | cut -d$delimiter -f$groupingFieldIdx | sed s/[^' 'a-zA-Z0-9]/?/g`
    nOfEqualLines=`cat $tmpCountUniqGroupingFile | grep "^[0-9]* ""${grouping}""$" | cut -d ' ' -f1`

    randomLine=$(( $(( $RANDOM % $nOfEqualLines )) + $i ))
    value=`cat $tmpInputFile | head -n $randomLine | tail -n 1 | cut -d$delimiter -f$valueFieldIdx1,$valueFieldIdx2`

    echo "grouping lines:" "$grouping" | tee -a $logFile
    echo "first line:" $i", number of equal lines:" "$nOfEqualLines" | tee -a $logFile
    echo "random line:" "$randomLine" | tee -a $logFile
    echo -e "corresponding value:" "$value" "\n" | tee -a $logFile

    echo $value >>$outputFile

    i=$[$i+$nOfEqualLines]
done

rm $tmpCountUniqGroupingFile
rm $tmpInputFile

exit 0