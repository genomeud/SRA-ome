#set -x
nOfParamsNeeded=1
if test $# -lt $nOfParamsNeeded
then
    echo "NB: if outputDir =/= runID fastq will create a subfolder named <runID>"
    echo "usage: $0 <runID> [default=SINGLE, PAIRED] [path/to/outputDir]"
    exit 1
fi

layout='SINGLE'
layoutOption=''
if test $# -gt $nOfParamsNeeded
then
    layout=$2
    if test "$layout" = 'PAIRED'
    then
        layoutOption='--split-files'
    fi
    outputDir=$3
    cd $outputDir
fi

runID=$1

dir="$runID"
mkdir $dir 2>>/dev/null
cd $dir

command="fasterq-dump $layoutOption --include-technical $runID"
echo $command
$command
#echo $?
exit #not necessary, redundant: $?
