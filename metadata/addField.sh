
inputFile=$1
allDataFile=$2
keyField=$3
fieldToAdd=$4
separator=','
outputFile=${inputFile}_new

echo -n >$outputFile

while read line
do
    key=`echo $line | cut -d$separator -f$keyField`
    toAdd=`cat $allDataFile | grep $key | cut -d$separator -f$4`
    echo ${line}${separator}${toAdd} >>$outputFile
done <$inputFile

mv $inputFile ${inputFile}_backup
mv $outputFile $inputFile