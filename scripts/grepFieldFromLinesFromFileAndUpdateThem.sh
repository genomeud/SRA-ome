nOfParamsNeeded=5

if test $# -lt $nOfParamsNeeded
then
    echo "usage: <file> <regex> <grep_options> <fieldIdxToUpdate> <newFieldValue>" 
    echo "example: metadata_filtered_small.csv "sars-cov-2.*,TO_DO$" i 19 IGNORE" 
    echo "NB: some useful options:"
    echo " -i: ignore case"
    echo " -v: inverse match"
    echo " -E: extended grep"
    exit 1
fi

file="$1"
regex="$2"
options="$3"
fieldIdxToUpdate="$4"
newFieldValue="$5"

backup_file="${file}".backup
cp "$file" "$backup_file"

temp_file='temp_file'
echo -n >$temp_file

#cat $file | grep -$options "$regex" >$temp_file
i=1
n=`cat "$file" | wc -l`

while read line
do

    remainder=`echo "$i 500" | awk '{ print ($1 % $2); }'`
    if test $remainder -eq 0
    then
        echo "running... $i of $n"
    fi

    #default: lines keeps be the same
    newLine="$line"

    #check if line greps regex given
    lineGreps=`echo "$line" | grep -"$options" "$regex"`

    if ! test -z "$lineGreps"
    then
        #if line greps then update field given:

        #0) save old value
        oldFieldValue=`echo "$line" | cut -d',' -f$fieldIdxToUpdate`

        #1.a) get fields before column to update
        lastLeftIdx=$(($fieldIdxToUpdate-1))
        lineLeftPart=`echo "$line" | cut -d',' -f1-$lastLeftIdx`

        #1.b) get field after column to update
        firstRightIdx=$(($fieldIdxToUpdate+1))
        lineRightPart=`echo "$line" | cut -d',' -f$firstRightIdx-`

        #2.a) if column to update is not the first field: attach left part and delimiter
        if test -n "$lineLeftPart"
        then
            newLine="$lineLeftPart"','
        fi

        #2.b) attach new value to colomun to update
        newLine="$newLine""$newFieldValue"
        
        #2.c) if column to update is not the last field: attach delimiter and right part
        if test -n "$lineRightPart"
        then
            newLine="$newLine"','"$lineRightPart"
        fi

        #print some output
        echo "$i: $oldFieldValue -> $newFieldValue"
        echo -e "$newLine""\n"

    fi

    #update new file
    echo "$newLine">>$temp_file
    #increase line counter
    i=$(($i+1))

done <"$file"

mv $temp_file "$file"

exit 0