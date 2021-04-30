#!/bin/bash
#set -x

nOfParamsNeeded=3
if test $# -lt $nOfParamsNeeded
then
    echo "usage: $0 <folderSearch> <run> <layout = SINGLE | PAIRED>"
    exit -1
fi

#NB, in this script i use:
#exit status < 0 ==> ERROR
#exit status > 0 ==> WARNING

folderSearch=$1
run=$2
layout=$3

cd $folderSearch

sizesB_array=(`ls -al | tr -s ' ' | egrep "$run(_[1,2])?\.fastq" | cut -d' ' -f5`)

if test ${#sizesB_array[@]} -eq 0
then
    echo "Error: $0 did not found any fastq file"
    exit -2
fi

totalSizeMB=0
#B_to_MB=$((2 ** 20)) #gives error if called from c++
B_to_MB=`echo "2 20" | awk '{ print ($1 ^ $2); }'`

warningMessage=''
warningStatus=0

if test ${#sizesB_array[@]} -eq 1
then
    if ! test $layout = 'SINGLE'
    then
        warningMessage="Warning: $0 found one fastq file of $run but run layout is not SINGLE, is there an error in SRA db?"
        warningStatus=1
    fi
    fastqSizeB=${sizesB_array[0]}
    fastqSizeMB=$(( $fastqSizeB / $B_to_MB ))
    totalSizeMB=$fastqSizeMB
    
elif test ${#sizesB_array[@]} -eq 2
then
    if ! test $layout = 'PAIRED'
    then
        warningMessage="Warning: $0 found two fastq file of $run but run layout is not PAIRED, is there an error in SRA db?"
        warningStatus=2
    fi
    fastq1SizeB=${sizesB_array[0]}
    fastq2SizeB=${sizesB_array[1]}
    fastq1SizeMB=$(( $fastq1SizeB / $B_to_MB )) 
    fastq2SizeMB=$(( $fastq2SizeB / $B_to_MB ))
    totalSizeMB=$(( $fastq1SizeMB + $fastq2SizeMB ))
else
    echo "Error: $0 found ${#sizesB_array[@]} fastq files of $run $layout, this was not expected."
    array=(`ls -al | tr -s ' ' | egrep "$run(_[1,2])?\.fastq"`)
    echo "List of fastq files found:" ${array[@]:0:${#array[@]}}
    exit -3
fi

#print output
echo $totalSizeMB

#eventually print a warning and exit with the corresponding exit status
if test $warningStatus -ne 0
then
    echo "$warningMessage"
    exit $warningStatus
fi

exit 0