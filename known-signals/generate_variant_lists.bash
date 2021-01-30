#!/bin/bash
function extract_results {
    if [[ ! -f "$2.txt" ]] ; then
	awk -F"\t" '{print $28"\t"$22"\t"$8}' gwas_catalog_v1.0-associations_e100_r2020-08-05.tsv | grep -iE "$1" | awk '! /conditioned/' | cut -f 1,2 | sed 's/;//g' | sort -k 2,2 -k 1,1g | sort -k 2,2 -s -u | sort -k 1,1g | head -20 | awk '{print $2"\t"$2}' > $2.txt ;
    fi
}

extract_results "psa|prostate-specific antigen" first_psa_level
#extract_results "colorectal cancer" j_colo_cancer
extract_results "endometrial cancer" j_endo_cancer
extract_results "breast cancer" j_breast_cancer
extract_results "^melanoma|malignant melanoma|malignant cutaneous melanoma" j_mela_cancer
extract_results "pancreatic" j_panc_cancer
extract_results "ovarian ca" j_osumm_cancer
#extract_results "prostate ca" j_pros_cancer
extract_results "lung ca" j_lung_cancer
extract_results "caffeine consumption" DT_CAFFEINE_DHQ
extract_results "serum cancer antigen 125 levels" first_ca125_level
#extract_results "chronic lymphocytic leukemia" j_cll
extract_results "intake of total sugars" DT_CARB_DHQ
## couldn't find relevant fat trait
## couldn't find relevant protein trait
extract_results "Smoking status \(ever vs never smokers\)" bq_cig_stat_o
