#!/bin/bash
if [ "$#" -ne 3 ]; then
    echo "this command requires three command line arguments, a config file, a phenotype with_na file, and an output filename"
else
awk -F"\t" 'BEGIN {f = 0; keys["plco_id"]}
        FNR == 1 {f++}
	f == 1 && /^phenotype:/ {keys[$2] ; next}
	f == 1 && /^covariates:/ {
	  for ( i = 2; i <= NF; i++ ) {
	     keys[$i]
	  }
	  next
	}
	f == 2 && FNR == 1 {
		for ( i = 1; i <= NF; i++ ) {
			if ($i in keys) {
				columns[lf=i]
				printf("%s ", $i)
			}
		}
		printf("\n")
		next
	}
	f == 2 {
		for ( i = 1; i <= NF; i++ ) {
			if (i in columns) {
				printf("%s%s", $i, i == lf ? "\n" : " ")
			}
		}
	}' "$1" "$2" | sort > "$3"
fi
