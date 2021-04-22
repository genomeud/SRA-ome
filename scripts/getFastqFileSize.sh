#set -x

nOfParamsNeeded=3
if test $# -lt $nOfParamsNeeded
then
    echo "usage: $0 <folderSearch> <run> <layout = SINGLE | PAIRED>"
    exit 1
fi

folderSearch=$1
run=$2
layout=$3

cd $folderSearch

sizesB=`ls -al | tr -s ' ' | egrep "$run(_[1,2])?\.fastq" | cut -d' ' -f5`

if test -z "$sizesB"
then
    echo "Error: $0 did not found any fastq file"
    exit 2
fi

totalSizeMB=0
#B_to_MB=$((2 ** 20)) #gives error if called from c++
B_to_MB=`echo "2 20" | awk '{ print ($1 ^ $2); }'`

if test $layout = 'SINGLE'
then
    fastqSizeB=`echo $sizesB`
    fastqSizeMB=$(( $fastqSizeB / $B_to_MB ))
    totalSizeMB=$fastqSizeMB
else
    fastq1SizeB=`echo $sizesB | cut -d' ' -f1`
    fastq2SizeB=`echo $sizesB | cut -d' ' -f2`
    fastq1SizeMB=$(( $fastq1SizeB / $B_to_MB )) 
    fastq2SizeMB=$(( $fastq2SizeB / $B_to_MB ))
    totalSizeMB=$(( $fastq1SizeMB + $fastq2SizeMB ))
fi

echo $totalSizeMB

exit 0