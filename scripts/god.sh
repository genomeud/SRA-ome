#set -x
#"usage: $0 [<outputFolder>]"
mainOutDir='/mnt/extra/fzuccato_new/'$(date +'%Y_%m_%d')'/'

if test $# -gt 0
then
    mainOutDir=$1
    mainOutDir=`echo "$mainOutDir" | sed s:/$::`
    mainOutDir="$mainOutDir"'/'
fi

#output directories
#mainOutDir_TEST='/mnt/extra/fzuccato_new/2021_13_32/'
infoOutDir="$mainOutDir"'.info/'
researchesOutDir="$mainOutDir"'.researches/'

#input directories
mainInDir=$HOME'/SRA/'
scriptsInDir=$mainInDir'scripts/'
metadataInDir=$mainInDir'metadata/'

#input and output files
metadataToDo_file=$metadataInDir'metadata_filtered_small_todo.csv'
metadataAll_file=$metadataInDir'metadata_filtered_small.csv'
runsToDo_file=$infoOutDir'runs_list.csv'

#scripts
pickRandom_script=$scriptsInDir'pickRandomInPercentage.sh'
execFasterQKrakenUpdate_script=$scriptsInDir'execFasterQ_Kraken_update.sh'
searchInAnalysis_script=$scriptsInDir'searchInAnalysis.sh'

if test -d $mainOutDir
then
    echo "error: directory $mainOutDir already exists"
    exit 1
else
    mkdir $mainOutDir
    if test $? -ne 0
    then
        echo "error: can't make directory $mainOutDir"
        exit 2
    fi
fi

#1) pick random 

#   a) parameters:
scientificName_idx=9 
run_idx=8 
layout_idx=14 
sizeMB_idx=17
maxSizeMB=5500 #facoltative, default: 5000

#   b) execution
pickRnd_cmd="$pickRandom_script \
    $metadataToDo_file \
    $scientificName_idx \
    $run_idx \
    $layout_idx \
    $sizeMB_idx \
    $infoOutDir \
    $maxSizeMB"

echo $pickRnd_cmd
$pickRnd_cmd

#2,3,4) execFasterQ_Kraken_update
#   a) parameters
createInfoFile_boolean='FALSE'

#   b) execution
execAll_cmd="$execFasterQKrakenUpdate_script \
    $runsToDo_file \
    $mainOutDir \
    $createInfoFile_boolean \
    $metadataAll_file"

echo $execAll_cmd
$execAll_cmd

#5) searchInAnalysis: (corona, coronavirus, sars-cov-2)

fieldIdxs_array=('6' '6' '5')
valueIdxs_array=('corona' 'coronavirus' '2697049')

n=${#fieldIdxs_array[@]}

for (( i=0; i<$n; i++ ))
do
    execSearch_cmd="$searchInAnalysis_script \
        $mainOutDir \
        ${fieldIdxs_array[$i]} \
        ${valueIdxs_array[$i]} \
        $researchesOutDir"

    echo $execSearch_cmd
    $execSearch_cmd

done