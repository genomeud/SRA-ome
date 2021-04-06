#set -x
nOfParamsNeeded=2
if test $# -lt $nOfParamsNeeded
then
    echo "usage: $0 <runID> <SINGLE | PAIRED> <[path/to/outputDir]>"
    exit 1
fi

runID=$1
layout=$2
layoutOption=''
if test "$layout" = 'PAIRED'
then
    layoutOption='--split-files'
fi

if test $# -gt $nOfParamsNeeded
then
    outputDir=$3
    cd $outputDir
fi

dir="$runID"
mkdir $dir 2>>/dev/null
cd $dir

command="fasterq-dump $layoutOption --include-technical $runID"
echo $command
$command
#echo $?
exit #not necessary, redundant: $?
