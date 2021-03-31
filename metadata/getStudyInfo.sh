#set -x

if test $# -ne 1
then
	echo "usage: $0 <SRAStudy>"
	exit 1
fi

SRAStudy=$1

#starts with S
#isNCBI=`echo $SRAStudy | grep ^S | wc -c`
#if [ "$isNCBI" -gt 0 ]; then isNCBI=true; else isNCBI=false; fi

#starts with E
#isEBI=`echo $SRAStudy | grep ^E | wc -c`
#if [ "$isEBI" -gt 0 ]; then isEBI=true; else isEBI=false; fi

#starts with D
#isINSDC=`echo $SRAStudy | grep ^D | wc -c`
#if [ "$isINSDC" -gt 0 ]; then isINSDC=true; else isINSDC=false; fi

pattern='<STUDY '.*'accession="'$SRAStudy'"'.*'>'
#echo -e "pattern:\t"$pattern

studyTitle=`cat experiment_formatted.xml \
| grep "$pattern" -A 100 \
| head -n 100 \
| grep '<STUDY_TITLE>' \
| sed s/^.*'<STUDY_TITLE>'// \
| sed s:'</STUDY_TITLE>'::`

#echo -e "studyTitle:\t"$studyTitle
echo "$studyTitle"

if test -z "$studyTitle"
then
	echo "$SRAStudy" >>error.txt
fi