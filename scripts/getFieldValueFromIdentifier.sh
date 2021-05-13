#set -x

nOfParamsNeeded=5

if test $# -lt $nOfParamsNeeded
then
	echo "usage: $0 <input_file> <identifier_regex> <field_header_regex> <field_trailer_regex> <num_lines_after_identifier>"
	echo "example: $0 experiment_formatted.xml '<STUDY.*accession=\"SRP190180\"' '<STUDY_TITLE>' '</STUDY_TITLE>' 100"
	exit 1
fi

input_file="$1"
identifier="$2"
field_header="$3"
field_trailer="$4"
nOfLinesAfterIdentifier="$5"

searched_value=`cat "$input_file" \
| grep "$identifier" -A $nOfLinesAfterIdentifier \
| head -n $nOfLinesAfterIdentifier \
| grep "$field_header" \
| sed s/^.*"$field_header"// \
| sed s:"$field_trailer".*:: \
| head -n 1`


if test -z "$searched_value"
then
	#error not found
	echo "error: $input_file, $identifier, $field_header, $field_trailer" >&2
else
	#ok
	echo "$searched_value"
fi