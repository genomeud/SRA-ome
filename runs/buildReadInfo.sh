#set -x
nOfParamsNeeded=1
if test $# -lt $nOfParamsNeeded
then
    echo "usage: $0 <runID> [<outputFile>]"
    exit 1
fi

runID=$1
outputFile='run.info'
if test $# -gt $nOfParamsNeeded
then
    outputFile=$2
fi

info=`esearch -db sra -query $runID | efetch -format runinfo`

i=1
file=''
temp1='temp1'
temp2='temp2'
while read line
do
    value=`echo $line | sed s/,/\n/g`
    echo "line: $i"
    echo $value
    echo $value >$temp2
    if test $i -gt 1
    then
        paste -d: $temp1 $temp2 >$outputFile
    else
        echo $value >$outputFile
    fi
    cat $outputFile >$temp1
    i=$[$i+1]
done < <(echo "$info")

echo $outputFile