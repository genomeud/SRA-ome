#set -x
nOfParamsNeeded=1
if test $# -lt $nOfParamsNeeded
then
    echo "usage: $0 <runID> [</path/to/outputFile>]"
    exit 1
fi

runID=$1
outputFile='run.info'
if test $# -gt $nOfParamsNeeded
then
    outputFile=$2
fi
echo $outputFile

info=`esearch -db sra -query $runID | efetch -format runinfo`

i=1
touch temp
touch current
while read line
do
    value=`echo $line | tr ',' '\n' >current`
    if test $i -gt 1
    then
        paste temp current >$outputFile
    else
        cp current $outputFile
    fi
    cp $outputFile temp
    i=$[$i+1]
done < <(echo "$info")

rm temp
rm current

echo "infos:"
cat $outputFile