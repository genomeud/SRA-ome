#!/bin/bash 

KRAKBIN=$1 
KDB=$2 
KRES=$3 
READDIR=$4
LOGDIR=$5
NPROCS=$6

echo krakbin=$KRAKBIN
echo kdb=$KDB
echo readdir=$READDIR
#Check if paired end files exist (/dev/null is just to avoid double printing of the file name)
if compgen -G $READDIR/*_1.fastq.gz > /dev/null;
then
for READFILE in $READDIR/*_1.fastq.gz
do
echo "Processing paired reads"
echo $READFILE
pref=$(basename ${READFILE/_1.fastq.gz/})
READFILE2=${READFILE/_1.fastq.gz/_2.fastq.gz}
echo $pref
#This one was in case of paired, still need to deal with that
cd ${KRES}; export TMPDIR=${KRES}; \
${KRAKBIN}/kraken2 --threads $NPROCS --paired --gzip-compressed --db $KDB ${READFILE} ${READFILE2} --output ${KRES}/${pref}.kraken \
--use-names --report ${KRES}/${pref}.kraken.report.txt >${LOGDIR}/${pref}_map.out 2>${LOGDIR}/${pref}_map.err
done
fi
#Check if we have single reads
if compgen -G $READDIR/*.fastq.gz > /dev/null;
then
	for READFILE in $READDIR/*.fastq.gz
	do
		if [[ "$READFILE" != *"_1.fastq"* && "$READFILE" != *"_2.fastq"* ]]
			then
			echo "Processing single reads"
			echo $READFILE
			pref=$(basename ${READFILE/.fastq.gz/})
			echo $pref
			#This one was in case of paired, still need to deal with that
			cd ${KRES}; export TMPDIR=${KRES}; \
			${KRAKBIN}/kraken2 --threads $NPROCS --gzip-compressed --db $KDB ${READFILE} --output ${KRES}/${pref}.kraken \
			--use-names --report ${KRES}/${pref}.kraken.report.txt >${LOGDIR}/${pref}_map.out 2>${LOGDIR}/${pref}_map.err
		fi
	done
fi
