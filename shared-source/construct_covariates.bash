#!/bin/bash
if [ "$#" -ne 2 ]; then
    echo "the command 'construct_covariates.bash' requires two command line arguments: the RUNID.CHIP prefix of an analysis, and the config file directory"
elif [[ -d "$2" ]]; then
    PREFIX="$1"
    CONFIG_DIR="$2"
    CONFIG_FILE=`echo "$PREFIX" | sed 's/\./\t/g' | awk '{print $1}' | grep -lwf - $CONFIG_DIR/*`
    COVARIATES=`grep -i covariate $CONFIG_FILE | cut -f 1 -d ' ' --complement | sed 's/ /,/g'`
    if [ -z "$COVARIATES" ]; then
	COVARIATES=NA
    fi
    echo "$COVARIATES"
else
    echo "the parameter $2 to construct_covariates.bash needs to be a directory"
fi
