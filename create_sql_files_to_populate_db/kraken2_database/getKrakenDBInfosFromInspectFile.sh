#set -x

nOfParamsNeeded=3

if test $# -ne $nOfParamsNeeded
then
    echo "usage: $0 <inspect.txt> <collection_name> <collection_date>"
    echo 'example:' $0 'Kraken2_DB16_inspect.txt' 'Standard-16' '2020-02-12'
    echo 'output_file: Kraken2_DB16_<collection_name>_<collection_date>.sql'
    exit 1
fi

krakendb_if=$1
collection=$2
collection_date=$3

output_file='Kraken2_DB16_'$collection'_'$collection_date'.sql'
temp_file='tmp'
#fields:
#PercFrags, RootedFrags, DirectFrags, Rank, TaxId, ScientificName
#we want 2,3,5

prefix='('\'$collection\'','\'$collection_date\'','

cat $krakendb_if \
| grep -v '^#' \
| tr '\t' ',' \
| cut -d ',' -f2,3,5 \
| sed s/^/"$prefix"/ \
| sed s/$/'),'/ \
| sed '$ s/,$/;/' \
>$temp_file

echo 'start transaction;' >$output_file
echo >>$output_file
echo 'insert into KrakenRecord' >>$output_file
echo '(Collection, CollectionDate, RootedFragmentNum, DirectFragmentNum, TaxonID)' >>$output_file
echo 'values' >>$output_file
cat $temp_file >>$output_file
echo >>$output_file
echo 'commit;' >>$output_file

rm $temp_file
