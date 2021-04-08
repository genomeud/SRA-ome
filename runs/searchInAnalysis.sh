#set -x

nOfParamsNeeded=3

if test $# -lt $nOfParamsNeeded
then
    echo -e "usage: $0 <folderSearchFiles> <field> <stringToSearch> [<folderOutFile>] \n"

    echo "output: search in <folderSearchFiles> recursive: files having extensions .kraken.report.txt"
    echo "          foreach file: search in the file <stringToSearch>, prints match to output file"
    echo -e "          output file: <folderSearchFiles>/string_searched_<stringToSearch>.txt \n"
    
    echo "example: $0 /path/to/folder/search 5 '2697049' /path/to/folder/output"
    echo "example: $0 /path/to/folder/search 6 'corona' /path/to/folder/output"

    exit 1
fi

folderSearch=$1
field=$2
stringToSearch=$3
folderOutFile=$folderSearch

if test $# -gt $nOfParamsNeeded
then
    folderOutFile=$4
fi

folderSearch=`echo $folderSearch | sed s:/$::`

reports=$folderSearch/'reports_temp.txt'
allLine_matches=$folderSearch/'allLine_matches_temp.txt'
echo -n >$allLine_matches
echo -n >$reports

reportExt='.kraken.report.txt'

find "$folderSearch" -name *$reportExt >$reports

outputFile=$folderOutFile/'searched_'$stringToSearch'_in_field_'$field'.txt'

i=1
n=`cat "$reports" | wc -l`

echo -n >$outputFile

while read reportFile
do
    run=`basename $reportFile | sed s/$reportExt//`
    
    #get match of a specific column:                cut $file -f"$field"    | grep -n "something"   ==> lineIdxs:"something"
    #get whole line that matched on that column:    head -n $lineIdxs $file  | tail -n 1             ==> "line...something...line"
    fieldMatched=`cat "$reportFile" | cut -f$field | grep -in "$stringToSearch"`
    echo "$fieldMatched" | cut -d':' -f1 >$allLine_matches

    if test -n "$fieldMatched"
    then
        echo $i of $n
        echo $run | tee -a $outputFile
        
        while read idxMatch
        do
            lineMatch=`head -n $idxMatch "$reportFile" | tail -n 1`
            echo -e "$lineMatch" | tee -a $outputFile

        done <"$allLine_matches"

        echo | tee -a $outputFile
    fi

    i=$[$i+1]
done <"$reports"

rm $reports
rm $allLine_matches

exit 0