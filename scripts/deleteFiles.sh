#set -x
nOfParamsNeeded=1

if test $# -lt $nOfParamsNeeded
then
    echo "usage: $0 <runID> <directory>"
    exit 1
fi

run=$1
dir=$2

if ! test -d $dir
then
    echo "error: directory not accessible or not existing or not a directory"
    exit 2
fi

cd $dir

ok=0

list='ls'
removeFiles='xargs -d\n rm'

#.fastq files
#ls | grep "$run.kraken$" | xargs -d"\n" r
findFastq='egrep '"$run(_[1,2])?\.fastq"
echo $list '|' $findFastq '|' $removeFiles
$list | $findFastq | $removeFiles

ok=$?

#.kraken files
#ls | egrep "$run(_[1,2])?\.fastq" | xargs -d"\n" rm
findKraken='grep '"$run.kraken$"
echo $list '|' $findKraken '|' $removeFiles
$list | $findKraken | $removeFiles

if test $ok -eq 0
then
    ok=$?
fi 

exit $ok