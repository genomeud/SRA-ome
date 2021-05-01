#!/bin/bash
#set -x

nOfParamsNeeded=2
if test $# -lt $nOfParamsNeeded
then
    echo "usage: $0 <folderSearch> <run> [<layout = SINGLE | PAIRED>]"
    exit 1
fi

#NB, in this script i use:
#exit status  1-99 ==> ERROR
#exit status  100+ ==> WARNING

folderSearch=$1
run=$2
layout=$3

cd $folderSearch

files=(`ls -al | tr -s ' ' | egrep "$run.*"'.fastq' | cut -d' ' -f9`)
sizesB_array=(`ls -al | tr -s ' ' | egrep "$run.*"'.fastq' | cut -d' ' -f5`)
#sizesB_array=(`ls -al | tr -s ' ' | egrep "$run(_[1,2])?\.fastq" | cut -d' ' -f5`)
n=${#sizesB_array[@]}

if test $n -eq 0
then
    echo "Error: $0 did not found any fastq file"
    exit 2
fi

totalSizeMB=0
#B_to_MB=$((2 ** 20)) #gives error if called from c++
B_to_MB=`echo "2 20" | awk '{ print ($1 ^ $2); }'`

totalSizeMB=0

for (( i=0; i<$n; i++ ))
do
    fastqSizeMB=$(( ${sizesB_array[$i]} / $B_to_MB ))
    totalSizeMB=$(( $totalSizeMB + $fastqSizeMB ))
done

#check integrity and correctness of SRA db
warningMessage=''
warningStatus=0
if test \( $n -eq 1 \) -a \( $layout = 'PAIRED' \)
then
    warningMessage="warning: $0 found one fastq file of $run but run layout is not SINGLE, is there an error in SRA db?"
    warningStatus=1
    
elif test \( $n -eq 2 \) -a \( $layout = 'SINGLE' \)
then
    warningMessage="warning: $0 found two fastq file of $run but run layout is not PAIRED, is there an error in SRA db?"
    warningStatus=2
elif test $n -gt 2
then
    #error
    warningMessage="warning: $0 found ${#sizesB_array[@]} fastq files of $run $layout, this was not expected. "
    warningMessage="$warningMessage""List of fastq files found: ${files[@]:0:${#files[@]}}"
    warningStatus=3
fi

#print output
echo $totalSizeMB

#eventually print a warning and exit with the corresponding exit status
if test $warningStatus -ne 0
then
    echo "$warningMessage"
    exit $((100 + $warningStatus))
fi

exit 0