include /home/palmercd/Development/Makefile_utilities/Makefile.qsub_handling
ALL_TARGETS := $(sort $(dir $(shell find results -name "*.tsv.gz" -print)))
ALL_TARGETS := $(foreach target,$(ALL_TARGETS),$(target)$(word 2,$(subst /, ,$(target))).$(word 3,$(subst /, ,$(target))).$(word 4,$(subst /, ,$(target))).meta1.tsv)
METAL := /home/palmercd/Development/METAL/generic-metal/metal
.DELETE_ON_ERROR:
.SECONDARY:
.SECONDEXPANSION:
.PHONY: all

all: $(addsuffix .success,$(ALL_TARGETS))

$(addsuffix .success,$(ALL_TARGETS)): $$(subst .meta1.tsv.success,.metal.par,$$@)
	$(call qsub_handler,$(subst .success,,$@),$(METAL) < $<)

$(subst .meta1.tsv,.metal.par,$(ALL_TARGETS)): $$(shell find $$(dir $$@) -name "*tsv.gz" -print | sed 's/.gz$$$$//')
	echo -e "MARKERLABEL SNP\nALLELELABELS Tested_Allele Other_Allele\nEFFECTLABEL BETA\nSTDERRLABEL SE\nSCHEME STDERR\nGENOMICCONTROL ON\n$(patsubst %,PROCESSFILE %\n,$^)OUTFILE $(subst .metal.par,,$@) .tsv\nANALYZE HETEROGENEITY\nQUIT" > $@
