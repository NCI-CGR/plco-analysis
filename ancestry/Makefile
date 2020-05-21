include ../PLCO_config.Makefile

GRAF_EXECUTABLE := /CGF/Bioinformatics/Production/palmercd/GRAF/GRAF/graf
GRAF_POP := /CGF/Bioinformatics/Production/palmercd/GRAF/GRAF/PlotPopulations.pl
GRAF_1KG_VARIANT_BIMFILE := /CGF/Bioinformatics/Production/palmercd/GRAF/GRAF/G1000FpGeno.bim

.DELETE_ON_ERROR:
.SECONDARY:
.SECONDEXPANSION:
.PHONY: all PLCO
all: PLCO.graf_estimates.txt $(patsubst %,PLCO_%.graf_estimates.txt,$(PROJECT_NAMES))

%.graf_estimates.txt: %.graf_estimates.modified.txt
	awk -F"\t" '$$NF == "African" {$$NF = "African American"} ; $$NF == "Other Asian or Pacific Islander" {$$NF = "East Asian"} ; {OFS = "\t" ; print $$0}' $< > $@

%.graf_estimates.modified.txt: %.graf_estimates.raw.txt
	cp $< $@

PLCO_Oncoarray.graf_estimates.modified.txt: $$(subst .modified.txt,.raw.txt,$$@)
	awk -F"\t" '$$1 == "Q-136222-7" {$$NF = "African American"} ; $$1 == "R-042641-2" {$$NF = "African"} ; $$1 == "A-080576-5" {$$NF = "African American"} ; {OFS = "\t" ; print $$0}' $< > $@

%.graf_estimates.raw.txt: %.graf_pop
	-$(GRAF_POP) $< $@

PLCO_%.graf_pop: $(PROJECT_DIRECTORY)/relatedness/PLCO_%.fpg
	-$(GRAF_EXECUTABLE) -geno $< -pop $@

%.graf_pop: $(PROJECT_DIRECTORY)/relatedness/PLCO.fpg
	-$(GRAF_EXECUTABLE) -geno $< -pop $@
