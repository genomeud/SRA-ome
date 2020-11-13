#!/bin/bash

################################################################################
#
# Metagenomics analysis
#
################################################################################

DBDIR=/projects/populus/ep/share/marroni/EOSC/
READDIR=/projects/populus/ep/share/marroni/EOSC/reads/Metagenomics
KRAKBIN=/projects/populus/ep/software/kraken2-2.0.6-beta/bin
KDB=/projects/igats/metagenomics/custom_databases/kraken_nt_2.0.7
MINIKDB=/projects/populus/ep/share/marroni/databases/minikraken2_v2_8GB_201904_UPDATE
KRES=/projects/populus/ep/share/marroni/EOSC/classification/Metagenomics
MINIKRES=/projects/populus/ep/share/marroni/EOSC/classification/Metagenomics_mini


module load it/lang/r/3.6.1
#Needed only once
Rscript /projects/populus/ep/share/marroni/functions/EOSC/01_explore_SRA.r \
-D FALSE \
-S SRAmetadb.sqlite \
-F $DBDIR \
-T 'metagenomics'


#Needed recursively (if we increase D we increase the number of SRA experiments downloaded in a single batch!)
myd=`echo "module load it/lang/r/3.6.1; Rscript /projects/populus/ep/share/marroni/functions/EOSC/02_download_SRA.r \
-S ${DBDIR}/SRAmetadb.sqlite \
-F $READDIR \
-D 5 \
-I ${DBDIR}/metagenomics_table.txt >${KRES}/logs/d.out 2>${KRES}/logs/d.err"| qsub -N df -l vmem=15G,walltime=168:00:00,nodes=1:ppn=1` 

#Needed recursively (on stratocluster) (still need to deal with discriminating between single and paired reads)
#Right now, only single reads

myk=`qsub -F "$KDB $KRES" /projects/populus/ep/share/marroni/scripts/EOSC/01_class_metag.pbs -W depend=afterok:$myd` 

mykmini=`qsub -F "$MINIKDB $MINIKRES" /projects/populus/ep/share/marroni/scripts/EOSC/01_class_metag.pbs -W depend=afterok:$myd` 

#Only execute if everything is fine
echo "rm ${KRES}/*.kraken; rm $READDIR/*.gz" | qsub -N myc -l vmem=2G,walltime=1:00:00,nodes=1:ppn=1 -W depend=afterok:$myk:$mykmini








################################################################################
#
# Transcriptome analysis
#
################################################################################

DBDIR=/projects/populus/ep/share/marroni/EOSC/
READDIR=/projects/populus/ep/share/marroni/EOSC/reads/Transcriptomics
KRAKBIN=/projects/populus/ep/software/kraken2-2.0.6-beta/bin
KDB=/projects/igats/metagenomics/custom_databases/kraken_nt_2.0.7
KRES=/projects/populus/ep/share/marroni/EOSC/classification/Transcriptomics


module load it/lang/r/3.6.1
#Needed only once
Rscript /projects/populus/ep/share/marroni/functions/EOSC/01_explore_SRA.r \
-D FALSE \
-S SRAmetadb.sqlite \
-F $DBDIR \
-T 'Transcriptome Analysis'

#Needed recursively (if we increase D we increase the number of SRA experiments downloaded in a single batch!)
myd=`echo "module load it/lang/r/3.6.1; Rscript /projects/populus/ep/share/marroni/functions/EOSC/02_download_SRA.r \
-S ${DBDIR}/SRAmetadb.sqlite \
-F $READDIR \
-D 2 \
-I ${DBDIR}/Transcriptome_Analysis_table.txt >${KRES}/logs/d.out 2>${KRES}/logs/d.err"| qsub -N df -l vmem=15G,walltime=168:00:00,nodes=1:ppn=1` 

#Needed recursively (on stratocluster) (still need to deal with discriminating between single and paired reads)
#Right now, only single reads

myk=`qsub /projects/populus/ep/share/marroni/scripts/EOSC/02_class_transcript.pbs -W depend=afterok:$myd` 

#Only execute if everything is fine
echo "rm ${KRES}/*.kraken; rm $READDIR/*.gz" | qsub -N myc -l vmem=2G,walltime=1:00:00,nodes=1:ppn=1 -W depend=afterok:$myk






##########################
#
# Experimental shit below!!!!
#
#####################################

#Try to link everything together (still not working!!!!!!!)
head -n20 ${DBDIR}/Transcriptome_Analysis_table.txt > ${DBDIR}/ciccio.txt


while IFS="\t" read -r p1 p2 p3 p4 p5 p6 p7 p8 p9 p10 p11 p12 p13 p14 p15 p16 p17 p18 p19 p20 p21 p22 p23 p24
do
#echo $line | cut -d$'\t' -f23
#down=$(echo $line | cut -f23) 
echo $p23
done < ${DBDIR}/ciccio.txt


#This is working!!!
awk 'BEGIN{OFS="\t"}
{ FS="\t"; $0=$0;
print $23
}' ${DBDIR}/ciccio.txt




##############################################
#
# Old stuff below
#
##############################################


##############################################
#Variables you will need to change
###############################################
PROJDIR=/path/to/results  #Everything will be saved as a subfolder of this
SOFTDIR=/path/to/software #Assuming you have a common repository for software (only needed if the software packages I used are not in your path)
FUNCDIR=/path/to/scripts/and/functions #I suggest you create inside this folder a folder called "functions/limodorum" in which you will save all the R functions provided.
										# You also need to create a folder scripts/limodorum in which you need to put al the shell and python scripts
ANACDIR=/path/to/anaconda/bins #I needed it to quickly access my conda environments
KRAKBIN=/path/to/kraken/executables # Only needed if kraken is not in your path nor in SOFTDIR (I am a mess, and it was in its own folder!)
KDB=/path/to/kraken/db #No comments
KSCRIPT=/path/to/kraken/helper/scripts #
TAXKIT=/path/to/taxonkit/bin        #Only needed if taxonkit is not in your repository specified with SOFTDIR
##############################################
#End of variables you will need to change
###############################################


INPUT=${PROJDIR}/full_trinity_assembly/Trinity.fasta
KRES=${PROJDIR}/kraken_nt
outpref=Trinity
# PRE Execution
#s1 - classify
mkdir -p ${KRES}/logs
krak1=`echo "cd ${KRES}/logs; export TMPDIR=${KRES}; 
module use --append /iga/scripts/dev_modules/modules; \
${KRAKBIN}/kraken2 --threads 16 --db $KDB $INPUT --unclassified-out ${KRES}/unclassified.fasta --output ${KRES}/${outpref}.kraken --use-names --report ${KRES}/${outpref}.kraken.report.txt >${KRES}/logs/krak.out 2>${KRES}/logs/krak.err"| qsub -N krak1_${outpref} -l vmem=220G,walltime=168:00:00,nodes=1:ppn=16`
#s2 - reports
echo "cd ${KRES}; \
export TMPDIR=${KRES}; \
module use --append /iga/scripts/dev_modules/modules; \
module load dev/krona/2.6; \
python  ${KSCRIPT}/kraken2txt.py ${KRES}/${outpref}.kraken.report.txt ${KRES}/${outpref}.kraken.krona_table.txt; \
ktImportText ${KRES}/${outpref}.kraken.krona_table.txt,${outpref} -o ${outpref}.kraken_single-chart.html >${KRES}/logs/map.out 2>${KRES}/logs/map.err" | qsub -N krak2_${outpref} -l vmem=32G,walltime=24:00:00,nodes=1:ppn=16 -W depend=afterok:$krak1



#Run KRAKEN on Reads, mostly to check to which fungus we are mostly assigning reads.
READ_LEN=150

cd ${FUNCDIR}/scripts/logs
PRES=${PROJDIR}
KRES=${PROJDIR}/kraken_reads
mkdir -p $KRES/logs
for SAMPLE in LM3 LM4 LM6 LS2 LS3 LS6
do
trimmed_dir=${PRES}/Sample_${SAMPLE}/merge_trimmed 
READ1=${trimmed_dir}/${SAMPLE}_R1.fastq.gz
READ2=${trimmed_dir}/${SAMPLE}_R2.fastq.gz
READ2=${READ1/_norRNA_1/_norRNA_2}
pref=$SAMPLE
step1=`echo "cd ${KRES}; export TMPDIR=${KRES}; module use --append /iga/scripts/dev_modules/modules; \
${KRAKBIN}/kraken2 --threads 16 --paired --gzip-compressed --db $KDB ${READ1} ${READ2} --output ${KRES}/${pref}.kraken --use-names --report ${KRES}/${pref}.kraken.report.txt >${KRES}/logs/map.out 2>${KRES}/logs/map.err"| qsub -N s1_${pref} -l vmem=150G,walltime=168:00:00,nodes=1:ppn=16`
#s2 - reports
echo "cd ${KRES}; \
export TMPDIR=${KRES}; \
module use --append /iga/scripts/dev_modules/modules; \
module load dev/krona/2.6; \
python ${KSCRIPT}/kraken2txt.py ${KRES}/${pref}.kraken.report.txt ${KRES}/${pref}.kraken.krona_table.txt; \
ktImportText ${KRES}/${pref}.kraken.krona_table.txt,${pref} -o ${pref}.kraken_single-chart.html >${KRES}/logs/map.out 2>${KRES}/logs/map.err" | qsub -N s2_${pref} -l vmem=32G,walltime=24:00:00,nodes=1:ppn=16 -W depend=afterok:$step1
done

#Use blastx to classify transcripts, just a second check
#!/bin/bash
module load aligners/blast/latest
INPUT=${PROJDIR}/full_trinity_assembly/Trinity.fasta
OUTPUT=${PROJDIR}/full_trinity_assembly/Trinity_blast_nr.out
NT=16
echo "module load aligners/blast/latest; blastx -query $INPUT -db /iga/biodb/ncbi/blastdb/latest/nr -outfmt '6 qseqid sseqid pident length mismatch gapopen qstart qend sstart send evalue bitscore stitle' -evalue 1e-10 -num_alignments 1 -num_threads $NT -out $OUTPUT" | qsub -N balnr -l vmem=32G,walltime=168:00:00,nodes=1:ppn=$NT

module load aligners/blast/latest
INPUT=${PROJDIR}/full_trinity_assembly/Trinity.fasta
OUTPUT=${PROJDIR}/full_trinity_assembly/Trinity_blast_nt.out
echo "module load aligners/blast/latest;blastn -query $INPUT -db /iga/biodb/ncbi/blastdb/latest/nt -outfmt '6 qseqid sseqid pident length mismatch gapopen qstart qend sstart send evalue bitscore stitle' -evalue 1e-10 -num_alignments 1 -num_threads $NT -out $OUTPUT " | qsub -N balnr -l vmem=32G,walltime=168:00:00,nodes=1:ppn=$NT

