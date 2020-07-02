## Cameron Palmer, 21 May 2020
## Compute relatedness estimates for each platform with GRAF

include $(PROJECT_BASE_DIR)/Makefile.config
.PHONY: all
.DELETE_ON_ERROR:
.SECONDEXPANSION:
.SECONDARY:

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

all: $(REL_OUTPUT) $(patsubst %,PLCO_%.relatedness.txt,$(POPS))

## patterns:
##    output: PLCO.relatedness.txt
##    input:  PLCO.fpg
$(REL_OUTPUT): $(FPG_OUTPUT)
	-$(GRAF_EXECUTABLE) -geno $< -out $@

## patterns:
##    output: PLCO.fpg
##    input:  PLCO_{CHIP}_rsids.bed
$(FPG_OUTPUT): $(patsubst %,PLCO_%_rsids.bed,$(POPS))
	-$(GRAF_EXECUTABLE) -exfp $(shell echo $^ | sed 's/ /,/g ; s/.bed//g')  -out $@ -type 4

## patterns:
##    output: PLCO_{CHIP}_rsids.bed
##    input:  {CHIP_FREEZE}/PLCO_{CHIP}.bed
##            {CHIP_FREEZE}/PLCO_{CHIP}.bim
##            {CHIP_FREEZE}/PLCO_{CHIP}.fam
##            GRAF.extract
##            GRAF.update_names
## Notes: the input genotype files don't tend to have rsID annotations, but GRAF assumes they're present.
## so this uses plink to update whatever IDs are present to rsIDs and only keep the IDs that are present in the GRAF backend files.
## not also that this ~~assumes both GRAF and chips are in hg19~~
PLCO_%_rsids.bed: $(CHIPS)/PLCO_%.bed $(CHIPS)/PLCO_%.bim $(CHIPS)/PLCO_%.fam GRAF.extract GRAF.update_names
	$(PLINK19) --bed $< --bim $(word 2,$^) --fam $(word 3,$^) --extract $(word 4,$^) --update-name $(word 5,$^) --make-bed --out $(subst .bed,,$@)

## patterns:
##    output: GRAF.extract
##    input:  {GRAF_backend_bimfile}
## Notes: generates a plink-format --extract file to keep only the variants in the GRAF 1KG AIMs set
GRAF.extract: $(GRAF_1KG_VARIANT_BIMFILE)
	awk '{print $$2}' $< > $@

## patterns:
##    output: GRAF.update_names
##    input: {GRAF_backend_bimfile}
## Notes: generates a plink(1.9)-format update-names file to convert chr:pos hg19 annotations to rsIDs
GRAF.update_names: $(GRAF_1KG_VARIANT_BIMFILE)
	awk '{print $$1":"$$4"\t"$$2}' $< > $@

## patterns:
##    output: PLCO_{CHIP}.relatedness.txt
##    input:  PLCO_{CHIP}.fpg
## Notes: this is really the primary output of this pipeline
PLCO_%.relatedness.txt: PLCO_%.fpg
	-$(GRAF_EXECUTABLE) -geno $< -out $@

## patterns:
##    output: PLCO_{CHIP}.fpg
##    input:  PLCO_{CHIP}_rsids.bed
PLCO_%.fpg: PLCO_%_rsids.bed
	-$(GRAF_EXECUTABLE) -exfp $(subst .bed,,$<) -out $@ -type 4
