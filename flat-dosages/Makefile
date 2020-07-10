## Cameron Palmer, 08 July 2020
## convert bgen files into flat dosage files for compatibility with POLMM
##   additionally fragment chromosomes to handle low processivity and high RAM requirements

include $(PROJECT_BASE_DIR)/Makefile.config

define determine_max_fragment =
$(shell echo "$$(( 165 - $(1) * 5 ))" )
endef

IMPUTED_DIR := $(BGEN_OUTPUT_DIR)
OUTPUT_DIR := $(POLMM_FLAT_DOSAGE_OUTPUT_DIR)
ALL_TARGETS := $(shell find $(IMPUTED_DIR) -name "chr*-filtered.bgen" -print)
ALL_TARGETS := $(foreach target,$(ALL_TARGETS),$(patsubst %,$(OUTPUT_DIR)/$(dir $(subst $(IMPUTED_DIR)/,,$(target)))$(subst -filtered.bgen,,$(notdir $(target)))-fragment%.raw.gz,$(shell seq 1 $(call determine_max_fragment,$(subst -filtered.bgen,,$(subst chr,,$(notdir $(target))))))))
ALL_TARGETS := $(ALL_TARGETS) $(subst .raw.gz,.traw.alleles.gz,$(ALL_TARGETS))

.PHONY: all
.DELETE_ON_ERROR:
.SECONDARY:
.SECONDEXPANSION:
all: $(ALL_TARGETS)

%.raw.gz: %.raw.success | $$(dir $$@)
	gzip -c $(subst .success,,$<) > $@

%.traw.alleles.gz: %.traw.success | $$(dir $$@)
	cut -f 7 --complement $(subst .success,,$<) | gzip -c > $@

%.raw.success: $$(subst $$(OUTPUT_DIR),$$(IMPUTED_DIR),$$(word 1,$$(subst -fragment,-filtered.bgen ,$$@))) $$(subst $$(OUTPUT_DIR),$$(IMPUTED_DIR),$$(word 1,$$(subst -fragment,-filtered-noNAs.sample ,$$@))) | $$(dir $$@)
	$(call qsub_handler,$(subst .success,,$@),$(PLINK2) --bgen $< ref-last --sample $(word 2,$^) --recode A --out $(subst .raw.success,,$@))

%.traw.success: $$(subst $$(OUTPUT_DIR),$$(IMPUTED_DIR),$$(word 1,$$(subst -fragment,-filtered.bgen ,$$@))) $$(subst $$(OUTPUT_DIR),$$(IMPUTED_DIR),$$(word 1,$$(subst -fragment,-filtered-noNAs.sample ,$$@))) | $$(dir $$@)
	$(call qsub_handler,$(subst .success,,$@),$(PLINK2) --bgen $< ref-last --sample $(word 2,$^) --thin-indiv-count 1 --recode A-transpose --out $(subst .traw.success,,$@))

$(sort $(dir $(ALL_TARGETS))):
	mkdir -p $@
