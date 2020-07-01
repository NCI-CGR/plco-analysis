## Cameron Palmer, 08 June 2020
## run meta-analysis on completed association results

include $(PROJECT_BASE_DIR)/Makefile.config

ALL_TARGETS := $(sort $(dir $(shell find $(RESULT_OUTPUT_DIR) \( -name "*.boltlmm.tsv.gz" -o -name "*fastgwa.tsv.gz" \) -print)))
ALL_TARGETS := $(foreach target,$(ALL_TARGETS),$(target)$(word 1,$(subst /, ,$(subst $(RESULT_OUTPUT_DIR),,$(target)))).$(word 2,$(subst /, ,$(subst $(RESULT_OUTPUT_DIR),,$(target)))).$(word 3,$(subst /, ,$(subst $(RESULT_OUTPUT_DIR),,$(target)))).tsv)
METAL := $(METAL_EXECUTABLE)

.DELETE_ON_ERROR:
.SECONDARY:
.SECONDEXPANSION:
.PHONY: all

all: $(addsuffix .gz,$(ALL_TARGETS))

## patterns:
##    output: results/{PHENOTYPE}/{ANCESTRY}/{METHOD}/{PHENOTYPE}.{METHOD}.tsv.gz
##    input:  results/{PHENOTYPE}/{ANCESTRY}/{METHOD}/{PHENOTYPE}.{METHOD}.tsv
## Notes: compress results
%.tsv.gz: %.tsv
	gzip -c $< > $@

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
	$(call qsub_handler,$(subst .success,,$@),$(METAL) < $<)

## patterns:
##    output: results/{PHENOTYPE}/{ANCESTRY}/{METHOD}/{PHENOTYPE}.{METHOD}1.par
##    input:  results/{PHENOTYPE}/{ANCESTRY}/{METHOD}/{PHENOTYPE}.{CHIP}.{METHOD}.tsv
## Notes: barebones configuration for metal. assumes effect estimates in log(OR) space for the moment.
%.par: $$(shell find $$(dir $$@) -name "*tsv.gz" -print | sed 's/.gz$$$$//')
	echo -e "MARKERLABEL SNP\nALLELELABELS Tested_Allele Other_Allele\nEFFECTLABEL BETA\nSTDERRLABEL SE\nFREQLABEL Freq_Tested_Allele_in_TOPMed\nCUSTOMVARIABLE TotalSampleSize\nLABEL TotalSampleSize as N\nSCHEME STDERR\nGENOMICCONTROL ON\nAVERAGEFREQ ON\nMINMAXFREQ ON\n$(patsubst %,PROCESSFILE %\n,$^)OUTFILE $(subst 1.par,,$@) .raw.tsv\nANALYZE HETEROGENEITY\nQUIT" > $@
