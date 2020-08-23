## Cameron Palmer, 08 June 2020
## run meta-analysis on completed association results

include $(PROJECT_BASE_DIR)/Makefile.config

ALL_FIND_TARGETS := $(shell find $(RESULT_OUTPUT_DIR) -name "*[mae].rawids.tsv" -print)
#ALL_TARGETS := $(sort $(dir $(shell echo $(ALL_FIND_TARGETS) | grep -vE "*/comparison[0-9]+/*")))
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

all: $(addsuffix .gz.success,$(ALL_TARGETS)) $(if $(EXCLUDE_SAIGE),,$(addsuffix .gz.success,$(CATEGORICAL_TARGETS)))

## patterns:
##    output: results/{PHENOTYPE}/{ANCESTRY}/{METHOD}/{PHENOTYPE}.{METHOD}.tsv.gz.success
##    input:  results/{PHENOTYPE}/{ANCESTRY}/{METHOD}/{PHENOTYPE}.{METHOD}.final-ids.tsv.success
## Notes: compress results
%.tsv.gz.success: %.final-ids.tsv.success
	gzip -c $(subst .success,,$<) > $(subst .success,,$@) && touch $@

## get a saved config parameter setting from a tracking file
define get_tracked_parameter =
$(shell cat $(1))
endef

## patterns:
##    output: results/{PHENOTYPE}/{ANCESTRY}/{METHOD}/{PHENOTYPE}.{METHOD}.final-ids.tsv.success
##    input:  results/{PHENOTYPE}/{ANCESTRY}/{METHOD}/{PHENOTYPE}.{METHOD}.sorted.tsv.success
## Notes: change chr:pos:ref:alt labels to rsids if requested in relevant config file tracker
%.final-ids.tsv.success: $(ANNOTATE_RSID) $(RSID_LINKER_FILE) %.sorted.tsv.success $$(shell find $$(dir $$@) -name "*$(ID_MODE_TRACKER_SUFFIX)" -print | head -1)
	$(eval ID_MODE := $(call get_tracker_parameter,$(word 4,$^)))
	$(if $(filter $(CHRPOS_MODE),$(ID_MODE)),ln -fs $(subst .success,,$(word 3,$^)) $(subst .success,,$@) && touch $@,$(call qsub_handler,$(subst .success,,$@),$< $(subst .success,,$(word 3,$^)) $(word 2,$^) $(subst .success,,$@)))

## patterns:
##    output: results/{PHENOTYPE}/{ANCESTRY}/{METHOD}/{PHENOTYPE}.{METHOD}.sorted.tsv.success
##    input:  results/{PHENOTYPE}/{ANCESTRY}/{METHOD}/{PHENOTYPE}.{METHOD}.tsv
## Notes: METAL hashes variants in an unfortunate fashion, so resort everything
COMMA:=,
%.sorted.tsv.success: %.tsv
	$(call qsub_handler,$(subst .success,,$@),sort -k 1$(COMMA)1g -k 2$(COMMA)2g $< -o $(subst .success,,$@))

## patterns:
##    output: results/{PHENOTYPE}/{ANCESTRY}/{METHOD}/{PHENOTYPE}.{METHOD}.tsv
##    input:  results/{PHENOTYPE}/{ANCESTRY}/{METHOD}/{PHENOTYPE}.{METHOD}1.raw.tsv.success
## Notes: reformat output to match standard atlas output format, with added heterogeneity p-value
$(ALL_TARGETS): $$(subst .tsv,1.raw.tsv.success,$$@)
	awk 'NR > 1 {print $$1"\t"$$2"\t"$$3"\t"$$4"\t"$$8"\t"$$9"\t"$$10"\t"$$16"\t"$$15}' $(subst .success,,$<) | sed 's/^chr// ; s/:/\t/g' | awk 'NR == 1 {print "CHR\tPOS\tSNP\tTested_Allele\tOther_Allele\tFreq_Tested_Allele_in_TOPMed\tBETA\tSE\tP\tN\tPHet"} ; {print $$1"\t"$$2"\tchr"$$1":"$$2":"$$3":"$$4"\t"toupper($$5)"\t"toupper($$6)"\t"$$7"\t"$$8"\t"$$9"\t"$$10"\t"$$11"\t"$$12}' > $@

## patterns:
##    output: results/{PHENOTYPE}/{ANCESTRY}/{METHOD}/{PHENOTYPE}.{METHOD}1.raw.tsv.success
##    input:  results/{PHENOTYPE}/{ANCESTRY}/{METHOD}/{PHENOTYPE}.{METHOD}1.par
## Notes: this simply wraps the call to metal itself. configuration happens with the par file rule
%.raw.tsv.success: %.par
	$(call qsub_handler_specify_queue_time,$(subst .success,,$@),$(METAL) < $<,bigmem.q,4:30:00)

## patterns:
##    output: results/{PHENOTYPE}/{ANCESTRY}/{METHOD}/{PHENOTYPE}.{METHOD}1.par
##    input:  results/{PHENOTYPE}/{ANCESTRY}/{METHOD}/{PHENOTYPE}.{CHIP}.{METHOD}.rawids.tsv
## Notes: barebones configuration for metal. assumes effect estimates in log(OR) space for the moment.
$(subst .tsv,1.par,$(shell echo $(ALL_TARGETS) | grep -iv saige)): $$(shell find $$(dir $$@) -name "*[am].rawids.tsv" -print)
	echo -e "MARKERLABEL SNP\nALLELELABELS Tested_Allele Other_Allele\nEFFECTLABEL BETA\nSTDERRLABEL SE\nFREQLABEL Freq_Tested_Allele_in_TOPMed\nCUSTOMVARIABLE TotalSampleSize\nLABEL TotalSampleSize as N\nSCHEME STDERR\nGENOMICCONTROL ON\nAVERAGEFREQ ON\nMINMAXFREQ ON\n$(patsubst %,PROCESSFILE %\n,$^)OUTFILE $(subst 1.par,,$@) .raw.tsv\nANALYZE HETEROGENEITY\nQUIT" > $@

$(subst .tsv,1.par,$(shell echo $(ALL_TARGETS) | grep -i saige)): $$(shell find $$(dir $$@) -name "*[e].rawids.tsv" -print)
	echo -e "MARKERLABEL SNP\nALLELELABELS Tested_Allele Other_Allele\nEFFECTLABEL BETA\nSTDERRLABEL SE\nFREQLABEL Freq_Tested_Allele_in_TOPMed\nCUSTOMVARIABLE TotalSampleSize\nLABEL TotalSampleSize as N\nCUSTOMVARIABLE CaseCount\nLABEL CaseCount as Ncases\nCUSTOMVARIABLE ControlCount\nLABEL ControlCount as Ncontrols\nSCHEME STDERR\nGENOMICCONTROL ON\nAVERAGEFREQ ON\nMINMAXFREQ ON\n$(patsubst %,PROCESSFILE %\n,$^)OUTFILE $(subst 1.par,,$@) .raw.tsv\nANALYZE HETEROGENEITY\nQUIT" > $@







#$(subst .tsv,1.par,$(CATEGORICAL_TARGETS)): $$(foreach target,$$(shell find $$(dir $$@) -name "*saige.rawids.tsv" -print),$$(if $$(shell echo $$(target) | grep -E "*/comparison[1-9]+/*"),$$(firstword $$(subst /comparison,/ ,$$(target)))$$(notdir $$(target)),$$(target)))
#	echo -e "MARKERLABEL SNP\nALLELELABELS Tested_Allele Other_Allele\nEFFECTLABEL BETA\nSTDERRLABEL SE\nWEIGHTLABEL N\nFREQLABEL Freq_Tested_Allele_in_TOPMed\nCUSTOMVARIABLE TotalSampleSize\nLABEL TotalSampleSize as N\nSCHEME SAMPLESIZE\nGENOMICCONTROL ON\nAVERAGEFREQ ON\nMINMAXFREQ ON\n$(patsubst %,PROCESSFILE %\n,$^)OUTFILE $(subst 1.par,,$@) .raw.tsv\nANALYZE HETEROGENEITY\nQUIT" > $@

#$(sort $(foreach target,$(sort $(dir $(CATEGORICAL_TARGETS))),$(shell find $(target) -name "*saige.rawids.tsv" -print | awk '/SAIGE\/comparison/' | sed -E 's/^(.*)\/comparison[0-9]+\/(.*)$$/\1\/\2/'))): $$(shell find $$(dir $$@)comparison* -name "$$(notdir $$@)" -print) $$(shell find $$(dir $$@)comparison* -name "$$(subst .rawids.tsv,.model_matrix,$$(notdir $$@))" -print)
#	$(eval EFFECTIVE_N := $(shell cat $(filter %.model_matrix,$^) | awk '! /FID/ {print $$2}' | sort | uniq | wc -l))
#	if [[ "$(words $(filter-out %.model_matrix,$^))" == "1" ]] ; then ; \
#	ln -fs $< $@ ; \
#	else \
#	$(SHARED_SOURCE)/combine_categorical_runs.out $^ $@ $(EFFECTIVE_N) ; \
#	fi

