#!/bin/bash
if [ "$#" -ne 2 ]; then
    echo "the command 'get_config_filename.bash' requires two command line arguments: the analysis prefix, and the config file directory"
elif [[ -d "$2" ]]; then
    PREFIX="$1"
    CONFIG_DIR="$2"
    CONFIG_FILE=`grep -Pl "analysis_prefix[[:space:]]*:[[:space:]]*$PREFIX[[:space:]]*$" $CONFIG_DIR/*config`
    echo "$CONFIG_FILE"
else
    echo "the parameter $2 to get_config_filename.bash needs to be a directory"
fi
