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
LOGDIR=/projects/populus/ep/share/marroni/scripts/logs



#Search sars-cov-2 quickly
MINIKRES=/projects/populus/ep/share/marroni/EOSC/classification/Metagenomics_mini
MINIKRES=/projects/populus/ep/share/marroni/EOSC/classification/Metatranscriptomics
awk '$5==2697049' ${MINIKRES}/*/*.kraken.report.txt






#######################
#
#OLD STUFF BELOW!!!
#
#######################

cd $LOGDIR
#Needed recursively (if we increase D we increase the number of SRA experiments downloaded in a single batch!)
#From newer to older
myd_rev=`echo "module load it/lang/r/3.6.1; Rscript /projects/populus/ep/share/marroni/functions/EOSC/02_download_SRA.r \
-S ${DBDIR}/SRAmetadb.sqlite \
-F $READDIR \
-R TRUE \
-D 19 \
-I ${DBDIR}/metagenomics_table.txt \
>${LOGDIR}/d_rev.out 2>${LOGDIR}/d_rev.err"| qsub -N df_rev -l vmem=15G,walltime=168:00:00,nodes=1:ppn=1` 
#Start from older to newer: I wait a couple of minutes to avoid using fread at the same time (file empty error)
myd_for=`echo "module load it/lang/r/3.6.1; Rscript /projects/populus/ep/share/marroni/functions/EOSC/02_download_SRA.r \
-S ${DBDIR}/SRAmetadb.sqlite \
-F $READDIR \
-R FALSE \
-D 19 \
-I ${DBDIR}/metagenomics_table.txt \
>${LOGDIR}/d_for.out 2>${LOGDIR}/d_for.err"| qsub -N df_for -l vmem=15G,walltime=168:00:00,nodes=1:ppn=1 -W depend=afterany:$myd_rev` 

#Needed recursively (on stratocluster) (still need to deal with discriminating between single and paired reads)
#Right now, only single reads
#I decided that I don't need the analysis on the full nt anymore. Better to focus on the minikraken database
#myk=`qsub -F "$KDB $KRES" /projects/populus/ep/share/marroni/scripts/EOSC/01_class_metag.pbs -W depend=afterany:$myd` 
mykmini=`qsub -F "$MINIKDB $MINIKRES" /projects/populus/ep/share/marroni/scripts/EOSC/01_class_metag.pbs -W depend=afterany:$myd_for:$myd_rev` 
#Only execute if everything is fine
echo "rm ${KRES}/*.kraken; rm ${MINIKRES}/*.kraken; rm $READDIR/*.gz" | qsub -N myc -l vmem=2G,walltime=1:00:00,nodes=1:ppn=1 -W depend=afterok:$mykmini
#Script for moving files to subfolders according to starting characters
qsub -F "$MINIKRES SRR 6" /projects/populus/ep/share/marroni/scripts/EOSC/03_move_kres.pbs -W depend=afterok:$mykmini 
qsub -F "$MINIKRES ERR 4" /projects/populus/ep/share/marroni/scripts/EOSC/03_move_kres.pbs -W depend=afterok:$mykmini 
qsub -F "$MINIKRES DRR 3" /projects/populus/ep/share/marroni/scripts/EOSC/03_move_kres.pbs -W depend=afterok:$mykmini 




#To check the progress quickly!
#Check how many donwload were completed or attempted
cut -f23  ${DBDIR}/metagenomics_table.txt | sort | uniq -c
#Check how many metagenomics results file we have
#ls -l $MINIKRES/* | wc -l
ls -l $MINIKRES | wc -l
for aaa in ${MINIKRES}/*
do
echo $aaa
ls -l $aaa | wc -l 
done




#This is my horrible R function to create a unique huge table with all results. I will just need to run it every now and then
Rscript /projects/populus/ep/share/marroni/functions/EOSC/03_summarize_K.r \
-I $MINIKRES \
-P kraken.report.txt \
-O /projects/populus/ep/share/marroni/EOSC/output/Metagenomics_mini/Summary.txt







################################################################################
#
# Transcriptome analysis
#
################################################################################

DBDIR=/projects/populus/ep/share/marroni/EOSC/
READDIR=/projects/populus/ep/share/marroni/EOSC/reads/Transcriptomics
KRAKBIN=/projects/populus/ep/software/kraken2-2.0.6-beta/bin
MINIKDB=/projects/populus/ep/share/marroni/databases/minikraken2_v2_8GB_201904_UPDATE
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

myk=`qsub ${MINIKDB} ${KRES} /projects/populus/ep/share/marroni/scripts/EOSC/02_class_transcript.pbs -W depend=afterok:$myd` 

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



