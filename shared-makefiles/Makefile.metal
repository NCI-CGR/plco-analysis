## Cameron Palmer, 08 June 2020
## run meta-analysis on completed association results

include $(PROJECT_BASE_DIR)/Makefile.config

ALL_FIND_TARGETS := $(shell find $(RESULT_OUTPUT_DIR) \( -name "*$(shell echo "$(SUPPORTED_TARGETS)" | tr '[\:upper\:]' '[\:lower\:]' | sed 's/ /.rawids.tsv" -o -name "*/g').rawids.tsv" \) -print)
ALL_TARGETS := $(sort $(dir $(ALL_FIND_TARGETS)))
ALL_TARGETS := $(foreach target,$(ALL_TARGETS),$(target)$(word 1,$(subst /, ,$(subst $(RESULT_OUTPUT_DIR),,$(target)))).$(word 2,$(subst /, ,$(subst $(RESULT_OUTPUT_DIR),,$(target)))).$(word 3,$(subst /, ,$(subst $(RESULT_OUTPUT_DIR),,$(target)))).tsv)


## handle categorical analysis targets separately, as they're split into separate binary outcomes versus a reference and must be preprocessed
#CATEGORICAL_TARGETS := $(sort $(dir $(shell echo $(ALL_FIND_TARGETS) | grep -E "*/comparison[0-9]+/*")))
#CATEGORICAL_TARGETS := $(sort $(foreach target,$(CATEGORICAL_TARGETS),$(word 1,$(subst /comparison,/ ,$(target)))))
#CATEGORICAL_TARGETS := $(foreach target,$(CATEGORICAL_TARGETS),$(target)$(word 1,$(subst /, ,$(subst $(RESULT_OUTPUT_DIR),,$(target)))).$(word 2,$(subst /, ,$(subst $(RESULT_OUTPUT_DIR),,$(target)))).$(word 3,$(subst /, ,$(subst $(RESULT_OUTPUT_DIR),,$(target)))).tsv)

#$(info $(CATEGORICAL_TARGETS))

METAL := $(METAL_EXECUTABLE)

$(if $(EXCLUDE_SAIGE),$(eval ALL_TARGETS:=$(filter-out %.SAIGE.tsv %.saige.tsv,$(ALL_TARGETS))),)
$(if $(EXCLUDE_BOLTLMM),$(eval ALL_TARGETS:=$(filter-out %.BOLTLMM.tsv %.boltlmm.tsv,$(ALL_TARGETS))),)
$(if $(EXCLUDE_FASTGWA),$(eval ALL_TARGETS:=$(filter-out %.FASTGWA.tsv %.fastgwa.tsv,$(ALL_TARGETS))),)

.DELETE_ON_ERROR:
.SECONDARY:
.SECONDEXPANSION:
.PHONY: all

all: $(addsuffix .gz$(TRACKING_SUCCESS_SUFFIX),$(ALL_TARGETS)) $(if $(EXCLUDE_SAIGE),,$(addsuffix .gz$(TRACKING_SUCCESS_SUFFIX),$(CATEGORICAL_TARGETS)))

## patterns:
##    output: results/{PHENOTYPE}/{ANCESTRY}/{METHOD}/{PHENOTYPE}.{METHOD}.tsv.gz$(TRACKING_SUCCESS_SUFFIX)
##    input:  results/{PHENOTYPE}/{ANCESTRY}/{METHOD}/{PHENOTYPE}.{METHOD}.final-ids.tsv$(TRACKING_SUCCESS_SUFFIX)
## Notes: compress results
%.tsv.gz$(TRACKING_SUCCESS_SUFFIX): %.final-ids.tsv$(TRACKING_SUCCESS_SUFFIX)
	$(call log_handler,$(subst $(TRACKING_SUCCESS_SUFFIX),,$@),gzip -c $(subst $(TRACKING_SUCCESS_SUFFIX),,$<) > $(subst $(TRACKING_SUCCESS_SUFFIX),,$@))

## get a saved config parameter setting from a tracking file
define get_tracked_parameter =
$(shell cat $(1))
endef

## patterns:
##    output: results/{PHENOTYPE}/{ANCESTRY}/{METHOD}/{PHENOTYPE}.{METHOD}.final-ids.tsv$(TRACKING_SUCCESS_SUFFIX)
##    input:  results/{PHENOTYPE}/{ANCESTRY}/{METHOD}/{PHENOTYPE}.{METHOD}.sorted.tsv$(TRACKING_SUCCESS_SUFFIX)
## Notes: change chr:pos:ref:alt labels to rsids if requested in relevant config file tracker
%.final-ids.tsv$(TRACKING_SUCCESS_SUFFIX): $(ANNOTATE_RSID) $(RSID_LINKER_FILE) %.sorted.tsv$(TRACKING_SUCCESS_SUFFIX) $$(shell find $$(dir $$@) -name "*$(ID_MODE_TRACKER_SUFFIX)" -print | head -1)
	$(eval ID_MODE := $(call get_tracker_parameter,$(word 4,$^)))
	$(if $(filter $(CHRPOS_MODE),$(ID_MODE)),ln -fs $(subst $(TRACKING_SUCCESS_SUFFIX),,$(word 3,$^)) $(subst $(TRACKING_SUCCESS_SUFFIX),,$@) && touch $@,$(call qsub_handler,$(subst $(TRACKING_SUCCESS_SUFFIX),,$@),$< $(subst $(TRACKING_SUCCESS_SUFFIX),,$(word 3,$^)) $(word 2,$^) $(subst $(TRACKING_SUCCESS_SUFFIX),,$@)))

## patterns:
##    output: results/{PHENOTYPE}/{ANCESTRY}/{METHOD}/{PHENOTYPE}.{METHOD}.sorted.tsv$(TRACKING_SUCCESS_SUFFIX)
##    input:  results/{PHENOTYPE}/{ANCESTRY}/{METHOD}/{PHENOTYPE}.{METHOD}.tsv$(TRACKING_SUCCESS_SUFFIX)
## Notes: METAL hashes variants in an unfortunate fashion, so resort everything
COMMA:=,
%.sorted.tsv$(TRACKING_SUCCESS_SUFFIX): %.tsv$(TRACKING_SUCCESS_SUFFIX)
	$(call qsub_handler,$(subst $(TRACKING_SUCCESS_SUFFIX),,$@),sort -k 1$(COMMA)1g -k 2$(COMMA)2g $(subst $(TRACKING_SUCCESS_SUFFIX),,$<) -o $(subst $(TRACKING_SUCCESS_SUFFIX),,$@))

## patterns:
##    output: results/{PHENOTYPE}/{ANCESTRY}/{METHOD}/{PHENOTYPE}.{METHOD}.tsv$(TRACKING_SUCCESS_SUFFIX)
##    input:  results/{PHENOTYPE}/{ANCESTRY}/{METHOD}/{PHENOTYPE}.{METHOD}1.raw.tsv$(TRACKING_SUCCESS_SUFFIX)
## Notes: reformat output to match standard atlas output format, with added heterogeneity p-value.
## For SAIGE only: add Ncases/Ncontrols bonus tracked annotations from metal
$(addsuffix $(TRACKING_SUCCESS_SUFFIX),$(ALL_TARGETS)): $$(subst .tsv,1.raw.tsv,$$@)
	$(eval IS_SAIGE := $(shell echo $@ | grep SAIGE))
	$(call log_handler,$(subst $(TRACKING_SUCCESS_SUFFIX),,$@),awk 'NR > 1 {print $$1"\t"$$2"\t"$$3"\t"$$4"\t"$$8"\t"$$9"\t"$$10"\t"$$16"\t"$$15$(if $(IS_SAIGE),"\t"$$17"\t"$$18,)}' $(subst $(TRACKING_SUCCESS_SUFFIX),,$<) | sed 's/^chr// ; s/:/\t/g' | awk 'NR == 1 {print "CHR\tPOS\tSNP\tTested_Allele\tOther_Allele\tFreq_Tested_Allele_in_TOPMed\tBETA\tSE\tP\tN\tPHet$(if $(IS_SAIGE),\tNcases\tNcontrols,)"} ; {print $$1"\t"$$2"\tchr"$$1":"$$2":"$$3":"$$4"\t"toupper($$5)"\t"toupper($$6)"\t"$$7"\t"$$8"\t"$$9"\t"$$10"\t"$$11"\t"$$12$(if $(IS_SAIGE),"\t"$$13"\t"$$14,)}' > $(subst $(TRACKING_SUCCESS_SUFFIX),,$@))

## patterns:
##    output: results/{PHENOTYPE}/{ANCESTRY}/{METHOD}/{PHENOTYPE}.{METHOD}1.raw.tsv$(TRACKING_SUCCESS_SUFFIX)
##    input:  results/{PHENOTYPE}/{ANCESTRY}/{METHOD}/{PHENOTYPE}.{METHOD}1.par$(TRACKING_SUCCESS_SUFFIX)
## Notes: this simply wraps the call to metal itself. configuration happens with the par file rule
%.raw.tsv$(TRACKING_SUCCESS_SUFFIX): %.par$(TRACKING_SUCCESS_SUFFIX)
	$(call qsub_handler_specify_queue_time,$(subst $(TRACKING_SUCCESS_SUFFIX),,$@),$(METAL) < $(subst $(TRACKING_SUCCESS_SUFFIX),,$<),bigmem.q,4:30:00)

## patterns:
##    output: results/{PHENOTYPE}/{ANCESTRY}/{METHOD}/{PHENOTYPE}.{METHOD}1.par$(TRACKING_SUCCESS_SUFFIX)
##    input:  results/{PHENOTYPE}/{ANCESTRY}/{METHOD}/{PHENOTYPE}.{CHIP}.{METHOD}.rawids.tsv
## Notes: barebones configuration for metal. assumes effect estimates in log(OR) space for the moment.
$(subst .tsv,1.par$(TRACKING_SUCCESS_SUFFIX),$(shell echo $(ALL_TARGETS) | grep -iv saige)): $$(shell find $$(dir $$@) -name "*[am].rawids.tsv" -print)
	$(call log_handler,$(subst $(TRACKING_SUCCESS_SUFFIX),,$@),echo -e "MARKERLABEL SNP\nALLELELABELS Tested_Allele Other_Allele\nEFFECTLABEL BETA\nSTDERRLABEL SE\nFREQLABEL Freq_Tested_Allele_in_TOPMed\nCUSTOMVARIABLE TotalSampleSize\nLABEL TotalSampleSize as N\nSCHEME STDERR\nGENOMICCONTROL ON\nAVERAGEFREQ ON\nMINMAXFREQ ON\n$(patsubst %,PROCESSFILE %\n,$^)OUTFILE $(subst 1.par$(TRACKING_SUCCESS_SUFFIX),,$@) .raw.tsv\nANALYZE HETEROGENEITY\nQUIT" > $(subst $(TRACKING_SUCCESS_SUFFIX),,$@))

$(subst .tsv,1.par$(TRACKING_SUCCESS_SUFFIX),$(shell echo $(ALL_TARGETS) | grep -i saige)): $$(shell find $$(dir $$@) -name "*[e].rawids.tsv" -print)
	$(call log_handler,$(subst $(TRACKING_SUCCESS_SUFFIX),,$@),echo -e "MARKERLABEL SNP\nALLELELABELS Tested_Allele Other_Allele\nEFFECTLABEL BETA\nSTDERRLABEL SE\nFREQLABEL Freq_Tested_Allele_in_TOPMed\nCUSTOMVARIABLE TotalSampleSize\nLABEL TotalSampleSize as N\nCUSTOMVARIABLE CaseCount\nLABEL CaseCount as Ncases\nCUSTOMVARIABLE ControlCount\nLABEL ControlCount as Ncontrols\nSCHEME STDERR\nGENOMICCONTROL ON\nAVERAGEFREQ ON\nMINMAXFREQ ON\n$(patsubst %,PROCESSFILE %\n,$^)OUTFILE $(subst 1.par$(TRACKING_SUCCESS_SUFFIX),,$@) .raw.tsv\nANALYZE HETEROGENEITY\nQUIT" > $(subst $(TRACKING_SUCCESS_SUFFIX),,$@))







#$(subst .tsv,1.par,$(CATEGORICAL_TARGETS)): $$(foreach target,$$(shell find $$(dir $$@) -name "*saige.rawids.tsv" -print),$$(if $$(shell echo $$(target) | grep -E "*/comparison[1-9]+/*"),$$(firstword $$(subst /comparison,/ ,$$(target)))$$(notdir $$(target)),$$(target)))
#	echo -e "MARKERLABEL SNP\nALLELELABELS Tested_Allele Other_Allele\nEFFECTLABEL BETA\nSTDERRLABEL SE\nWEIGHTLABEL N\nFREQLABEL Freq_Tested_Allele_in_TOPMed\nCUSTOMVARIABLE TotalSampleSize\nLABEL TotalSampleSize as N\nSCHEME SAMPLESIZE\nGENOMICCONTROL ON\nAVERAGEFREQ ON\nMINMAXFREQ ON\n$(patsubst %,PROCESSFILE %\n,$^)OUTFILE $(subst 1.par,,$@) .raw.tsv\nANALYZE HETEROGENEITY\nQUIT" > $@

#$(sort $(foreach target,$(sort $(dir $(CATEGORICAL_TARGETS))),$(shell find $(target) -name "*saige.rawids.tsv" -print | awk '/SAIGE\/comparison/' | sed -E 's/^(.*)\/comparison[0-9]+\/(.*)$$/\1\/\2/'))): $$(shell find $$(dir $$@)comparison* -name "$$(notdir $$@)" -print) $$(shell find $$(dir $$@)comparison* -name "$$(subst .rawids.tsv,.model_matrix,$$(notdir $$@))" -print)
#	$(eval EFFECTIVE_N := $(shell cat $(filter %.model_matrix,$^) | awk '! /FID/ {print $$2}' | sort | uniq | wc -l))
#	if [[ "$(words $(filter-out %.model_matrix,$^))" == "1" ]] ; then ; \
#	ln -fs $< $@ ; \
#	else \
#	$(SHARED_SOURCE)/combine_categorical_runs.out $^ $@ $(EFFECTIVE_N) ; \
#	fi

