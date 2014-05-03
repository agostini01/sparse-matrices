#!/bin/bash
# Tomas Nesrovnal, nesro@nesro.cz, Copyright 2014
# https://github.com/nesro/sparse-matrices

if false; then
	export big_list="cage12 ldoor Freescale1 thermal2 atmosmodj nlpkkt120"
	export big_dir_mat=../big_matrices
	export big_dir_vec=../big_vectors
else
	export big_list="c-23 eurqsa GT01R"
	export big_dir_mat=../test_matrices
	export big_dir_vec=../test_matrices
fi

function gnuplot_wrapper {
	input_filename=$1
	output_filename=$2
	xlabel=$3
	ylabel=$4
	nlines=$5
	
	plot="plot \"$input_filename\" using $nlines:1"
	for (( i=2; i<nlines; i++ )); do
		plot+=", \"\" using $nlines:$i"
	done  
	
	# set term png size 1024,786
	
	gnuplot << __EOF__
		set term pdf
		set output "$output_filename"
		set pointsize 2
		set style data point
		
		set logscale y

		set key top left reverse Left
		set key autotitle columnhead
		set key title "Legend"
		set key box width 1 height 1

		set ylabel "$ylabel"
		set xlabel "$xlabel"

		$plot
__EOF__
}

function check_code {
	code=$1
	if [[ $code -ne 0 ]]; then
		echo "Previous command has failed. Exiting."
		exit 1
	fi
}


#gnuplot_wrapper test.txt test.png "xlabel" "ylabel" 3
