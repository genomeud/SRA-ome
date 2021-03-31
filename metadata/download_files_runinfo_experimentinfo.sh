#links to download all metadata needed

#rettype=runinfo ==> tabella csv: ogni riga le info di una run
#SOURCE = METATRANSCRIPTOMIC ==> solo metatranscrittomica
#circa 20-25 MB di file
wget 'http://trace.ncbi.nlm.nih.gov/Traces/sra/sra.cgi?save=efetch&db=sra&rettype=runinfo&term="METATRANSCRIPTOMIC"[Source]'

#rettype=experimentinfo ==> file xml con tutti i metadati: esperimenti, studi, samples, run...
#SOURCE = METATRANSCRIPTOMIC ==> solo metatranscrittomica
#circa 400-450 MB di file
wget 'http://trace.ncbi.nlm.nih.gov/Traces/sra/sra.cgi?save=efetch&db=sra&rettype=experimentinfo&term="METATRANSCRIPTOMIC"[Source]'