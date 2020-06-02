#!/bin/bash
if [ "$#" -ne 2 ]; then
    echo "the command 'construct_phenotype.bash' requires two command line arguments: the analysis prefix, and the config file directory"
elif [[ -d "$2" ]]; then
    PREFIX="$1"
    CONFIG_DIR="$2"
    CONFIG_FILE=`grep -Pl "analysis_prefix[[:space:]]*:[[:space:]]*$PREFIX[[:space:]]*$" $CONFIG_DIR/*`
    PHENOTYPE=`grep -i phenotype $CONFIG_FILE | cut -f 1 -d ' ' --complement`
    echo "$PHENOTYPE"
else
    echo "the parameter $2 to construct_phenotype.bash needs to be a directory"
fi
