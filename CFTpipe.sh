#!/bin/bash

home=~/transcriptomes/

# places paths to files ending in ".fastq" into an array
ARRAY=(`find $home -name '*.fastq'`)

# places files ending in ".fastq" into an array
ARRAY1=(`find $home -name '*.fastq' -exec basename {} \;`)                  

# for loop that iterates through ".fastq" files
for(( t=0; t<${#ARRAY[@]}; t++))
do

        echo $home
        echo $t                         # print current iteration
        echo ${ARRAY[$t]}               # print path t
        echo ${ARRAY1[$t]}              # print file t
        # length of the element located at index t
        x=${#ARRAY1[$t]}
	# removes last six characters (.fastq) from element located at index t
	BASE=${ARRAY1[$t]:0:$x-6}
	echo $BASE		        # print file without ".fastq"

	# run ConDeTri
        perl ~/ConDeTri/condetri_v2.2.pl -fastq1=${ARRAY[$t]} -prefix=$BASE -hq=25 -lq=10 -frac=.8 -minlen=50 -mh=45 -ml=5 -sc=33
        
        # move ConDeTri outputs to corresponding directories ("_trim.fastq" and ".stats")
        mv $BASE* $home$BASE

	# run FastQC
        ~/FastQC/fastqc -o=$home$BASE --noextract $home$BASE/$BASE"_trim.fastq"

done                                                                                  

# places paths to ConDeTri outputs into an array
ARRAY2=(`find $home -name '*_trim.fastq'`)                                  

# for loop that iterates through ConDeTri files
for(( t=0; t<${#ARRAY2[@]}; t++))                                                       
do                                                                                      

	echo $t                         # print current iteration
        echo ${ARRAY2[$t]}              # print path t
	# length of the element located at index t
        x=${#ARRAY2[$t]}
        # removes last eleven characters (_trim.fastq) from element located at index t
        path=${ARRAY2[$t]:0:$x-11}
        echo $path  			# print path without "_trim.fastq"                          
        
        # descriptively renames ConDeTri output                                      
        mv ${ARRAY2[$t]} $path"_m50_hq25_lq10_frac80_mh45_ml5_sc33.fq"         

        # run Trinity
        perl ~/../../c1/apps/trinity/r20131110/Trinity.pl --seqType fq --JM 10G  --single $path"_m50_hq25_lq10_frac80_mh45_ml5_sc33.fq"        

done
