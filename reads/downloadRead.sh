#set -x
nOfParamsNeeded=1
if test $# -lt $nOfParamsNeeded
then
    echo "usage: $0 <experimentID>"
    exit 1
fi

experimentID=$1

dir="${experimentID}.kraken.reads"
mkdir $dir
cd $dir

command="fastq-dump $experimentID"
echo $command
echo `$command`

exit 0
