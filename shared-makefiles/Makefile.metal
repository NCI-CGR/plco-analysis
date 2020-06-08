## Cameron Palmer, 08 June 2020
## run meta-analysis on completed association results

include $(PROJECT_BASE_DIR)/Makefile.config

ALL_TARGETS := $(sort $(dir $(shell find $(RESULT_OUTPUT_DIR) -name "*.tsv.gz" -print)))
ALL_TARGETS := $(foreach target,$(ALL_TARGETS),$(target)$(word 2,$(subst /, ,$(target))).$(word 3,$(subst /, ,$(target))).$(word 4,$(subst /, ,$(target)))1.tsv)
METAL := $(METAL_EXECUTABLE)

.DELETE_ON_ERROR:
.SECONDARY:
.SECONDEXPANSION:
.PHONY: all

all: $(addsuffix .success,$(ALL_TARGETS))

## patterns:
##    output: results/{PHENOTYPE}/{ANCESTRY}/{METHOD}/{PHENOTYPE}.{METHOD}1.tsv
##    input:  results/{PHENOTYPE}/{ANCESTRY}/{METHOD}/{PHENOTYPE}.{METHOD}l.par
## Notes: this simply wraps the call to metal itself. configuration happens with the par file rule
$(addsuffix .success,$(ALL_TARGETS)): $$(subst .meta1.tsv.success,.metal.par,$$@)
	$(call qsub_handler,$(subst .success,,$@),$(METAL) < $<)

## patterns:
##    output: results/{PHENOTYPE}/{ANCESTRY}/{METHOD}/{PHENOTYPE}.{METHOD}.metal.par
##    input:  results/{PHENOTYPE}/{ANCESTRY}/{METHOD}/{PHENOTYPE}.{CHIP}.{METHOD}.tsv
## Notes: barebones configuration for metal. assumes effect estimates in log(OR) space for the moment.
$(subst .meta1.tsv,.metal.par,$(ALL_TARGETS)): $$(shell find $$(dir $$@) -name "*tsv.gz" -print | sed 's/.gz$$$$//')
	echo -e "MARKERLABEL SNP\nALLELELABELS Tested_Allele Other_Allele\nEFFECTLABEL BETA\nSTDERRLABEL SE\nSCHEME STDERR\nGENOMICCONTROL ON\n$(patsubst %,PROCESSFILE %\n,$^)OUTFILE $(subst .metal.par,,$@) .tsv\nANALYZE HETEROGENEITY\nQUIT" > $@
