# Workflow for the evaluation of bottom-up proteomics data using MaxQuant and R

This repo contains a workflow which can be used for the processing of bottom-up proteomics data using MaxQuant and R.
After setting up the configuration file (mqpar) in MaxQuant using the windows GUI. All files (.raw files, fasta files and configuration files)
must be uploaded to the Linux server using the pre-defined folder structure.

* FASTA files: `/proj/proteomics/fasta/`
* RAW files: `/proj/proteomics/<project directory>/data/`
* MQPAR file: `/proj/proteomics/mqpar_tmp`

<img width="174" alt="folderstructureserver" src="https://user-images.githubusercontent.com/60740660/181258129-a56ac528-4b05-448b-9af5-c8a1f7818fdd.png">

The upload can be done using the `scp` with the following command:
`scp <file path in windows environment>/<with using slahes>/<fasta file.fasta> >username>@tubdsnode01:/proj/proteomics/<folder where the files should be uploaded`>

After uploading the script run-maxquant.sh which is available at `/proj/proteomics/run-maxquant.sh`could be run using the following syntax.

`run-maxquant.sh −m <file −name mqpar file> −p <name project directory> −r <number
of runs> −v <used MaxQuant version> -R <perform post-processing>`

The script contains also a help function which can be called using `run-maxquant.sh -h`. 

Additionally a config-file could be used to run the script.

`run-maxquant.sh −c yes`

The final results with the log file of data-analysis can be found in the folder `/proj/proteomics/<project directory>/results/`.

If post-processing is performed the results can be found in the folder `/proj/proteomics/<project directory>/evaluation/`.

For post-processing using R the markdown file `post-processing.Rmd` can be used. Here the user can define various settings. Based on the the data are filtered, summarized and vizualized. More details and explaination could be found in the Rmd file.

