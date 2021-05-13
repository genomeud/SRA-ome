#set -x

nOfParamsNeeded=7

if test $# -lt $nOfParamsNeeded
then
    echo "usage: $0 <ids_inputfile> <identifier_index_inputfile> <all_fields_inputfile> <output_file> <identifier_regex> <field_header_regex> <field_trailer_regex>"
    echo "NB: in <identifier_regex> the character '#' will be substituted with the current identifier"
    echo "example: $0 metadata.csv 4 experiments.xml study_title.txt '<STUDY .*accession=\"#\"' '<STUDY_TITLE>' '</STUDY_TITLE>'"
    exit 1
fi

ids_inputfile="$1"
identifier_index_inputfile="$2"
all_fields_inputfile="$3"
output_file="$4"
identifier_regex_with_wildcard="$5"
field_header_regex="$6"
field_trailer_regex="$7"

wildcard='#'

delimiter=','
log_file=${output_file}'.log'

#clear files
echo -n >$output_file
echo -n >$log_file

script_dir=$HOME'/SRA/scripts'
get_one_field_script=$script_dir/getFieldValueFromIdentifier.sh

i=1
n=`cat "$ids_inputfile" | wc -l`

while read line
do
    current_identifier=`echo "$line" | cut -d"$delimiter" -f"$identifier_index_inputfile"`
    echo -n "line: $i of $n, current identifier: $current_identifier ==> " | tee -a $log_file
    identifier_regex=`echo "$identifier_regex_with_wildcard" | sed s/"$wildcard"/"$current_identifier"/`
    searched_value=`"$get_one_field_script" "$all_fields_inputfile" "$identifier_regex" "$field_header_regex" "$field_trailer_regex" 100`
    ok=$?
    echo "$searched_value" | tee -a $log_file
    if test "$ok" -eq 0
    then
        echo "$searched_value" >>$output_file
    else
        echo "--------------------------- error: $searched_value"
    fi
    i=$[$i+1]

    #sleep 1

done <"$ids_inputfile"