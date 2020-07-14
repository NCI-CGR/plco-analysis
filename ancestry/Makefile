## Cameron Palmer, 21 May 2020
## Compute GRAF ancestry estimates for each chip

include $(PROJECT_BASE_DIR)/Makefile.config

## location of GRAF relatedness estimation output
## NB: this assumes the relatedness pipeline has already been run. Dependency controlled at top level directory.
REL_DIR := $(RELATEDNESS_OUTPUT_DIR)

.DELETE_ON_ERROR:
.SECONDARY:
.SECONDEXPANSION:
.PHONY: all PLCO
all: $(patsubst %,PLCO_%.graf_estimates.txt,$(foreach platform,$(PLATFORMS),$(firstword $(subst _, ,$(platform)))))

## patterns:
##    output: PLCO_{CHIP}.graf_estimates.txt
##    input:  PLCO_{CHIP}.graf_estimates.modified.txt
## Notes: this step merges the {African American and African} and {East Asian and Other Asian or Pacific Islander} ancestries.
##        this decision was made by the PLCO analysis group. this behavior can be controlled from within GRAF but, as the ancestries
##        needed to be manually modified in other ways too, I've kept the modification outside of GRAF for clarity.
%.graf_estimates.txt: %.graf_estimates.modified.txt
	awk -F"\t" '$$NF == "African" {$$NF = "African American"} ; $$NF == "Other Asian or Pacific Islander" {$$NF = "East Asian"} ; {OFS = "\t" ; print $$0}' $< > $@

## patterns:
##    output: PLCO_{CHIP}.graf_esimates.modified.txt
##    input:  PLCO_{CHIP}.graf_estimates.raw.txt
## Notes: this step merely symlinks the previous step's output for chips other than Oncoarray, for reasons described below.
%.graf_estimates.modified.txt: %.graf_estimates.raw.txt
	ln -s $< $@

## patterns:
##    output: PLCO_Oncoarray.graf_estimates.modified.txt
##    input:  PLCO_Oncoarray.graf_estimates.raw.txt
## Notes: this step manually overrides the actual GRAF ancestry estimates for three subjects that were typed on multiple platforms.
##        these three subjects were on the border between two admixed groups and different chip compositions on different platforms led
##        to different estimates. in two cases, this step is actually rendered unnecessary by the following step (merging groups), but
##        for recordkeeping the modifications are still made. for the remaining subject, the switch is from Hispanic1 -> African American,
##        which is still necessary. per the decision of the PLCO analysis group, the final ancestry for conflicting subjects is taken from
##        the denser array; as the conflict always happens to be between Oncoarray and the Omni{2.5/5} arrays, the Oncoarray is the only
##        chip that requires changing
PLCO_Oncoarray.graf_estimates.modified.txt: $$(subst .modified.txt,.raw.txt,$$@)
	awk -F"\t" '$$1 == "Q-136222-7" {$$NF = "African American"} ; $$1 == "R-042641-2" {$$NF = "African"} ; $$1 == "A-080576-5" {$$NF = "African American"} ; {OFS = "\t" ; print $$0}' $< > $@

## patterns:
##    output: PLCO_{CHIP}.graf_estimates.raw.txt
##    input:  PLCO_{CHIP}.graf_pop
%.graf_estimates.raw.txt: %.graf_pop
	-$(GRAF_POP) $< $@

## patterns:
##    output: PLCO_{CHIP}.graf_pop
##    input:  {PROJECT_BASE_DIR}/relatedness/PLCO_{CHIP}.fpg
## Notes: input is the output of the relatedness pipeline, which needs to complete before this pipeline is run.
PLCO_%.graf_pop: $(REL_DIR)/PLCO_%.fpg
	-$(GRAF_EXECUTABLE) -geno $< -pop $@

## test set to run after completion
check: testing/Makefile
	$(MAKE) -C testing check

testing/Makefile: testing/Makefile.am testing/configure.ac
	cd testing && autoreconf -vi && ./configure && cd ../
