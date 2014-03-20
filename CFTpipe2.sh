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

	# give ConDeTri output a more descriptive name
	mv $home/$BASE/$BASE"_trim.fastq" $home/$BASE/$BASE"_m50_hq25_lq10_frac80_mh30_ml5_sc33.fq"

	# make a Trinity shell that will be called by the SLURM
	echo '#!/bin/bash' > $home/$BASE/$BASE"_Trinity.sh"
	
	# add Trinity module to the shell
	echo 'module load trinity/r20131110'
	
	# add Trinity to the shell
	echo '# run Trinity' >> >> $home/$BASE/$BASE"_Trinity.sh"
	echo "perl $c1/apps/trinity/r20131110/Trinity.pl --seqType fq --JM 10G  --single $home/$BASE/"$BASE"_m50_hq25_lq10_frac80_mh30_ml5_sc33.fq' --output $home/$BASE/trinity_out_dir/" >> $home/$BASE/$BASE"_Trinity.sh"

	# add TrinityStats.pl to the shell
	echo '#run TrinityStats.pl' >> $home/$BASE/$BASE"_Trinity.sh"
	echo "perl $c1/apps/trinity/r20131110/util/TrinityStats.pl $home/$BASE/trinity_out_dir/Trinity.fasta > $home/$BASE/TrinityStats.txt" >> $home/$BASE/$BASE"_Trinity.sh"
	
	# add count_fasta.pl to the shell
	echo '#run count_fasta.pl' >> $home/$BASE/$BASE"_Trinity.sh"
	echo "perl ~/softWare/countFasta/count_fasta.pl -i 100 $home/$BASE/trinity_out_dir/Trinity.fasta > $home/$BASE/n50.txt" >> $home/$BASE/$BASE"_Trinity.sh"

	# add RSEM to the shell
	echo '#run RSEM' >> $home/$BASE/$BASE"_Trinity.sh"
	echo "perl $c1/apps/trinity/r20131110/util/RSEM_util/run_RSEM_align_n_estimate.pl --transcripts $home/$BASE/trinity_out_dir/Trinity.fasta --seqType fq --single $home/$BASE/"$BASE"_m50_hq25_lq10_frac80_mh30_ml5_sc33.fq" >> $home/$BASE/$BASE"_Trinity.sh"

	# make Trinity shell executable
	chmod u+x $home/$BASE/$BASE"_Trinity.sh"

	# make a SLURM shell to run Trinity
	echo '#!/bin/sh' > $home/$BASE/$BASE"_Trinity_SLURM.sh"
	
	# define the partition in the shell
	echo '# put job in "defq" partition' >> $home/$BASE/$BASE"_Trinity_SLURM.sh"
	echo '#SBATCH --partition=defq' >> $home/$BASE/$BASE"_Trinity_SLURM.sh"
	
	# request cores in the shell
	echo '# request one core' >> $home/$BASE/$BASE"_Trinity_SLURM.sh"
	echo '#SBATCH --nodes=1' >> $home/$BASE/$BASE"_Trinity_SLURM.sh"
	
	# set a wall in the shell
	echo '# three hour wall' >> $home/$BASE/$BASE"_Trinity_SLURM.sh"
	echo '#SBATCH --time=03:00:00' >> $home/$BASE/$BASE"_Trinity_SLURM.sh"
	
	# name the job in the shell
	echo '#SBATCH --job-name='$BASE'_SLURM' >> $home/$BASE/$BASE"_Trinity_SLURM.sh"
	
	# name output file in the shell
	echo '#SBATCH --output='$BASE'_SLURM.out' >> $home/$BASE/$BASE"_Trinity_SLURM.sh"
	
	# name error file in the shell
	echo '#SBATCH --error='$BASE'_SLURM.err' >> $home/$BASE/$BASE"_Trinity_SLURM.sh"
	
	# set email notifications in the shell
	echo '# notify on state change: BEGIN, END, FAIL or ALL' >> $home/$BASE/$BASE"_Trinity_SLURM.sh"
	echo '#SBATCH --mail-type=ALL' >> $home/$BASE/$BASE"_Trinity_SLURM.sh"
	echo '#SBATCH --mail-user=hansenms@gwu.edu' >> $home/$BASE/$BASE"_Trinity_SLURM.sh"
	
	# set requeue preference
	echo '#Specifies that the job will be requeued after a node failure.' >> $home/$BASE/$BASE"_Trinity_SLURM.sh"
	echo '#The default is that the job will not be requeued.' >> $home/$BASE/$BASE"_Trinity_SLURM.sh"
	echo '#SBATCH --requeue' >> $home/$BASE/$BASE"_Trinity_SLURM.sh"
	
	# execute the Trinity file in the shell
	echo "./"$BASE"_Trinity.sh"	>> $home/$BASE/$BASE"_Trinity_SLURM.sh"
	
	# call the SLURM file
	sbatch $home/$BASE/$BASE"_Trinity_SLURM.sh"

done
