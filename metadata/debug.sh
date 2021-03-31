#set -x

run=$1

SRAStudy=`cat runs_info_new_with_singlequote.txt | grep "$run" | cut -f21`

echo $SRAStudy

studyTitle=`cat experiment_formatted.xml \
| grep "$SRAStudy" -A 100 \
| head -n 100 \
| grep '<STUDY_TITLE>' \
| sed s/^.*'<STUDY_TITLE>'// \
| sed s:'</STUDY_TITLE>'::`

echo "$studyTitle"
echo