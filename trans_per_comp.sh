#!/bin/bash

#keep track of when files were made
pwd >> histogram.txt
date >> histogram.txt
echo >> histogram.txt

#prepare for while loop
declare -i num=1
tran=1
declare -i count=0

#intitate while loop
while(( $tran != 0 ))
do
	#count the number of lines that have "seq1", "seq2", "seq3", etc. in them
	tran=$(grep -c "seq$num " Trinity.fasta)
	declare -i filter[$count]=$tran
	
	#output the number number of lines that have "seq1", "seq2", "seq3", etc. in them
	if(( $tran != 0 ))
	then
		echo "There are $tran components with $num sequence(s)." >> histogram.txt
		num=($num+1)
		count=($count+1)
	fi
done

#prepare for while loop
num=($num-1)
declare -i i=0
echo >> histogram.txt

#initiate while loop
while(( $i < $count))
do
	#calculate and output the percent of sequences that compose each component
	declare -i comp=${filter[$i]}-${filter[$i+1]}
	i=($i+1)
	percent=$(echo "scale=5; ($comp/${filter[0]})*100" | bc)
	echo "$comp components have a total of $i isoform(s): $percent%" >> histogram.txt
done

