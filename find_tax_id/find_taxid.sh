#set -x

dirPath='/home/fzuccato/test/viromescan/bowtie2'
#inFile='human_ALL+covid19.fa'
inFile='coronavirus.fa'

outFileFound=$inFile.taxID.map
outFileNotFound=$inFile.NO.taxID.txt
outFileResults=$inFile.results.txt

mapFile='/home/fzuccato/databases/krakenDB16/seqid2taxid.map'

#clear files
echo -n >$outFileFound
echo -n >$outFileNotFound
echo -n >$outFileResults

#human_all header line example:
#>xxxxxxxNC_218763278462.7|xxxxxxxxxxxxxx
#coronavirus header line example:
#>NC_218763278462.7 xxxxxxxxxxxxxx
#>MN_218763278462.7 xxxxxxxxxxxxxx
nOfHeaders=0
nOfIdsMapped=0
nOfIdsNotMapped=0
while read line
do
	#check if is a header line
	isHeader=`echo $line | grep '^>'`
	if test -n "$isHeader"
	then
		#line is header, get someID
		nOfHeaders=$[$nOfHeaders+1]
		#someID=`echo $isHeader | sed 's/^.*NC_/NC_/' | cut -f1 -d\|` #for human_all file
		someID=`echo $isHeader | sed 's/>//' | cut -f1 -d' '` #for coronavirus file

        taxID=`cat $mapFile | grep $someID`
        if test -n "$taxID"
        then
        	#someID trovato nel file map
			#to do: stampare sul file la riga aggiungendo il taxID
        	nOfIdsMapped=$[$nOfIdsMapped+1]
	        echo -e $nOfHeaders '\t' $taxID
	        echo $taxID >>$outFileFound
        else
        	#someID non trovato nel file map
			#to do: stampare sul file la riga cosi come è
			nOfIdsNotMapped=$[$nOfIdsNotMapped+1]
        	echo -e 'NOT FOUND:' $nOfHeaders '\t' $line
        	echo -e '--------------------------------------------------- NOT FOUND:' $nOfHeaders '\t' $someID
	        echo $nOfHeaders' | '$line >>$outFileNotFound
        fi
	else
		#line is not header
		#to do: stampare sul file la riga cosi come è
        #sed s/'>'/&
		echo -n
	fi
#	sleep 1
done < $dirPath/$inFile 

n=`cat $dirPath/$inFile | grep '^>' | wc -l`

echo
echo $inFile
echo -e $n'\tTotal IDs in file' | tee $outFileResults
echo -e $[$n-$nOfHeaders]'\tERR: IDs missed from analysis' | tee -a $outFileResults
echo -e $nOfIdsNotMapped'\tWARN: IDs NOT found in map file' | tee -a $outFileResults
echo -e $nOfIdsMapped'\tOK: IDs found in map file' | tee -a $outFileResults

exit 0
