#!/bin/bash

ARRAY=(`find ~/transcriptomes/ -name '*.fastq'`)                                        # places paths to files ending in .fastq into an array
ARRAY1=(`find ~/transcriptomes/ -name '*.fastq' -exec basename {} \;`)                  # places files ending in .fastq into an array

for(( t=0; t<${#ARRAY[@]}; t++))                                                        # for loop that iterates through .fastq files
do                                                                                      # begin ConDeTri & FastQC for loop

        echo $t                                                                         # print current iteration
        echo ${ARRAY[$t]}                                                               # print path t
        echo ${ARRAY1[$t]}                                                              # print file t
        x=${#ARRAY1[$t]}                                                                # length of the element located at index t
        echo ${ARRAY1[$t]:0:$x-6}                                                       # removes last six characters (.fastq) from element located at index t


        perl ~/ConDeTri/condetri_v2.2.pl -fastq1=${ARRAY[$t]} -prefix=${ARRAY1[$t]:0:$x-6} -hq=25 -lq=10 -frac=.8 -minlen=50 -mh=45 -ml=5 -sc=33        # run ConDeTri
        mv ${ARRAY1[$t]:0:$x-6}* ~/transcriptomes/${ARRAY1[$t]:0:$x-6}                  # move ConDeTri outputs to corresponding directories ("_trim.fastq" and ".stats")

        ./~/FastQC/fastqc -o=~/transcriptomes/${ARRAY1[$t]:0:$x-6}/ --noextract ~/transcriptomes/${ARRAY1[$t]:0:$x-6}/${ARRAY1[$t]:0:$x-6}_trim.fastq   # run FastQC

done                                                                                    # end ConDeTri & FastQC for loop

ARRAY2=(`find ~/transcriptomes/ -name '*_trim.fastq'`)                                  # places paths to ConDeTri outputs into an array

for(( t=0; t<${#ARRAY2[@]}; t++))                                                       # for loop that iterates through ConDeTri files
do                                                                                      # begin Trinity for loop

        x=${#ARRAY2[$t]}                                                                # length of the element located at index t
        mv ${ARRAY2[$t]} ${ARRAY2[$t]:0:$x-11}_m50_hq25_lq10_frac80_mh45_ml5.fq         # descriptively renames ConDeTri output

        perl ~/../../c1/apps/trinity/r20131110/Trinity.pl --seqType fq --JM 10G  --single ${ARRAY2[$t]:0:$x-11}_m50_hq25_lq10_frac80_mh45_ml5.fq        # run Trinity

done                                                                                    # end Trinity for loop
