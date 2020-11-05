#!/bin/bash
if [ "$#" -ne 20 ]; then
    echo "the command 'construct_output_filenames.bash' requires nineteen command line arguments: the name of the config file, the software (saige, bolt, fastgwa) requested, the minimum sample count for the software, the directory prefix for all bgen files, the pipeline results toplevel directory, the phenotype file currently in use, the column extractor program, the phenotype file used tracker file suffix, the frequency mode tracker file suffix, the id mode tracker file suffix, the phenotype model tracker file suffix, the covariate model tracker file suffix, the category level tracker file suffix, the phenotype transformation tracker file suffix, the sex-specific analysis selection tracker file suffix, the control inclusion tracker file suffix, the control exclusion tracker file suffix, the finalized analysis tracker file suffix, binary indicator of whether make -B is in effect, and a binary indicator of whether make -n is in effect"
else
    CONFIG_FILE="$1"
    REQUESTED_SOFTWARE="$2"
    SAMPLE_MIN_COUNT="$3"
    BGEN_PREFIX="$4"
    RESULTS_PREFIX="$5"
    PHENOTYPE_FILENAME="$6"
    COLUMN_EXTRACTOR="$7"
    PHENOTYPE_USED_TRACKER_SUFFIX="$8"
    FREQUENCY_MODE_TRACKER_SUFFIX="$9"
    ID_MODE_TRACKER_SUFFIX="${10}"
    PHENOTYPE_SELECTED_TRACKER_SUFFIX="${11}"
    COVARIATES_SELECTED_TRACKER_SUFFIX="${12}"
    CATEGORY_TRACKER_SUFFIX="${13}"
    TRANSFORMATION_TRACKER_SUFFIX="${14}"
    SEX_SPECIFIC_TRACKER_SUFFIX="${15}"
    CONTROL_INCLUSION_TRACKER_SUFFIX="${16}"
    CONTROL_EXCLUSION_TRACKER_SUFFIX="${17}"
    FINALIZED_ANALYSIS_TRACKER_SUFFIX="${18}"
    FORCE_RUN="${19}"
    PRETEND_RUN="${20}"

    ## python yaml helper functions
    declare -A PARSED_YAML
    ## for version reasons, this can't be wrapped in a function
    raw_lines=`python3 -c "import yaml; print(yaml.safe_load(open('$1')))" 2> /dev/null`
    if [[ "$raw_lines" =~ ^\{.*\}$ ]] ; then
	lines=`echo "$raw_lines" | sed -E "s/('[^:,']+'): ('[^']+')/\1: \2\n/g ; s/],/]\n/g ; s/\{// ; s/\}//" | sed "s/^,// ; s/\[// ; s/]// ; s/ //g ; s/'//g"`
	for line in `echo "$lines" | sed 's/ /\n/g'`;
	do
	    PARSED_YAML[`echo "$line" | cut -f 1 -d ":"`]=`echo "$line" | cut -f 2 -d ":"`
	done
    else
	## this should have been caught upstream by the config test suite, so just die here in this case
	echo "config failure detected, terminating: \"$raw_lines\""
	exit 1
    fi
    ## previous versons of this implementation had distinct behaviors for these two functions; leaving as is for now
    yaml() {
	echo "${PARSED_YAML[$1]//,/ }"
    }
    yaml_check_exists() {
	echo "${PARSED_YAML[$1]//,/ }"
    }

    ANALYSIS_PREFIX=$(yaml analysis_prefix)
    REQUESTED_CHIPS=$(yaml chips)
    REQUESTED_ANCESTRIES=$(yaml ancestries)
    REQUESTED_ALGORITHM=$(yaml algorithm)

    ## only compute this either the first time, or when the analysis as a whole is being reevaluated
    PHENOTYPE=$(yaml phenotype)
    FACTORIZATION="NA"
    if [[ "${REQUESTED_ALGORITHM^^}" == *"SAIGE"* ]] ; then
    FACTORIZATION=`awk -F"\t" -v trait=$PHENOTYPE 'BEGIN {COL=0}
    		       NR == 1 { for ( i = 1 ; i <= NF ; i++ ) { if ( $i == trait ) {COL=i} } }
		       NR > 1 { print $COL }' "$PHENOTYPE_FILENAME" | sort | uniq -c | awk '$2 != "NA"' | sort -k 1,1gr |
		          awk 'BEGIN {nsmall=0}
			       NR == 1 {ref=$2}
			       NR > 1 && $1 >= 100 {print ref"\t"$2}
			       NR > 1 && $1 < 100  {alt[$2] ; nsmall++}
			       END { if (nsmall > 0) { printf("%s\t", ref) ; for ( i in alt ) {printf("%s+", i)}}}' | awk '{print $0}' | sed 's/+$//'`
    fi
    
    for chip in $REQUESTED_CHIPS;
    do
	for ancestry in $REQUESTED_ANCESTRIES;
	do
	    if [[ "$REQUESTED_ALGORITHM" == *"$REQUESTED_SOFTWARE"* ]] &&
		   [ -d "$BGEN_PREFIX/${chip/_//}/${ancestry}" ] &&
		   [ -f "$BGEN_PREFIX/${chip/_//}/${ancestry}/chr22-filtered-noNAs.sample" ] ; then \
                PLINK_TAG=".assoc.linear"
                if [[ "${REQUESTED_ALGORITHM^^}" == *"SAIGE"* ]] ; then
                    PLINK_TAG=".assoc.logistic" ;
                fi
                REPORT_SUFFIX=""
                if [[ "${REQUESTED_SOFTWARE^^}" == "PLINK" ]] ; then
                    REPORT_SUFFIX="$PLINK_TAG" ;
                fi
		LINE_COUNT=`wc -l $BGEN_PREFIX/${chip/_//}/${ancestry}/chr22-filtered-noNAs.sample | awk '{print $1}'`
		if [[ "$LINE_COUNT" -gt "$SAMPLE_MIN_COUNT" ]] ; then
		    RESULTDIR="$ANALYSIS_PREFIX/${ancestry}/${REQUESTED_SOFTWARE^^}"
		    RESULT="$RESULTDIR/$ANALYSIS_PREFIX.$chip.$REQUESTED_SOFTWARE"


		    PHENOTYPE_USED_TRACKER="$RESULTS_PREFIX/$RESULT$PHENOTYPE_USED_TRACKER_SUFFIX"
		    FREQUENCY_MODE_TRACKER="$RESULTS_PREFIX/$RESULT$FREQUENCY_MODE_TRACKER_SUFFIX"
		    ID_MODE_TRACKER="$RESULTS_PREFIX/$RESULT$ID_MODE_TRACKER_SUFFIX"
		    PHENOTYPE_SELECTED_TRACKER="$RESULTS_PREFIX/$RESULT$PHENOTYPE_SELECTED_TRACKER_SUFFIX"
		    COVARIATES_SELECTED_TRACKER="$RESULTS_PREFIX/$RESULT$COVARIATES_SELECTED_TRACKER_SUFFIX"
		    TRANSFORMATION_TRACKER="$RESULTS_PREFIX/$RESULT$TRANSFORMATION_TRACKER_SUFFIX"
		    SEX_SPECIFIC_TRACKER="$RESULTS_PREFIX/$RESULT$SEX_SPECIFIC_TRACKER_SUFFIX"
		    CONTROL_INCLUSION_TRACKER="$RESULTS_PREFIX/$RESULT$CONTROL_INCLUSION_TRACKER_SUFFIX"
		    CONTROL_EXCLUSION_TRACKER="$RESULTS_PREFIX/$RESULT$CONTROL_EXCLUSION_TRACKER_SUFFIX"
		    FINALIZED_ANALYSIS_TRACKER="$RESULTS_PREFIX/$RESULT$FINALIZED_ANALYSIS_TRACKER_SUFFIX"
		    

		    ## for tracking reasons, be certain this directory exists
		    if [[ ! -d "$RESULTS_PREFIX/$RESULTDIR" ]] ; then
			mkdir -p "$RESULTS_PREFIX/$RESULTDIR"
		    fi

		    ## tracking whether the indicators should be updated in bulk. Allows manual override as well,
		    ## specifically if make was invoked with -B
		    UPDATE_BUNDLE="$FORCE_RUN"
		    ## run phenotype tracking/version difference testing
		    if [[ -f "$PHENOTYPE_USED_TRACKER" && "$PRETEND_RUN" -eq "0" ]] ; then
			## if the current phenotype filename is different than the one in use
			USED_FILENAME=`cat "$PHENOTYPE_USED_TRACKER"`
			if [[ "$USED_FILENAME" != "$PHENOTYPE_FILENAME" ]] ; then
			    ## actually running the full model matrix comparison is slow due to the size of the phenotype file
			    ## so check the log of compatible phenotype files to see if this one has been scanned previously
			    RESCAN_REQUIRED="0"
			    if [[ -f "$PHENOTYPE_USED_TRACKER.history" ]] ; then
				PREVIOUSLY_OK=`grep -w "$PHENOTYPE_FILENAME" $PHENOTYPE_USED_TRACKER.history`
				if [[ -z "$PREVIOUSLY_OK" ]] ; then
				    RESCAN_REQUIRED="1"
				fi
			    else
				RESCAN_REQUIRED="2"
			    fi
			    if [[ "$RESCAN_REQUIRED" -gt "0" ]] ; then
				## get phenotype and covariates requested for this analysis
				"$COLUMN_EXTRACTOR" "$CONFIG_FILE" "$PHENOTYPE_FILENAME" "$RESULT.raw_phenotypes_new"
				"$COLUMN_EXTRACTOR" "$CONFIG_FILE" "$USED_FILENAME" "$RESULT.raw_phenotypes_current"
				PHENOTYPE_DIFFERENCE=`diff "$RESULT.raw_phenotypes_new" "$RESULT.raw_phenotypes_current" | wc -l`
				rm "$RESULT.raw_phenotypes_new" "$RESULT.raw_phenotypes_current"
				if [[ "$PHENOTYPE_DIFFERENCE" -gt "0" ]] ; then
				    ## change between versions. Emit output prefix
				    echo "$PHENOTYPE_FILENAME" > "$PHENOTYPE_USED_TRACKER.history"
				    UPDATE_BUNDLE="1"
				else
				    ## new version but compatible with old
				    echo "$PHENOTYPE_FILENAME" >> "$PHENOTYPE_USED_TRACKER.history"
				fi
			    fi
			fi
		    elif [[ "$PRETEND_RUN" -eq "0" ]] ; then
			## the tracker didn't exist. This should conceptually trigger the model matrix build, and everything else
			echo "$PHENOTYPE_FILENAME" > "$PHENOTYPE_USED_TRACKER.history"
			UPDATE_BUNDLE="1"
		    fi

		    ## run phenotype selection tracking/version difference testing
		    if [[ -f "$PHENOTYPE_SELECTED_TRACKER" ]] ; then
			USED_PHENOTYPE=`cat $PHENOTYPE_SELECTED_TRACKER`
			if [[ "$PHENOTYPE" != "$USED_PHENOTYPE" ]] ; then
			    UPDATE_BUNDLE="1"
			fi
		    else
			UPDATE_BUNDLE="1"
		    fi

		    ## run covariate selection tracking/version difference testing
		    COVARIATES="NA"
		    if [[ ! -z $(yaml_check_exists covariates) ]] ; then
			COVARIATES=$(yaml covariates)
			COVARIATES=${COVARIATES// /,}
		    fi
		    if [[ -f "$COVARIATES_SELECTED_TRACKER" ]] ; then
			USED_COVARIATES=`cat "$COVARIATES_SELECTED_TRACKER"`
			if [[ "$COVARIATES" != "$USED_COVARIATES" ]] ; then
			    UPDATE_BUNDLE="1"
			fi
		    else
			UPDATE_BUNDLE="1"
		    fi

		    ## run frequency reporting mode tracking/version difference testing
		    FREQUENCY_UPDATED="0"
		    if [[ "$PRETEND_RUN" -eq "0" ]] ; then
			FREQUENCY_MODE="reference"
			if [[ ! -z $(yaml_check_exists frequency_mode) ]] ; then
			    FREQUENCY_MODE=$(yaml frequency_mode)
			fi
			if [[ -f "$FREQUENCY_MODE_TRACKER" ]] ; then
			    EXISTING_FREQUENCY_MODE=`cat $FREQUENCY_MODE_TRACKER`
			    if [[ "$EXISTING_FREQUENCY_MODE" != "$FREQUENCY_MODE" ]] ; then
				echo "$FREQUENCY_MODE" > "$FREQUENCY_MODE_TRACKER"
				FREQUENCY_UPDATED="1"
			    fi
			else
			    echo "$FREQUENCY_MODE" > "$FREQUENCY_MODE_TRACKER"
			    FREQUENCY_UPDATED="1"
			    rm -f "$FINALIZED_ANALYSIS_TRACKER"
			fi
			## allow manual override
			if [[ "$FORCE_RUN" -gt "0" ]] ; then
			    FREQUENCY_UPDATED="1"
			    echo "$FREQUENCY_MODE" > "$FREQUENCY_MODE_TRACKER"
			fi
		    fi

		    ## run ID reporting mode tracking/version difference testing
		    ID_UPDATED="0"
		    if [[ "$PRETEND_RUN" -eq "0" ]] ; then
			ID_MODE="chrpos"
			if [[ ! -z $(yaml_check_exists id_mode) ]] ; then
			    ID_MODE=$(yaml id_mode)
			fi
			if [[ -f "$ID_MODE_TRACKER" ]] ; then
			    EXISTING_ID_MODE=`cat $ID_MODE_TRACKER`
			    if [[ "$EXISTING_ID_MODE" != "$ID_MODE" ]] ; then
				ID_UPDATED="1"
				echo "$ID_MODE" > "$ID_MODE_TRACKER"
			    fi
			else
			    ID_UPDATED="1"
			    echo "$ID_MODE" > "$ID_MODE_TRACKER"
			    rm -f "$FINALIZED_ANALYSIS_TRACKER"
			fi
			## allow manual override
			if [[ "$FORCE_RUN" -gt "0" ]] ; then
			    ID_UPDATED="1"
			    echo "$ID_MODE" > "$ID_MODE_TRACKER"
			fi
		    fi

		    ## run phenotype transformation mode tracking/version difference testing
		    TRANSFORMATION="none"
		    if [[ ! -z $(yaml_check_exists transformation) ]] ; then
			TRANSFORMATION=$(yaml transformation)
		    fi
		    if [[ -f "$TRANSFORMATION_TRACKER" ]] ; then
			EXISTING_TRANSFORMATION=`cat $TRANSFORMATION_TRACKER`
			if [[ "$EXISTING_TRANSFORMATION" != "$TRANSFORMATION" ]] ; then
			    UPDATE_BUNDLE="1"
			fi
		    else
			UPDATE_BUNDLE="1"
		    fi


		    ## run phenotype transformation mode tracking/version difference testing
		    SEX_SPECIFIC="combined"
		    if [[ ! -z $(yaml_check_exists sex-specific) ]] ; then
			SEX_SPECIFIC=$(yaml sex-specific)
		    fi
		    if [[ -f "$SEX_SPECIFIC_TRACKER" ]] ; then
			EXISTING_SEX_SPECIFIC=`cat $SEX_SPECIFIC_TRACKER`
			if [[ "$EXISTING_SEX_SPECIFIC" != "$SEX_SPECIFIC" ]] ; then
			    UPDATE_BUNDLE="1"
			fi
		    else
			UPDATE_BUNDLE="1"
		    fi

		    ## run control inclusion tracking/version difference testing
		    ## defaults to: don't use any filters, just include everyone valid
		    CONTROL_INCLUSION="NA"
		    if [[ ! -z $(yaml_check_exists control_inclusion) ]] ; then
			CONTROL_INCLUSION=$(yaml control_inclusion)
		    fi
		    if [[ -f "$CONTROL_INCLUSION_TRACKER" ]] ; then
			EXISTING_CONTROL_INCLUSION=`cat $CONTROL_INCLUSION_TRACKER`
			if [[ "$EXISTING_CONTROL_INCLUSION" != "$CONTROL_INCLUSION" ]] ; then
			    UPDATE_BUNDLE="1"
			fi
		    else
			UPDATE_BUNDLE="1"
		    fi
		    
		    ## run control exclusion tracking/version difference testing
		    ## defaults to: don't use any filters, just include everyone valid
		    CONTROL_EXCLUSION="NA"
		    if [[ ! -z $(yaml_check_exists control_exclusion) ]] ; then
			CONTROL_EXCLUSION=$(yaml control_exclusion)
		    fi
		    if [[ -f "$CONTROL_EXCLUSION_TRACKER" ]] ; then
			EXISTING_CONTROL_EXCLUSION=`cat $CONTROL_EXCLUSION_TRACKER`
			if [[ "$EXISTING_CONTROL_EXCLUSION" != "$CONTROL_EXCLUSION" ]] ; then
			    UPDATE_BUNDLE="1"
			fi
		    else
			UPDATE_BUNDLE="1"
		    fi

		    ## if any of the model matrix configuration options need updating,
		    ## update all of them to ensure synchronicity.
		    if [[ "$PRETEND_RUN" -gt "0" ]] ; then
			UPDATE_BUNDLE="0"
		    fi
		    if [[ "$UPDATE_BUNDLE" -gt "0" ]] ; then
			echo "$PHENOTYPE_FILENAME" > "$PHENOTYPE_USED_TRACKER"
			echo "$PHENOTYPE" > "$PHENOTYPE_SELECTED_TRACKER"
			echo "$COVARIATES" > "$COVARIATES_SELECTED_TRACKER"
			echo "$TRANSFORMATION" > "$TRANSFORMATION_TRACKER"
			echo "$SEX_SPECIFIC" > "$SEX_SPECIFIC_TRACKER"
			echo "$CONTROL_INCLUSION" > "$CONTROL_INCLUSION_TRACKER"
			echo "$CONTROL_EXCLUSION" > "$CONTROL_EXCLUSION_TRACKER"
			rm -f "$FINALIZED_ANALYSIS_TRACKER"
		    fi

		    ## for storage efficiency reasons an analysis can be in a "finalized" state, which
		    ## is triggered externally. This program can however remove the finalized condition if
		    ## configuration options have changed. A finalized analysis has a very aggressive set of
		    ## removed files that likely breaks dependency tracking; so if the analysis is finalized
		    ## and none of the configuration tracking files have changed, then do not report this
		    ## analysis as a tracking candidate to the workflow unless make -B has been invoked.
		    if [[ ! -f "$FINALIZED_ANALYSIS_TRACKER" ]] ; then
			SUPPRESS_CENTRAL_DIRECTORY="0"
			## run category tracking. this is a complicated hack to make the SAIGE binary pipeline work with categorical variables
			## skip when outcome is continuous
			if [[ "$CATEGORY_TRACKER_SUFFIX" != "NA" ]] ; then
			    N_COMPARISONS=`echo "$FACTORIZATION" | wc -l`
			    if [[ "$N_COMPARISONS" -gt "1" ]] ; then
				## there is more than one comparison to be done; this requires splitting the analysis into multiple directories :(
				for i in `seq 1 $N_COMPARISONS` ;
				do
				    ## build the new location information
				    RESULTDIR="$ANALYSIS_PREFIX/${ancestry}/${REQUESTED_SOFTWARE^^}/comparison$i"
				    RESULT="$RESULTDIR/$ANALYSIS_PREFIX.$chip.$REQUESTED_SOFTWARE"
				    PHENOTYPE_USED_TRACKER_CMP="$RESULTS_PREFIX/$RESULT$PHENOTYPE_USED_TRACKER_SUFFIX"
				    FREQUENCY_MODE_TRACKER_CMP="$RESULTS_PREFIX/$RESULT$FREQUENCY_MODE_TRACKER_SUFFIX"
				    ID_MODE_TRACKER_CMP="$RESULTS_PREFIX/$RESULT$ID_MODE_TRACKER_SUFFIX"
				    PHENOTYPE_SELECTED_TRACKER_CMP="$RESULTS_PREFIX/$RESULT$PHENOTYPE_SELECTED_TRACKER_SUFFIX"
				    COVARIATES_SELECTED_TRACKER_CMP="$RESULTS_PREFIX/$RESULT$COVARIATES_SELECTED_TRACKER_SUFFIX"
				    TRANSFORMATION_TRACKER_CMP="$RESULTS_PREFIX/$RESULT$TRANSFORMATION_TRACKER_SUFFIX"
				    SEX_SPECIFIC_TRACKER_CMP="$RESULTS_PREFIX/$RESULT$SEX_SPECIFIC_TRACKER_SUFFIX"
				    CONTROL_INCLUSION_TRACKER_CMP="$RESULTS_PREFIX/$RESULT$CONTROL_INCLUSION_TRACKER_SUFFIX"
				    CONTROL_EXCLUSION_TRACKER_CMP="$RESULTS_PREFIX/$RESULT$CONTROL_EXCLUSION_TRACKER_SUFFIX"
				    FINALIZED_ANALYSIS_TRACKER_CMP="$RESULTS_PREFIX/$RESULT$FINALIZED_ANALYSIS_TRACKER_SUFFIX"
				    CATEGORY_TRACKER_CMP="$RESULTS_PREFIX/$RESULT$CATEGORY_TRACKER_SUFFIX"
				    ## make the directory if needed
				    mkdir -p "$RESULTS_PREFIX/$RESULTDIR"
				    ## copy trackers over
				    if [[ "$UPDATE_BUNDLE" -gt "0" ]] ; then
					cp "$PHENOTYPE_USED_TRACKER" "$PHENOTYPE_USED_TRACKER_CMP"
					cp "$PHENOTYPE_USED_TRACKER.history" "$PHENOTYPE_USED_TRACKER_CMP.history"
					if [[ "$FREQUENCY_UPDATED" -gt "0" ]] ; then
					    cp "$FREQUENCY_MODE_TRACKER" "$FREQUENCY_MODE_TRACKER_CMP"
					fi
					if [[ "$ID_UPDATED" -gt "0" ]] ; then
					    cp "$ID_MODE_TRACKER" "$ID_MODE_TRACKER_CMP"
					fi
					cp "$PHENOTYPE_SELECTED_TRACKER" "$PHENOTYPE_SELECTED_TRACKER_CMP"
					cp "$COVARIATES_SELECTED_TRACKER" "$COVARIATES_SELECTED_TRACKER_CMP"
					cp "$TRANSFORMATION_TRACKER" "$TRANSFORMATION_TRACKER_CMP"
					cp "$SEX_SPECIFIC_TRACKER" "$SEX_SPECIFIC_TRACKER_CMP"
					cp "$CONTROL_INCLUSION_TRACKER" "$CONTROL_INCLUSION_TRACKER_CMP"
					cp "$CONTROL_EXCLUSION_TRACKER" "$CONTROL_EXCLUSION_TRACKER_CMP"
					NEW_CATEGORIES=`echo "$FACTORIZATION" | awk -v target=$i 'NR == target' | sed 's/\t/\n/g ; s/+/\n/g'`
					if [[ ! -f "$CATEGORY_TRACKER_CMP" ]] ; then
					    echo "$NEW_CATEGORIES" > "$CATEGORY_TRACKER_CMP"
					else
					    OLD_CATEGORIES=`cat $CATEGORY_TRACKER`
					    if [[ "$NEW_CATEGORIES" != "$OLD_CATEGORIES" ]] ; then
						echo "$NEW_CATEGORIES" > "$CATEGORY_TRACKER_CMP"
					    fi
					fi
				    fi
				    ## emit the directory as an analysis target
				    echo "$RESULT$REPORT_SUFFIX"
				done
				SUPPRESS_CENTRAL_DIRECTORY="1"
			    else
				## there is only one comparison. this is very good. still needs to be emitted
				CATEGORY_TRACKER="$RESULTS_PREFIX/$RESULT$CATEGORY_TRACKER_SUFFIX"
				NEW_CATEGORIES=`echo "$FACTORIZATION" | sed 's/\t/\n/g ; s/+/\n/g'`
				if [[ ! -f "$CATEGORY_TRACKER" ]] ; then
				    echo "$NEW_CATEGORIES" > "$CATEGORY_TRACKER"
				else
				    OLD_CATEGORIES=`cat $CATEGORY_TRACKER`
				    if [[ "$NEW_CATEGORIES" != "$OLD_CATEGORIES" ]] ; then
					echo "$NEW_CATEGORIES" > "$CATEGORY_TRACKER"
				    fi
				fi
			    fi
			fi
			if [[ "$SUPPRESS_CENTRAL_DIRECTORY" -eq "0" ]] ; then
			    echo "$RESULT$REPORT_SUFFIX"
			fi
		    fi
		fi
	    fi
	done
    done
fi
