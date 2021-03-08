#set -x
nOfParamsNeeded=1
if test $# -lt $nOfParamsNeeded
then
    echo "usage: $0 <runID> [default=SINGLE, PAIRED]"
    exit 1
fi

layout='SINGLE'
layoutOption=''
if test $# -gt $nOfParamsNeeded
then
    layout=$2
    if test $layout = 'PAIRED'
    then
        layoutOption='--split-files'
    fi
fi

runID=$1

dir="${runID}"
mkdir $dir
cd $dir

command="fastq-dump $layoutOption --gzip $runID"
echo $command
echo `$command`

exit 0
