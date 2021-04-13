#!/bin/zsh
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
    noDoubleQuote=`echo "$line" | tr \" \'`
    hasSingleQuote=`echo "$noDoubleQuote" | grep \'`

    if test -z "$hasSingleQuote"
    then
        #line has no escapers so we assume delimiter is only is the right places
        echo "$line">>$cleanFile
    else
        #line has escapers so we assume delimiter is also in the mid of a field
        leftLine=`echo $hasSingleQuote | cut -d\' -f1`
        rightLine=`echo $hasSingleQuote | cut -d\' -f3`
        problematicField=`echo $hasSingleQuote | cut -d\' -f2 | tr -d "$delimiter"`
        echo "$leftLine""$problematicField""$rightLine" | tr -d \' >>$cleanFile
    fi

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
