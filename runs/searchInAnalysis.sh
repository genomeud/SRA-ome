#set -x
#!/bin/zsh
folderSearch=$1
stringToSearch=$2

reports='reports.txt'
find "$folderSearch" -name *'.kraken.report.txt' >$reports

output='searchedFrom_'$folderSearch'.txt'

i=1
n=`cat "$reports" | wc -l`

echo -n >$output

while read reportFile
do
    run=`basename $reportFile | sed s/.kraken.report.txt//`
    match=`cat $reportFile | grep -i $stringToSearch`
    if test -n "$match"
    then
        echo $i di $n': '$run
        echo "$reportFile" | tee -a $output
        echo -e "$match""\n" | tee -a $output
    fi


    i=$[$i+1]
done <"$reports"

