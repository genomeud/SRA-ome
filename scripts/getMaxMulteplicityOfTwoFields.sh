#set -x
nOfParamsNeeded=3

if test $# -lt $nOfParamsNeeded
then
    echo "usage: $0 <file.csv> <fieldIdx1> <fieldIdx2> [<delimiter=','>]"
    exit 1
fi

#check if two fields are (1,1), (1,M), (M,M)

output_dir='test'
delimiter=','

file=$1
field1=$2
field2=$3
if test $# -gt $nOfParamsNeeded
then
    delimiter=$4
fi
output_file_both=$output_dir'/''fields_'${field1}'_'${field2}'.txt'
output_file_1=$output_dir'/''field_'${field1}'.txt'
output_file_2=$output_dir'/''field_'${field2}'.txt'

cat $file | \
cut -d "$delimiter" -f$field1,$field2 | \
sort | \
uniq -c | \
tr -s ' ' | \
cut -d' ' -f2- | \
sed s/' '/$delimiter/ \
>$output_file_both

cat $output_file_both | \
cut -d "$delimiter" -f2 | \
uniq -c | \
tr -s ' ' | \
cut -d' ' -f2- | \
grep -v ^'1 ' \
>$output_file_1

cat $output_file_both | \
cut -d "$delimiter" -f3 | \
uniq -c | \
tr -s ' ' | \
cut -d' ' -f2- | \
grep -v ^'1 ' \
>$output_file_2

#file_both=`cat $output_file_both`
file_1=`cat $output_file_1`
file_2=`cat $output_file_2`

has_lines_1=false
has_lines_2=false

if ! test -z "$file_1"
then
    has_lines_1=true
fi
if ! test -z "$file_2"
then
    has_lines_2=true
fi

if test ${has_lines_1} = true -a ${has_lines_2} = true
then
    #both have lines
    echo "$field1 (1,M) <> (1,M) $field2"

elif test ${has_lines_1} = true -a ${has_lines_2} = false
then
    #only 1 has lines
    echo "$field1 (1,M) <> (1,1) $field2"

elif test ${has_lines_1} = false -a ${has_lines_2} = true
then
    #only 2 has lines
    echo "$field1 (1,1) <> (1,M) $field2"

elif test ${has_lines_1} = false -a ${has_lines_2} = false
then
    #both not have lines
    echo "$field1 (1,1) <> (1,1) $field2"

else
    echo "WTF?"
fi

exit 0