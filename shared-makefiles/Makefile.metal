## Cameron Palmer, 08 June 2020
## run meta-analysis on completed association results

include $(PROJECT_BASE_DIR)/Makefile.config

ALL_TARGETS := $(sort $(dir $(shell find $(RESULT_OUTPUT_DIR) \( -name "*.boltlmm.tsv.gz" -o -name "*fastgwa.tsv.gz" \) -print)))
ALL_TARGETS := $(foreach target,$(ALL_TARGETS),$(target)$(word 1,$(subst /, ,$(subst $(RESULT_OUTPUT_DIR),,$(target)))).$(word 2,$(subst /, ,$(subst $(RESULT_OUTPUT_DIR),,$(target)))).$(word 3,$(subst /, ,$(subst $(RESULT_OUTPUT_DIR),,$(target))))1.raw.tsv)
METAL := $(METAL_EXECUTABLE)

.DELETE_ON_ERROR:
.SECONDARY:
.SECONDEXPANSION:
.PHONY: all

all: $(addsuffix .success,$(ALL_TARGETS))

%.tsv.gz: %.tsv
	gzip -c $< > $@

%.tsv: %.raw.tsv
	awk 'NR > 1 {print $$1"\t"$$2"\t"$$3"\t"$$4"\t"$$8"\t"$$9"\t"$$10}'

## patterns:
##    output: results/{PHENOTYPE}/{ANCESTRY}/{METHOD}/{PHENOTYPE}.{METHOD}1.raw.tsv
##    input:  results/{PHENOTYPE}/{ANCESTRY}/{METHOD}/{PHENOTYPE}.{METHOD}1.par
## Notes: this simply wraps the call to metal itself. configuration happens with the par file rule
$(addsuffix .success,$(ALL_TARGETS)): $$(subst 1.raw.tsv.success,1.par,$$@)
	$(call qsub_handler,$(subst .success,,$@),$(METAL) < $<)

## patterns:
##    output: results/{PHENOTYPE}/{ANCESTRY}/{METHOD}/{PHENOTYPE}.{METHOD}1.par
##    input:  results/{PHENOTYPE}/{ANCESTRY}/{METHOD}/{PHENOTYPE}.{CHIP}.{METHOD}.tsv
## Notes: barebones configuration for metal. assumes effect estimates in log(OR) space for the moment.
$(subst 1.raw.tsv,1.par,$(ALL_TARGETS)): $$(shell find $$(dir $$@) -name "*tsv.gz" -print | sed 's/.gz$$$$//')
	echo -e "MARKERLABEL SNP\nALLELELABELS Tested_Allele Other_Allele\nEFFECTLABEL BETA\nSTDERRLABEL SE\nFREQLABEL Freq_Tested_Allele_in_TOPMed\nCUSTOMVARIABLE TotalSampleSize\nLABEL TotalSampleSize as N\nSCHEME STDERR\nGENOMICCONTROL ON\nAVERAGEFREQ ON\nMINMAXFREQ ON\n$(patsubst %,PROCESSFILE %\n,$^)OUTFILE $(subst 1.par,,$@) .raw.tsv\nANALYZE HETEROGENEITY\nQUIT" > $@
