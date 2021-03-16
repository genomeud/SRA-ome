cat experiment_formatted.xml | grep -i '<STUDY_TITLE>' | sort | uniq >study_title.txt
cat study_title.txt | sed s/^' '*'<'/'<'/ | sort | uniq >study_title_squeezed.txt