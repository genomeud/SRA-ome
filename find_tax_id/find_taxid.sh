#set -x

usage="usage $0 <int: 0=human_ALL or 1=coronavirus>"
if test $# -ne 1
then
	echo $usage
	exit 1
fi

dirPath='/home/fzuccato/test/viromescan/bowtie2'
inFile=""
if test $1 -eq 0
then
	inFile='human_ALL+covid19.fa'
else
	inFile='coronavirus.fa'
fi
echo $inFile

outFileFound=$inFile.taxID.map
outFileNotFound=$inFile.NO.taxID.txt
outFileResults=$inFile.results.txt
outFileNewFa=$inFile.taxID.fa

mapFile='/home/fzuccato/databases/krakenDB16/seqid2taxid.map'

#clear files
echo -n >$outFileFound
echo -n >$outFileNotFound
echo -n >$outFileResults
echo -n >$outFileNewFa

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
	#echo 'read line'
	#check if is a header line
	isHeader=`echo $line | grep '^>'`
	if test -n "$isHeader"
	then
		#echo 'is header' #line is header, get someID
		nOfHeaders=$[$nOfHeaders+1]
		someID=""
		if test $1 -eq 0
		then
			#echo 'human all file' #for human_all file
			someID=`echo $isHeader | sed 's/^.*NC_/NC_/' | cut -f1 -d\|` 
		else
			#echo 'coronavirus file' #for coronavirus file
			someID=`echo $isHeader | sed 's/>//' | cut -f1 -d' '`
		fi

        findTaxID=`cat $mapFile | grep "$someID"`
        kraken_taxid='kraken:taxid'
        taxID='10239' #default
        name='Viruses' #default
        if test -n "$findTaxID"
        then
			#echo 'found taxid' #someID trovato nel file map
        	taxID=`echo $findTaxID | cut -f'2' -d'|'`
        	name=''
        	nOfIdsMapped=$[$nOfIdsMapped+1]
        else
	        isSarsCov2=`echo $line | grep 'Severe acute respiratory syndrome coronavirus 2'`
	        if test -n "$isSarsCov2"
	        then
	        	#echo 'not found taxid but is sars-cov-2' #someID non trovato nel file map ma è sars-cov-2
				taxID=2697049
	        	name=''
	        	nOfIdsMapped=$[$nOfIdsMapped+1]
	        else
	        	#echo 'unknown, assigned to general virus' #someID non trovato nel file map
		        nOfIdsNotMapped=$[$nOfIdsNotMapped+1]
		        echo $nOfHeaders '|' $isHeader >>$outFileNotFound
	        fi
    	fi
    	if test -n $name
    	then
	        echo $kraken_taxid'|'$taxID'|'$someID >>$outFileFound
	        echo -e 'found:\t'$nOfHeaders'\t'$someID'\t==>\t'$taxID
    	else
        	echo -e 'NOPE:\t'$nOfHeaders'\t'$someID'\t???\t'$isHeader
    	fi
		line=`echo $line | sed s/'^>'/'>'$kraken_taxid'|'$taxID'|'$name'|'/`
	else
		#echo 'not header #line is not header
		echo -n
	fi
	#sleep 1
	echo $line >>$outFileNewFa
done < $dirPath/$inFile 

n=`cat $dirPath/$inFile | grep '^>' | wc -l`

echo
echo $inFile
echo -e $n'\tTotal IDs in file' | tee $outFileResults
echo -e $[$n-$nOfHeaders]'\tERR: IDs missed from analysis' | tee -a $outFileResults
echo -e $nOfIdsNotMapped'\tWARN: IDs NOT found in map file' | tee -a $outFileResults
echo -e $nOfIdsMapped'\tOK: IDs found in map file' | tee -a $outFileResults

exit 0
