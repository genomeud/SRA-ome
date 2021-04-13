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

ls | egrep "$run(_[1,2])?\.fastq" | xargs -d"\n" rm
ls | grep "$run.kraken$" | xargs -d"\n" rm

exit 0