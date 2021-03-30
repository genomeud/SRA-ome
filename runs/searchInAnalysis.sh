set -x
#!/bin/zsh
folderSearch=$1
stringToSearch=$2

reports='reports.txt'
reportExt='.kraken.report.txt'
find "$folderSearch" -name *$reportExt >$reports

folderSearch=`echo $folderSearch | sed s:/$::`
output='searchedFrom_'$folderSearch'.txt'

i=1
n=`cat "$reports" | wc -l`

echo -n >$output

while read reportFile
do
    run=`basename $reportFile | sed s/$reportExt//`
    match=`cat $reportFile | grep -i $stringToSearch`
    if test -n "$match"
    then
        echo $i of $n
        echo $run | tee -a $output
        echo -e "$match""\n" | tee -a $output
    fi

    i=$[$i+1]
done <"$reports"

