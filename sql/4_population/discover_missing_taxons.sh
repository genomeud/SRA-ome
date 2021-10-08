#set -x

nOfParamsNeeded=1

if test $# -ne $nOfParamsNeeded
then
    echo "usage: $0 <taxons_if>"
    echo "example: $0 'taxons_of_kraken_db.txt'"
    echo "NB: format of each row of input file: 'taxid' (with the '!)"
    echo "NB: the queries will not modify the database, are runned only SELECT"
    exit 1
fi

# script is useful to find out which taxons are: 
#   - present       in kraken database or in sample
#   - not present   in the taxonomy.
# it we will be useful in case of update the databases

# NB this script is quite slow (maybe can be improved with multithreading)
# if you think only few rows can cause problems of missing taxids
# just try the insert, look the taxid missing, comment the taxid line in the insert file
# try again a few times, if keeps giving you errors use this script,
# so you all the taxid problematic.

taxons_if=$1
log_file=$taxons_if'_all_searched_taxons.log'
output_file=$taxons_if'_only_missing_taxons.txt'

query_general='select TaxonID, TaxonName from Taxon where TaxonID = '
tmp_query_file='tmp_query.sql'

user='postgres'
database='sra_analysis'

while read line
do
    query_current="${query_general}${line}"
    echo $query_current >$tmp_query_file
    sudo -u $user psql -d $database -a -f $tmp_query_file | tee -a $log_file

done < "$taxons_if"

cat $log_file \
| grep -B 3 ^\('0 rows'\)$ \
| grep \'[0-9]*\'$ \
| sed s/[^\']*\'/\'/ \
>$output_file

rm $tmp_query_file
