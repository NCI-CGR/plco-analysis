#!/bin/bash

set -e -o pipefail

study_id=$1
ldsc_log_file=$2
ldsc_report_file=$3


grep -E "Lambda GC|Intercept" $ldsc_log_file | sed 's/:/\t/g' | awk '/Lambda GC/ {printf("%s\t",$3)} ; /Intercept/ {print $2"\t"$3}' | awk -v STUDYID=$study_id '{print STUDYID"\t"$1}' > $ldsc_report_file