#set -x

if test $# -lt 1
then
    echo "assumption on fields: SRAStudy=21, Run=1"
    echo "usage: $0 <inputfile>"
    exit 1
fi

inputfile=$1
delimiter='\t'

if test $# -gt 1
then
    delimiter="$2"
fi

inputfile=$1

outputFile='SRAStudyTitle.txt'
logFile='SRAStudyTitle_log.txt'

#clear files
echo -n >$outputFile
echo -n >$logFile

i=1
len=`cat "$inputfile" | wc -l`

while read line
do
    SRAStudy=`echo "$line" | cut -f21`
    Run=`echo "$line" | cut -f1`
    echo "line:" "$i" "of" "$len", run: "$Run", study: "$SRAStudy" | tee -a $logFile
    studyTitle=`./getStudyInfo.sh $SRAStudy` 
    echo -e "$studyTitle" "\n" | tee -a $logFile
    echo "$studyTitle" >>$outputFile
    i=$[$i+1]

done <"$inputfile"