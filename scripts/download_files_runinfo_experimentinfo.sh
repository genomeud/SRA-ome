#links to download all metadata needed

#rettype=runinfo ==> tabella csv: ogni riga le info di una run
#SOURCE = METATRANSCRIPTOMIC ==> solo metatranscrittomica
#circa 20-25 MB di file
wget -O run_info.csv 'http://trace.ncbi.nlm.nih.gov/Traces/sra/sra.cgi?save=efetch&db=sra&rettype=runinfo&term="METATRANSCRIPTOMIC"[Source]'

#rettype=experimentinfo ==> file xml con tutti i metadati: esperimenti, studi, samples, run...
#SOURCE = METATRANSCRIPTOMIC ==> solo metatranscrittomica
#NB: il file generato è xml ma tutto in una riga, va formattato (ad esempio con xmllint)
#circa 400-450 MB di file
wget  -O experiment_info.xml 'http://trace.ncbi.nlm.nih.gov/Traces/sra/sra.cgi?save=efetch&db=sra&rettype=experimentinfo&term="METATRANSCRIPTOMIC"[Source]'

#format file
cat experiment_info.xml \
| xmllint --format - \
>experiment_info_formatted.xml

#rm experiment_info.xml
