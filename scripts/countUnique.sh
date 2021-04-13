if test $# -lt 1
then
    echo "usage $0 <inputfile> [<delimiter>]"
fi 
inputfile=$1
d='\t'
if test $# -gt 1
then
    d="$2"
fi

outputfile=output.txt

#echo -n >$outputfile

n=`head -n 1 $inputfile | sed -E s/[^"$d"]//g | wc -c`
for (( i=1; i<=$n; i++ ))
do
    count=`cat "$1" | cut -f$i | sort | uniq | wc -l`
    #count=$[$count - 2]
    echo -en "$count""\t" >>$outputfile
done
echo >>$outputfile