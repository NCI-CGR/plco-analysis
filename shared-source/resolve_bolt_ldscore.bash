#!/bin/bash
if [ "$#" -ne 2 ]; then
    echo "the command 'resolve_bolt_ldscore.bash' requires two command line arguments: the ancestry being analyzed, and the ldscore directory"
else
    ANCESTRY="$1"
    LDSC_DIRECTORY="$2"
    LDSC_PREFIX="${LDSC_DIRECTORY}/LDSCORE.1000G_"
    LDSC_SUFFIX=".l2.ldscore.gz"
    if [[ "$ANCESTRY" == "European" ]] ; then
	echo "${LDSC_PREFIX}EUR${LDSC_SUFFIX}" ;
    elif [[ "$ANCESTRY" == "Hispanic1" ]] || [[ "$ANCESTRY" == "Hispanic2" ]] ; then
	echo "${LDSC_PREFIX}AMR${LDSC_SUFFIX}" ;
    elif [[ "$ANCESTRY" == "East_Asian" ]] ; then
	echo "${LDSC_PREFIX}EAS${LDSC_SUFFIX}" ;
    elif [[ "$ANCESTRY" == "Other_Asian_or_Pacific_Islander" ]] || [[ "$ANCESTRY" == "Other" ]] ; then
	echo "${LDSC_PREFIX}ALL${LDSC_SUFFIX}" ;
    elif [[ "$ANCESTRY" == "African" ]] ; then
	echo "${LDSC_PREFIX}AFR${LDSC_SUFFIX}" ;
    elif [[ "$ANCESTRY" == "African_American" ]] ; then
	echo "${LDSC_PREFIX}AFRAMR${LDSC_SUFFIX}" ;
    elif [[ "$ANCESTRY" == "South_Asian" ]] ; then
	echo "${LDSC_PREFIX}SAS${LDSC_SUFFIX}" ;
    fi
fi
