#set -x
nOfParamsNeeded=2

if test $# -lt $nOfParamsNeeded
then
    echo "usage: $0 <runID> <directory> [delFastq = <[true] | false>, delKraken = <[true] | false>]"
    exit 1
fi

run=$1
dir=$2

delFastq=true
delKraken=true

if ! test -d $dir
then
    echo "error: directory $dir not accessible or not existing or not a directory"
    exit 2
fi

if test $# -gt $nOfParamsNeeded
then
    delFastq=$3
    delKraken=$4
fi

cd $dir

ok=0

list='ls'
removeFiles='xargs -d\n rm'

fastqStatus=0
if test $delFastq = true
then
    #.fastq files
    #ls | grep "$run.kraken$" | xargs -d"\n" r
    findFastq='egrep '"$run(_[1,2])?\.fastq"
    #echo $list '|' $findFastq '|' $removeFiles
    $list | $findFastq | $removeFiles
    fastqStatus=$?
fi

krakenStatus=0
if test $delKraken = true
then
    #.kraken files
    #ls | egrep "$run(_[1,2])?\.fastq" | xargs -d"\n" rm
    findKraken='grep '"$run.kraken$"
    #echo $list '|' $findKraken '|' $removeFiles
    $list | $findKraken | $removeFiles
    krakenStatus=$?
fi

#delete temp download files
#large files, fasterqdump autodeletes them unless there is error
#we want to delete them in any case
find . -type d -name "fasterq.tmp.*" -exec rm -rf {} \; 2>>/dev/null

ok=0
if test $fastqStatus -ne 0
then
    ok=$fastqStatus
elif test $krakenStatus -ne 0
then
    ok=$krakenStatus
fi

exit $ok