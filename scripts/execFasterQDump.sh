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

outputDir=$PWD

if test $# -gt $nOfParamsNeeded
then
    outputDir=$3
    mkdir $outputDir 2>/dev/null
    cd $outputDir
fi

command="fasterq-dump $layoutOption -O $outputDir $runID"
echo $command
$command
#echo "exit status fasterq: " $?
exit #not necessary, redundant: $?
