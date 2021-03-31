#set -x
#!/bin/zsh

nOfParamsNeeded=2

if test $# -ne $nOfParamsNeeded
then
    echo -e "usage: $0 <folderSearchFiles> <stringToSearch>\n"
    echo "output: search in <folderSearchFiles> recursive: files having extensions .kraken.report.txt"
    echo "          foreach file: search in the file <stringToSearch>, prints match to output file"
    echo "          output file: <folderSearchFiles>/string_searched_<stringToSearch>.txt"
    exit 1
fi

folderSearch=$1
stringToSearch=$2

folderSearch=`echo $folderSearch | sed s:/$::`

reports=$folderSearch/'reports.txt'
reportExt='.kraken.report.txt'

find "$folderSearch" -name *$reportExt >$reports

outputFile=$folderSearch/'string_searched_'$stringToSearch'.txt'

i=1
n=`cat "$reports" | wc -l`

echo -n >$outputFile

while read reportFile
do
    run=`basename $reportFile | sed s/$reportExt//`
    match=`cat $reportFile | grep -i $stringToSearch`
    if test -n "$match"
    then
        echo $i of $n
        echo $run | tee -a $outputFile
        echo -e "$match""\n" | tee -a $outputFile
    fi

    i=$[$i+1]
done <"$reports"

rm $reports

exit 0