nOfParamsNeeded=3

if test $# -lt $nOfParamsNeeded
then
    echo "usage: <file> <regex> <grep_options>"
    echo "NB: some useful options:"
    echo " -i: ignore case"
    echo " -v: inverse match"
    echo " -E: extended grep"
    exit 1
fi

file=$1
regex=$2
options=$3

backup_file=${file}.backup
cp $file $backup_file

temp_file='temp_file'

nOfLinesOld=`cat $file | wc -l`

cat $file | grep -$options "$regex" >$temp_file
mv $temp_file $file

nOfLinesNew=`cat $file | wc -l`

nOfLinesRemoved=$(($nOfLinesOld - $nOfLinesNew))

echo "saved a backup file at: $backup_file"
echo "removed: $nOfLinesRemoved"
echo "number of lines of new file: $nOfLinesNew"

exit 0