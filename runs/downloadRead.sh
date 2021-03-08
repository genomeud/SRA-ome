#set -x
nOfParamsNeeded=1
if test $# -lt $nOfParamsNeeded
then
    echo "usage: $0 <runID>"
    exit 1
fi

runID=$1

dir="${runID}"
mkdir $dir
cd $dir

command="fastq-dump --gzip $runID"
echo $command
echo `$command`

exit 0
