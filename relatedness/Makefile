## Cameron Palmer, 21 May 2020
## Compute relatedness estimates for each platform with GRAF

include $(PROJECT_BASE_DIR)/Makefile.config
.PHONY: all
.DELETE_ON_ERROR:
.SECONDEXPANSION:
.SECONDARY:

## Computing the all-platforms relatedness file is slow and not required for the pipeline as-is;
##   however, there are plenty of applications and QC steps that would require it. If you want it
##   to be generated, define the below variable as anything at all and it will be added to the target set.
GENERATE_CROSS_PLATFORM_RELATEDNESS :=

## So initially, long ago, the relatedness estimation was being conducted across the entire study.
## For whatever reason, these results were discarded in favor of within-platform estimates.
## Regardless, I've kept the between-platform estimates in here imagining someone will want them someday.
FPG_OUTPUT := PLCO.fpg
REL_OUTPUT := PLCO.relatedness.txt
POPS := $(sort $(foreach platform,$(PLATFORMS),$(firstword $(subst _, ,$(platform)))))
CHIPS := $(CHIP_FREEZE_INPUT_DIR)

## all targets are both the between-platform estimates and the within-platform estimates only.
## note that you can extract the within-platform estimates from the between-platform version
## if you prefer and it would make things go faster, but as this is only run once, it doesn't
## make much of a difference, and removes a step that I'd otherwise be manually manipulating.

all: $(addsuffix $(TRACKING_SUCCESS_SUFFIX),$(if $(GENERATE_CROSS_PLATFORM_RELATEDNESS),$(REL_OUTPUT),) $(patsubst %,PLCO_%.relatedness.txt,$(POPS)))

## patterns:
##    output: PLCO.relatedness.txt$(TRACKING_SUCCESS_SUFFIX)
##    input:  PLCO.fpg$(TRACKING_SUCCESS_SUFFIX)
## Notes: GRAF doesn't return sensible error codes so it's hard to tell if it worked. Require make check to continue.
##    In place of make's internal ignore return code feature, override the default success/fail tracking behavior for excepted rules.
$(REL_OUTPUT)$(TRACKING_SUCCESS_SUFFIX): $(FPG_OUTPUT)$(TRACKING_SUCCESS_SUFFIX)
	-$(call log_handler,$(subst $(TRACKING_SUCCESS_SUFFIX),,$@),$(GRAF_EXECUTABLE) -geno $(subst $(TRACKING_SUCCESS_SUFFIX),,$<) -out $(subst $(TRACKING_SUCCESS_SUFFIX),,$@))
	rm -f $(subst $(TRACKING_SUCCESS_SUFFIX),$(TRACKING_FAIL_SUFFIX),$@) && touch $@

## patterns:
##    output: PLCO.fpg$(TRACKING_SUCCESS_SUFFIX)
##    input:  PLCO_{CHIP}_rsids.bed$(TRACKING_SUCCESS_SUFFIX)
$(FPG_OUTPUT)$(TRACKING_SUCCESS_SUFFIX): $(patsubst %,PLCO_%_rsids.bed$(TRACKING_SUCCESS_SUFFIX),$(POPS))
	-$(call log_handler,$(subst $(TRACKING_SUCCESS_SUFFIX),,$@),$(GRAF_EXECUTABLE) -exfp $(shell echo $(subst $(TRACKING_SUCCESS_SUFFIX),,$^) | sed 's/ /,/g ; s/.bed//g')  -out $(subst $(TRACKING_SUCCESS_SUFFIX),,$@) -type 4)
	rm -f $(subst $(TRACKING_SUCCESS_SUFFIX),$(TRACKING_FAIL_SUFFIX),$@) && touch $@

## patterns:
##    output: PLCO_{CHIP}_rsids.bed$(TRACKING_SUCCESS_SUFFIX)
##    input:  {CHIP_FREEZE}/PLCO_{CHIP}.bed
##            {CHIP_FREEZE}/PLCO_{CHIP}.bim
##            {CHIP_FREEZE}/PLCO_{CHIP}.fam
##            GRAF.extract$(TRACKING_SUCCESS_SUFFIX)
##            GRAF.update_names$(TRACKING_SUCCESS_SUFFIX)
## Notes: the input genotype files don't tend to have rsID annotations, but GRAF assumes they're present.
## so this uses plink to update whatever IDs are present to rsIDs and only keep the IDs that are present in the GRAF backend files.
## not also that this ~~assumes both GRAF and chips are in hg19~~
PLCO_%_rsids.bed$(TRACKING_SUCCESS_SUFFIX): $(CHIPS)/PLCO_%.bed $(CHIPS)/PLCO_%.bim $(CHIPS)/PLCO_%.fam GRAF.extract$(TRACKING_SUCCESS_SUFFIX) GRAF.update_names$(TRACKING_SUCCESS_SUFFIX)
	$(call qsub_handler,$(subst $(TRACKING_SUCCESS_SUFFIX),,$@),$(PLINK19) --bed $< --bim $(word 2,$^) --fam $(word 3,$^) --extract $(subst $(TRACKING_SUCCESS_SUFFIX),,$(word 4,$^)) --update-name $(subst $(TRACKING_SUCCESS_SUFFIX),,$(word 5,$^)) --make-bed --out $(subst .bed$(TRACKING_SUCCESS_SUFFIX),,$@))

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
##    output: PLCO_{CHIP}.relatedness.txt$(TRACKING_SUCCESS_SUFFIX)
##    input:  PLCO_{CHIP}.fpg$(TRACKING_SUCCESS_SUFFIX)
## Notes: this is really the primary output of this pipeline
PLCO_%.relatedness.txt$(TRACKING_SUCCESS_SUFFIX): PLCO_%.fpg$(TRACKING_SUCCESS_SUFFIX)
	-$(call log_handler,$(subst $(TRACKING_SUCCESS_SUFFIX),,$@),$(GRAF_EXECUTABLE) -geno $(subst $(TRACKING_SUCCESS_SUFFIX),,$<) -out $(subst $(TRACKING_SUCCESS_SUFFIX),,$@))
	rm -f $(subst $(TRACKING_SUCCESS_SUFFIX),$(TRACKING_FAIL_SUFFIX),$@) && touch $@

## patterns:
##    output: PLCO_{CHIP}.fpg$(TRACKING_SUCCESS_SUFFIX)
##    input:  PLCO_{CHIP}_rsids.bed$(TRACKING_SUCCESS_SUFFIX)
PLCO_%.fpg$(TRACKING_SUCCESS_SUFFIX): PLCO_%_rsids.bed$(TRACKING_SUCCESS_SUFFIX)
	-$(call log_handler,$(subst $(TRACKING_SUCCESS_SUFFIX),,$@),$(GRAF_EXECUTABLE) -exfp $(subst .bed$(TRACKING_SUCCESS_SUFFIX),,$<) -out $(subst $(TRACKING_SUCCESS_SUFFIX),,$@) -type 4)
	rm -f $(subst $(TRACKING_SUCCESS_SUFFIX),$(TRACKING_FAIL_SUFFIX),$@) && touch $@

## test set to run after completion
check: testing/Makefile
	$(MAKE) -C testing check

testing/Makefile: testing/Makefile.am testing/configure.ac
	cd testing && autoreconf -vi && ./configure && cd ../
