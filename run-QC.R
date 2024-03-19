#!/usr/bin/Rscript

###############################################################################################################
# R script which reads in the file-path from run-maxquant.sh
# e.g. /proj/proteomics/11_20220713_FH/results/results_run1_mqpar_20220713_QC
# based on this path QC is performed using the PTXQC package
###############################################################################################################

# load libraries 
library(PTXQC)

# get parameters from bach srcipt
# https://www.r-bloggers.com/2015/02/bashr-howto-pass-parameters-from-bash-script-to-r/
args <- commandArgs()

# args[6] is the path defined in the bash script
# e.g. /proj/proteomics/11_20220713_FH/results/results_run1_mqpar_20220713_QC_delete
# pth <- "/proj/proteomics/11_20220713_FH/results/results_run1_mqpar_20220713_QC_delete"
pth <- args[6]
# for PTXQC the txt folder is needed
pth <- paste(pth,"/combined/txt",sep="")
# create report
createReport(txt_folder = pth)



