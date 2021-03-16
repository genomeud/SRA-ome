#set -x

if test $# -ne 1
then
    echo "assumption on fields: SRAStudy=21, Run=1"
    echo "usage: $0 <file.csv>"
    exit 1
fi

CSV=$1

outputFile='SRAStudyTitle.txt'
logFile='SRAStudyTitle_log.txt'

#clear files
echo -n >$outputFile
echo -n >$logFile

i=1
len=`cat $CSV | wc -l`

while read line
do
    SRAStudy=`echo $line | cut -d',' -f21`
    Run=`echo $line | cut -d',' -f1`
    echo "line:" $i "of" $len, $Run, | tee -a $logFile
    studyTitle=`./getStudyInfo.sh $SRAStudy` 
    echo -e $studyTitle "\n" | tee -a $logFile
    echo $studyTitle >>$outputFile
    i=$[$i+1]

done <$CSV