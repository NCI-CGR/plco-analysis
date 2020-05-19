#!/bin/bash
SAMPLE_MIN_COUNT_FASTGWA=1000
SAMPLE_MIN_COUNT_BOLTLMM=2100
SAMPLE_MIN_COUNT_SAIGE=1000
if [ "$#" -ne 2 ]; then
    echo "the command 'construct_output_filenames.bash' requires two command line arguments: the name of the config file, and the software (saige, bolt, fastgwa) requested"
else
    CONFIG_FILE="$1"
    REQUESTED_SOFTWARE="$2"
    ANALYSIS_PREFIX=`grep -i analysis_prefix $CONFIG_FILE | awk '{print $2}'`
    REQUESTED_CHIPS=`grep -i chips $CONFIG_FILE | cut -f 1 -d ' ' --complement`
    REQUESTED_ANCESTRIES=`grep -i ancestries $CONFIG_FILE | cut -f 1 -d ' ' --complement`
    REQUESTED_ALGORITHM=`grep -i algorithm $CONFIG_FILE | grep -i $REQUESTED_SOFTWARE -`
    SAMPLE_MIN_COUNT=0
    if [ "${REQUESTED_SOFTWARE^^}" == "BOLTLMM" ] ; then
	SAMPLE_MIN_COUNT=$SAMPLE_MIN_COUNT_BOLTLMM ;
    elif [ "${REQUESTED_SOFTWARE^^}" == "FASTGWA" ] ; then
	SAMPLE_MIN_COUNT=$SAMPLE_MIN_COUNT_FASTGWA ;
    elif [ "${REQUESTED_SOFTWARE^^}" == "SAIGE" ] ; then
	SAMPLE_MIN_COUNT=$SAMPLE_MIN_COUNT_SAIGE ;
    fi
    for chip in $REQUESTED_CHIPS;
    do
	for ancestry in $REQUESTED_ANCESTRIES;
	do
	    if [[ ! -z "$REQUESTED_ALGORITHM" ]] && [ -d "../raw-by-ancestry/${chip/_//}/${ancestry}" ] && [ -f "../bgen-format/${chip/_//}/${ancestry}/chr22-filtered-noNAs.sample" ] ; then \
		LINE_COUNT=`wc -l ../bgen-format/${chip/_//}/${ancestry}/chr22-filtered-noNAs.sample | awk '{print $1}'` ; if [[ "$LINE_COUNT" -gt "$SAMPLE_MIN_COUNT" ]] ; then echo $ANALYSIS_PREFIX/${ancestry}/${REQUESTED_SOFTWARE^^}/$ANALYSIS_PREFIX.$chip.$REQUESTED_SOFTWARE ; fi
	    fi
	done
    done
fi
