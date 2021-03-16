cat $1 | wc -l
cat $1 | grep -Eiv "$2" >temp.csv
cp temp.csv $1
cat temp.csv | cut -d',' -f1,29 >temp_new.csv
rm temp.csv
cat $1 | wc -l