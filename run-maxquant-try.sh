#!/usr/bin/bash env

set -euo pipefail
trap 's=$?; echo >&2 "$0: Error on line "$LINENO": $BASH_COMMAND"; exit $s' ERR

function cleanup()
{
	echo "####################################ERROR#################################"
	echo "Process terminated - deleting log-file, mqpar-file and temporary results"
	echo "/proj/proteomics/$projname/mqpar/$filename.xml"
	rm -f "/proj/proteomics/log.txt"
	rm -f "/proj/proteomics/$projname/mqpar/$filename.xml"
	rm -rf "/proj/proteomics/$projname/results/results_run$runs_$filename"
}

trap cleanup ERR

# get start time & date
start=`date +%s`

Help()
{
   # Display Help
   echo "Run MaxQuant Analysis"
   echo
   echo "Syntax: run-maxquant.sh [-m|v|r|h|p|R|c]"
   echo "options:"
   echo "m     MaxQuant Filename without ending .xml - e.g. mqpar_210830"
   echo "p     Project Name - e.g. 20220406_FH_TR"
   echo "v     Version: new or old"
   echo "r     no. of runs"
   echo "R     perform post-processing in R"
   echo "c     use config-file"
   echo "h     Print this help"
   echo
}

# define pre-setting of variables
version="new"
runs=1
R="no"
c="no"

# get values of flags
while getopts hm:v:r:p:R:c: flag
do
    case "${flag}" in
        m) filename=${OPTARG};;
        v) version=${OPTARG};;
        r) runs=${OPTARG};;
        p) projname=${OPTARG};;
        R) R=${OPTARG};;
	c) c=${OPTARG};;
        h) # display Help
           Help
           exit;;
    esac
done

# check if config file should be used
if [ $c ==  "yes" ]; then
	source /proj/proteomics/config-file-proteomics
	filename=$m
	version=$v
	runs=$r
	projname=$p
	R=$R
	echo "Config-file used for data analysis" | tee -a log.txt
fi

#######################
# check directories
#######################
folder=/proj/proteomics/

if [ -d "$folder$projname" ]; then
  # Take action if $DIR exists. #
  cd $folder
  echo "#####################################" | tee -a log.txt
  echo "check directories" | tee -a log.txt
  echo "#####################################" | tee -a log.txt
  echo "Project Folder {$folder$projname} exists. Continue" | tee -a log.txt
  mkdir -p ./$projname/data ./$projname/mqpar ./$projname/results
else
  echo "Project Folder {$folder$projname} doesn't exists. Aborting..." | tee -a log.txt
  exit 1
fi

# check if mqpar file exsists
if [ -f "./$projname/mqpar/$filename.xml" ]; then
  echo "mqpar file ./$projname/mqpar/$filename.xml already exists. Aborting..." | tee -a log.txt
  echo "deleting log-file"
  rm ./log.txt
  exit 1
fi

# activate conda base environment
source /apps/anaconda3/etc/profile.d/conda.sh
conda activate base

# create mqpar file for QC samples
if [[ "$filename" == "QC" ]]; then
  export projname
  python ./bin/create-mqpar-file.py
  filename="mqpar_QC_$projname"
  mv ./mqpar_tmp/mqpar_QC_updated.xml ./mqpar_tmp/$filename.xml
  echo "mqpar file automated created - name: ./mqpar_tmp/$filename.xml" | tee -a log.txt
fi 

########################
# settings
#########################

echo "#####################################" | tee -a log.txt
echo "settings" | tee -a log.txt
echo "#####################################" | tee -a log.txt

echo "Filename: $filename" | tee log.txt
echo "Project name: $projname" | tee -a log.txt
echo "Version: $version" | tee -a log.txt
echo "No. of runs: $runs" | tee -a log.txt

#########################
# activate maxquant
#########################
echo "#####################################" | tee -a log.txt
echo "activate maxquant" | tee -a log.txt
echo "#####################################" | tee -a log.txt
if [ $version = "new" ]
then
	echo "new version of maxquant is used"
  	source /apps/anaconda3/etc/profile.d/conda.sh
	conda activate maxquant2
	echo "Current conda environment is $CONDA_DEFAULT_ENV" | tee -a log.txt

else
	echo "old version of maxquant is used"
  	source /apps/anaconda3/etc/profile.d/conda.sh
	conda activate maxquant
	echo "Current conda environment is $CONDA_DEFAULT_ENV" | tee -a log.txt
fi

###############################
#check and disable net core
###############################
echo "#####################################" | tee -a log.txt
echo "check and disable net core" | tee -a log.txt
echo "#####################################" | tee -a log.txt

search="<useDotNetCore>True"
replace="<useDotNetCore>False"

if [[ $search != "" && $replace != "" ]]; then
sed -i "s/$search/$replace/" ./mqpar_tmp/$filename.xml
echo "<useDotNetCore> was set to False" | tee -a log.txt
fi

###############################
# re-name path file paths 
###############################
#<path-to-current-xmlfile> --changeFolder <path-to-new-xmlfile> <path-to-fasta-folder> <path-to-rawfile-folder>

echo "#####################################" | tee -a log.txt
echo "re-naming paths in $filename.xml" | tee -a log.txt
echo "#####################################" | tee -a log.txt

maxquant ./mqpar_tmp/$filename.xml --changeFolder ./$projname/mqpar/$filename.xml ./fasta ./$projname/data | tee -a log.txt

START=1
END=$runs
 
for (( c=$START; c<=$END; c++ ))
do
    #re-name fixed combine folder
    sed -i "/<fixedCombinedFolder>/c\   <fixedCombinedFolder>\/proj\/proteomics\/$projname\/results\/results_run$c\_$filename<\/fixedCombinedFolder>" ./$projname/mqpar/$filename.xml
    echo "re-naming of combined folder sucessful" | tee -a log.txt
    ###############################
    # start maxquant
    ###############################
    echo "#####################################" | tee -a log.txt
    echo "run maxquant | run no. $c" | tee -a log.txt
    echo "#####################################" | tee -a log.txt
    maxquant ./$projname/mqpar/$filename.xml | tee -a log.txt
done

###############################
# post-processing
###############################

# post-processing only works if one run is performed
if [ $R ==  "yes" ] && [[ $runs == 1 ]]; then
    echo "#####################################" | tee -a log.txt
    echo "post-processing R" | tee -a log.txt
    echo "#####################################" | tee -a log.txt
    mkdir -p ./$projname/evaluation
    #path="/proj/proteomics/testR"
    path="/proj/proteomics/$projname/results/results\_run$runs\_$filename"
    Rscript ./bin/run-R.R $path
    #move file
    cp -rf ./$projname/results/results\_run$runs\_$filename/post-processing.html ./$projname/evaluation/post-processing-$filename.html
    rm -rf ./$projname/results/results\_run$runs\_$filename/post-processing.html
    if [ -f "/proj/proteomics/results_final.csv" ] ; then
        cp -rf /proj/proteomics/results_final.csv ./$projname/evaluation/results-$filename.csv
    	rm -rf /proj/proteomics/results_final.csv
    fi
    echo "post-processing R sucessful" | tee -a log.txt
    echo "result file: ./$projname/evaluation/post-processing-$filename.html" | tee -a log.txt
fi

###############################
# get run time
###############################
echo "#####################################" | tee -a log.txt
echo "runtime" | tee -a log.txt
echo "#####################################" | tee -a log.txt
#get runtime
end=`date +%s`
runtime=$((end-start))

hours=$((runtime / 3600)); minutes=$(( (runtime % 3600) / 60 )); seconds=$(( (runtime % 3600) % 60 ))

echo "Runtime: $hours:$minutes:$seconds (hh:mm:ss)" | tee -a log.txt

###############################
# clean up
###############################
echo "#####################################" | tee -a log.txt
echo "clean up" | tee -a log.txt
echo "#####################################" | tee -a log.txt

#move logfile
mv ./log.txt ./$projname/results/results_$filename.txt

#remove mqpar_temp file
mv ./mqpar_tmp/$filename.xml ./mqpar_tmp/done