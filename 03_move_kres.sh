#!/bin/bash 


MINIKRES=$1 TYPE=$2 NCHAR=$3 

mioarray=()
i=0
for bbb in ${MINIKRES}/${TYPE}*.report.txt
do
ccc=$(basename $bbb)
aaa=${ccc:0:$NCHAR}
mioarray[$i]=$aaa
((i++))
done
#Get only unique entries
newfolder=()
newfolder=$(echo ${mioarray[@]} | tr " " "\n" | sort | uniq)
#Create the folders based on SRRXXX and move the files to the correct folder
for PREF in $newfolder
do
echo $PREF
#compgen -G checks if at least one file satisfying the pattern exist
if compgen -G ${MINIKRES}/$PREF*.report.txt > /dev/null ; then 
echo Pattern exists, moving files!
mkdir -p ${MINIKRES}/${PREF}
mv ${MINIKRES}/$PREF*.report.txt ${MINIKRES}/${PREF} 
fi
done

