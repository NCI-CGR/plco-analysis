#!/bin/bash

set -e -o pipefail

gwas_summary_stat_file=$1
ldsc_formatted_file=$2

zcat $gwas_summary_stat_file | awk 'NR > 1 {$7 = $7 / $8 ; print $1":"$2"\t"$4"\t"$5"\t"$6"\t"$7"\t"$9"\t"$10} ; NR == 1 {print "SNP\tTested_Allele\tOther_Allele\t{input.FREQ_COL}\tSTAT\tP\tN"}'  >  $ldsc_formatted_file