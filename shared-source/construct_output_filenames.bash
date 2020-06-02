#!/bin/bash
if [ "$#" -ne 4 ]; then
    echo "the command 'construct_output_filenames.bash' requires four command line arguments: the name of the config file, the software (saige, bolt, fastgwa) requested, the minimum sample count for the software, and the directory prefix for all bgen files"
else
    CONFIG_FILE="$1"
    REQUESTED_SOFTWARE="$2"
    SAMPLE_MIN_COUNT="$3"
    BGEN_PREFIX="$4"
    ANALYSIS_PREFIX=`grep -i analysis_prefix $CONFIG_FILE | awk '{print $2}'`
    REQUESTED_CHIPS=`grep -i chips $CONFIG_FILE | cut -f 1 -d ' ' --complement`
    REQUESTED_ANCESTRIES=`grep -i ancestries $CONFIG_FILE | cut -f 1 -d ' ' --complement`
    REQUESTED_ALGORITHM=`grep -i algorithm $CONFIG_FILE | grep -i $REQUESTED_SOFTWARE -`
    for chip in $REQUESTED_CHIPS;
    do
	for ancestry in $REQUESTED_ANCESTRIES;
	do
	    if [[ ! -z "$REQUESTED_ALGORITHM" ]] && [ -d "$BGEN_PREFIX/${chip/_//}/${ancestry}" ] && [ -f "$BGEN_PREFIX/${chip/_//}/${ancestry}/chr22-filtered-noNAs.sample" ] ; then \
                PLINK_TAG=".assoc.linear"
                CONFIG_FILE_MENTIONS_SAIGE=`grep -i "saige" $CONFIG_FILE | wc -l | awk '{print $1}'`
                if [[ "$CONFIG_FILE_MENTIONS_SAIGE" -gt "0" ]] ; then
                    PLINK_TAG=".assoc.logistic" ;
                fi
                REPORT_SUFFIX=""
                if [[ "${REQUESTED_SOFTWARE^^}" == "PLINK" ]] ; then
                    REPORT_SUFFIX="$PLINK_TAG" ;
                fi
		LINE_COUNT=`wc -l $BGEN_PREFIX/${chip/_//}/${ancestry}/chr22-filtered-noNAs.sample | awk '{print $1}'` ; if [[ "$LINE_COUNT" -gt "$SAMPLE_MIN_COUNT" ]] ; then echo $ANALYSIS_PREFIX/${ancestry}/${REQUESTED_SOFTWARE^^}/$ANALYSIS_PREFIX.$chip.$REQUESTED_SOFTWARE$REPORT_SUFFIX ; fi
	    fi
	done
    done
fi
