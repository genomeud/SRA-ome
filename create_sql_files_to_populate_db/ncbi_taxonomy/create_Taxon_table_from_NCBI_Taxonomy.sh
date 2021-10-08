set -x

nOfParamsNeeded=2

if test $# -ne $nOfParamsNeeded
then
    echo "usage: $0 <taxonomy_input_directory> <taxonomy_date>"
    echo "example: $0 'taxonomy_2021-03-01' '2021-03-01'"
    echo "output_file: <taxonomy_input_directory>/2_tax_Taxon_<taxonomy_date>.sql'"
    echo "NB: inside directory we expect exists files nodes.dmp, names.dmp"
    exit 1
fi

dir=$1
taxonomy_date=$2

dir=`echo $dir | sed s:'/'$::`

nodes_if=$dir/'nodes.dmp'
nodes_of=$dir/'nodes_cutted.csv'

names_if=$dir/'names.dmp'
names_of=$dir/'names_cutted.csv'

temp_file=$dir/'tmp'
output_file=$dir/'2_tax_Taxon_'$taxonomy_date'.sql'

cat $nodes_if \
| cut -d'|' -f1-3 \
| sed s:\':'\\'\':g \
| sed s:'|':\'\,\':g \
| sed s:^:\': \
| sed s:$:\': \
| tr -d '\t' \
>$nodes_of

cat $names_if \
| grep 'scientific name' \
| cut -d'|' -f2 \
| sed s:\':'\\'\':g \
| sed s:^:E\': \
| sed s:$:\': \
| tr -d '\t' \
>$names_of

paste -d',' $nodes_of $names_of \
| sed s:^:'(': \
| sed s:$:'),': \
| sed '$ s/,$/;/' \
>$temp_file

echo 'start transaction;' >$output_file
echo >>$output_file
echo 'insert into Taxon' >>$output_file
echo '(TaxonID, ParentTaxonID, Rank, TaxonName)' >>$output_file
echo 'values' >>$output_file
cat $temp_file >>$output_file
echo >>$output_file
echo 'commit;' >>$output_file

rm $temp_file

rm $names_of
rm $nodes_of
