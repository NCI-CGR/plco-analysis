## Cameron Palmer, 21 May 2020
## Compute relatedness estimates for each platform with GRAF

include $(PROJECT_BASE_DIR)/Makefile.config
.PHONY: all
.DELETE_ON_ERROR:
.SECONDEXPANSION:
.SECONDARY:

POPS := $(sort $(foreach platform,$(PLATFORMS),$(firstword $(subst _, ,$(platform)))))
CHIPS := $(CHIP_FREEZE_INPUT_DIR)

## all targets are both the between-platform estimates and the within-platform estimates only.
## note that you can extract the within-platform estimates from the between-platform version
## if you prefer and it would make things go faster, but as this is only run once, it doesn't
## make much of a difference, and removes a step that I'd otherwise be manually manipulating.

all: $(addsuffix $(TRACKING_SUCCESS_SUFFIX),$(patsubst %,%.relatedness.txt,$(POPS)))

## patterns:
##    output: {CHIP}_rsids.bed$(TRACKING_SUCCESS_SUFFIX)
##    input:  {CHIP_FREEZE}/PLCO_{CHIP}.bed
##            {CHIP_FREEZE}/PLCO_{CHIP}.bim
##            {CHIP_FREEZE}/PLCO_{CHIP}.fam
##            GRAF.extract$(TRACKING_SUCCESS_SUFFIX)
##            GRAF.update_names$(TRACKING_SUCCESS_SUFFIX)
## Notes: the input genotype files don't tend to have rsID annotations, but GRAF assumes they're present.
## so this uses plink to update whatever IDs are present to rsIDs and only keep the IDs that are present in the GRAF backend files.
## not also that this ~~assumes both GRAF and chips are in hg19~~
%_rsids.bed$(TRACKING_SUCCESS_SUFFIX): $(CHIPS)/PLCO_%.bed $(CHIPS)/PLCO_%.bim $(CHIPS)/PLCO_%.fam GRAF.extract$(TRACKING_SUCCESS_SUFFIX) GRAF.update_names$(TRACKING_SUCCESS_SUFFIX)
	$(call sub_handler,$(subst $(TRACKING_SUCCESS_SUFFIX),,$@),$(PLINK19) --bed $< --bim $(word 2,$^) --fam $(word 3,$^) --extract $(subst $(TRACKING_SUCCESS_SUFFIX),,$(word 4,$^)) --update-name $(subst $(TRACKING_SUCCESS_SUFFIX),,$(word 5,$^)) --make-bed --out $(subst .bed$(TRACKING_SUCCESS_SUFFIX),,$@))

## patterns:
##    output: GRAF.extract$(TRACKING_SUCCESS_SUFFIX)
##    input:  {GRAF_backend_bimfile}
## Notes: generates a plink-format --extract file to keep only the variants in the GRAF 1KG AIMs set
GRAF.extract$(TRACKING_SUCCESS_SUFFIX): $(GRAF_1KG_VARIANT_BIMFILE)
	$(call log_handler,$(subst $(TRACKING_SUCCESS_SUFFIX),,$@),awk '{print $$2}' $< > $(subst $(TRACKING_SUCCESS_SUFFIX),,$@))

## patterns:
##    output: GRAF.update_names$(TRACKING_SUCCESS_SUFFIX)
##    input: {GRAF_backend_bimfile}
## Notes: generates a plink(1.9)-format update-names file to convert chr:pos hg19 annotations to rsIDs
GRAF.update_names$(TRACKING_SUCCESS_SUFFIX): $(GRAF_1KG_VARIANT_BIMFILE)
	$(call log_handler,$(subst $(TRACKING_SUCCESS_SUFFIX),,$@),awk '{print $$1":"$$4"\t"$$2}' $< > $(subst $(TRACKING_SUCCESS_SUFFIX),,$@))

## patterns:
##    output: {CHIP}.relatedness.txt$(TRACKING_SUCCESS_SUFFIX)
##    input:  {CHIP}.fpg$(TRACKING_SUCCESS_SUFFIX)
## Notes: this is really the primary output of this pipeline
%.relatedness.txt$(TRACKING_SUCCESS_SUFFIX): %.fpg$(TRACKING_SUCCESS_SUFFIX)
	-$(call sub_handler,$(subst $(TRACKING_SUCCESS_SUFFIX),,$@),$(GRAF_EXECUTABLE) -geno $(subst $(TRACKING_SUCCESS_SUFFIX),,$<) -out $(subst $(TRACKING_SUCCESS_SUFFIX),,$@))
	rm -f $(subst $(TRACKING_SUCCESS_SUFFIX),$(TRACKING_FAIL_SUFFIX),$@) && touch $@

## patterns:
##    output: {CHIP}.fpg$(TRACKING_SUCCESS_SUFFIX)
##    input:  {CHIP}_rsids.bed$(TRACKING_SUCCESS_SUFFIX)
%.fpg$(TRACKING_SUCCESS_SUFFIX): %_rsids.bed$(TRACKING_SUCCESS_SUFFIX)
	-$(call sub_handler,$(subst $(TRACKING_SUCCESS_SUFFIX),,$@),$(GRAF_EXECUTABLE) -exfp $(subst .bed$(TRACKING_SUCCESS_SUFFIX),,$<) -out $(subst $(TRACKING_SUCCESS_SUFFIX),,$@) -type 4)
	rm -f $(subst $(TRACKING_SUCCESS_SUFFIX),$(TRACKING_FAIL_SUFFIX),$@) && touch $@

## test set to run after completion
check: testing/Makefile
	$(MAKE) -C testing check

testing/Makefile: testing/Makefile.am testing/configure.ac
	cd testing && autoreconf -vi && ./configure && cd ../
