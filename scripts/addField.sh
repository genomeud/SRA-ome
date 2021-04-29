#set -x 

nOfParamsNeeded=4

if test $# -ne $nOfParamsNeeded
then
    echo "usage: $0 <inputFile> <keyField> <allDataFile> <fieldToAdd>"
    echo "example: $0 /path/to/runs_list.csv 1 $HOME/SRA/metadata/metadata_filtered_small.csv 14,17"
    exit 1
fi

inputFile=$1
keyField=$2
allDataFile=$3
fieldToAdd=$4

separator=','
outputFile=${inputFile}_new

echo -n >$outputFile

while read line
do
    key=`echo $line | cut -d$separator -f$keyField`
    toAdd=`cat $allDataFile | grep $key | cut -d$separator -f$fieldToAdd`
    echo ${line}${separator}${toAdd} >>$outputFile
done <$inputFile

mv $inputFile ${inputFile}_backup
mv $outputFile $inputFile

exit 0