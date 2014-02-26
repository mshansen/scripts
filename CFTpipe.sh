#!/bin/bash

home=~/transcriptomes
c1=~/../../c1

# places paths to files ending in ".fastq" into an array
ARRAY=(`find $home -name '*.fastq'`)

# places files ending in ".fastq" into an array
ARRAY1=(`find $home -name '*.fastq' -exec basename {} \;`)                  

# for loop that iterates through ".fastq" files
for(( t=0; t<${#ARRAY[@]}; t++))
do

	echo $home
	echo $t				# print current iteration
	echo ${ARRAY[$t]}	# print path t
	echo ${ARRAY1[$t]}	# print file t
	# length of the element located at index t
	x=${#ARRAY1[$t]}
	# removes last six characters (.fastq) from element located at index t
	BASE=${ARRAY1[$t]:0:$x-6}
	echo $BASE			# print file without ".fastq"

	# run ConDeTri
	perl ~/softWare/ConDeTri/condetri_v2.2.pl -fastq1=${ARRAY[$t]} -prefix=$BASE -hq=25 -lq=10 -frac=.8 -minlen=50 -mh=30 -ml=5 -sc=33
        
	# move ConDeTri outputs to corresponding directories ("_trim.fastq" and ".stats")
	mv $BASE* $home/$BASE

	# run FastQC
	~/softWare/FastQC/fastqc -o=$home/$BASE --noextract $home/$BASE/$BASE"_trim.fastq"

done                                                                                  

# places paths to ConDeTri outputs into an array
ARRAY2=(`find $home -name '*_trim.fastq'`)

# places files ending in "_trim.fastq" into an array
ARRAY3=(`find $home -name '*_trim.fastq' -exec basename {} \;`)

# for loop that iterates through ConDeTri files
for(( t=0; t<${#ARRAY2[@]}; t++))                                                       
do                                                                                      

	echo $t				# print current iteration
	echo ${ARRAY2[$t]}	# print path t
	# length of the element located at index t
	x=${#ARRAY2[$t]}
	# removes last eleven characters (_trim.fastq) from element located at index t and adds descriptive suffix
	path=${ARRAY2[$t]:0:$x-11}"_m50_hq25_lq10_frac80_mh30_ml5_sc33.fq" 
	echo $path  		# print path without "_trim.fastq"
        
	# length of the element located at index t
	y=${#ARRAY3[$t]}
	# removes last eleven characters (_trim.fastq) from element located at index t
	BASE=${ARRAY3[$t]:0:$y-11}                          
        
	# descriptively renames ConDeTri output                                      
	mv ${ARRAY2[$t]} $path        

	# run Trinity
	perl $c1/apps/trinity/r20131110/Trinity.pl --seqType fq --JM 10G  --single $path --output $home/$BASE/trinity_out_dir/

	#run TrinityStats.pl
	perl $c1/apps/trinity/r20131110/util/TrinityStats.pl $home/$BASE/trinity_out_dir/Trinity.fasta > $home/$BASE/TrinityStats.txt
	
	#run count_fasta.pl
	perl ~/softWare/countFasta/count_fasta.pl -i 100 $home/$BASE/trinity_out_dir/Trinity.fasta > $home/$BASE/n50.txt

	#run RSEM
	perl $c1/apps/trinity/r20131110/util/RSEM_util/run_RSEM_align_n_estimate.pl --transcripts $home/$BASE/trinity_out_dir/Trinity.fasta --seqType fq --single $path 

done
