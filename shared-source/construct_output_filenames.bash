#!/bin/bash
if [ "$#" -ne 16 ]; then
    echo "the command 'construct_output_filenames.bash' requires sixteen command line arguments: the name of the config file, the software (saige, bolt, fastgwa) requested, the minimum sample count for the software, the directory prefix for all bgen files, the pipeline results toplevel directory, the phenotype file currently in use, the column extractor program, the phenotype file used tracker file, the frequency mode tracker file, the phenotype model tracker file, the covariate model tracker file, the phenotype transformation tracker file, the sex-specific analysis selection tracker file, the finalized analysis tracker file, binary indicator of whether make -B is in effect, and a binary indicator of whether make -n is in effect"
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
    PHENOTYPE_SELECTED_TRACKER_SUFFIX="${10}"
    COVARIATES_SELECTED_TRACKER_SUFFIX="${11}"
    TRANSFORMATION_TRACKER_SUFFIX="${12}"
    SEX_SPECIFIC_TRACKER_SUFFIX="${13}"
    FINALIZED_ANALYSIS_TRACKER_SUFFIX="${14}"
    FORCE_RUN="${15}"
    PRETEND_RUN="${16}"

    ## python yaml helper function
    yaml() {
	VALUE=`python3 -c "import yaml; print(yaml.safe_load(open('$1'))['$2'])"`
	echo "$VALUE" | sed "s/\[//g ; s/\]//g ; s/'//g ; s/,//g"
    }
    yaml_check_exists() {
	VALUE=`python3 -c "import yaml; print(\"$2\" in yaml.safe_load(open('$1')))"`
	if [[ "$VALUE" == "True" ]] ; then
	    echo "1"
	fi
    }
    ANALYSIS_PREFIX=$(yaml "$CONFIG_FILE" "analysis_prefix")
    REQUESTED_CHIPS=$(yaml "$CONFIG_FILE" "chips")
    REQUESTED_ANCESTRIES=$(yaml "$CONFIG_FILE" "ancestries")
    REQUESTED_ALGORITHM=$(yaml "$CONFIG_FILE" "algorithm")
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
		    PHENOTYPE_SELECTED_TRACKER="$RESULTS_PREFIX/$RESULT$PHENOTYPE_SELECTED_TRACKER_SUFFIX"
		    COVARIATES_SELECTED_TRACKER="$RESULTS_PREFIX/$RESULT$COVARIATES_SELECTED_TRACKER_SUFFIX"
		    TRANSFORMATION_TRACKER="$RESULTS_PREFIX/$RESULT$TRANSFORMATION_TRACKER_SUFFIX"
		    SEX_SPECIFIC_TRACKER="$RESULTS_PREFIX/$RESULT$SEX_SPECIFIC_TRACKER_SUFFIX"
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
		    PHENOTYPE=$(yaml "$CONFIG_FILE" "phenotype")
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
		    if [[ ! -z $(yaml_check_exists "$CONFIG_FILE" "covariates") ]] ; then
			COVARIATES=$(yaml "$CONFIG_FILE" "covariates")
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
		    if [[ "$PRETEND_RUN" -eq "0" ]] ; then
			FREQUENCY_MODE="reference"
			if [[ ! -z $(yaml_check_exists "$CONFIG_FILE" "frequency_mode") ]] ; then
			    FREQUENCY_MODE=$(yaml "$CONFIG_FILE" "frequency_mode")
			fi
			if [[ -f "$FREQUENCY_MODE_TRACKER" ]] ; then
			    EXISTING_FREQUENCY_MODE=`cat $FREQUENCY_MODE_TRACKER`
			    if [[ "$EXISTING_FREQUENCY_MODE" != "$FREQUENCY_MODE" ]] ; then
				echo "$FREQUENCY_MODE" > "$FREQUENCY_MODE_TRACKER"
			    fi
			else
			    echo "$FREQUENCY_MODE" > "$FREQUENCY_MODE_TRACKER"
			    rm -f "$FINALIZED_ANALYSIS_TRACKER"
			fi
			## allow manual override
			if [[ "$FORCE_RUN" -gt "0" ]] ; then
			    echo "$FREQUENCY_MODE" > "$FREQUENCY_MODE_TRACKER"
			fi
		    fi
		    ## run phenotype transformation mode tracking/version difference testing
		    TRANSFORMATION="none"
		    if [[ ! -z $(yaml_check_exists "$CONFIG_FILE" "transformation") ]] ; then
			TRANSFORMATION=$(yaml "$CONFIG_FILE" "transformation")
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
		    if [[ ! -z $(yaml_check_exists "$CONFIG_FILE" "sex-specific") ]] ; then
			SEX_SPECIFIC=$(yaml "$CONFIG_FILE" "sex-specific")
		    fi
		    if [[ -f "$SEX_SPECIFIC_TRACKER" ]] ; then
			EXISTING_SEX_SPECIFIC=`cat $SEX_SPECIFIC_TRACKER`
			if [[ "$EXISTING_SEX_SPECIFIC" != "$SEX_SPECIFIC" ]] ; then
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
			rm -f "$FINALIZED_ANALYSIS_TRACKER"
		    fi

		    ## for storage efficiency reasons an analysis can be in a "finalized" state, which
		    ## is triggered externally. This program can however remove the finalized condition if
		    ## configuration options have changed. A finalized analysis has a very aggressive set of
		    ## removed files that likely breaks dependency tracking; so if the analysis is finalized
		    ## and none of the configuration tracking files have changed, then do not report this
		    ## analysis as a tracking candidate to the workflow unless make -B has been invoked.
		    if [[ ! -f "$FINALIZED_ANALYSIS_TRACKER" ]] ; then
			echo "$RESULT$REPORT_SUFFIX"
		    fi
		fi
	    else
		echo "algorithm pattern match failure"
	    fi
	done
    done
fi
