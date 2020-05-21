include ../PLCO_config.Makefile
.PHONY: all
.DELETE_ON_ERROR:
.SECONDEXPANSION:
.SECONDARY:
FPG_OUTPUT := PLCO.fpg
REL_OUTPUT := PLCO.relatedness.txt
POPS := $(PROJECT_NAMES)
all: $(ANC_OUTPUT) $(REL_OUTPUT) $(patsubst %,PLCO_%.relatedness.txt,$(POPS))
GRAF := /CGF/Bioinformatics/Production/palmercd/GRAF/GRAF/graf
PLINK := plink

$(REL_OUTPUT): $(FPG_OUTPUT)
	-$(GRAF) -geno $< -out $@

$(FPG_OUTPUT): $(patsubst %,PLCO_%_rsids.bed,$(POPS))
	-$(GRAF) -exfp $(shell echo $^ | sed 's/ /,/g ; s/.bed//g')  -out $@ -type 4

PLCO_%_rsids.bed: $(FINAL_CHIP_DATA)/PLCO_%.bed $(FINAL_CHIP_DATA)/PLCO_%.bim $(FINAL_CHIP_DATA)/PLCO_%.fam GRAF.extract GRAF.update_names
	$(PLINK) --bed $< --bim $(word 2,$^) --fam $(word 3,$^) --extract $(word 4,$^) --update-name $(word 5,$^) --make-bed --out $(subst .bed,,$@)

#PLCO_GSA_rsids.bed: $(FINAL_CHIP_DATA)/PLCO_GSA.bed $(FINAL_CHIP_DATA)/PLCO_GSA.bim $(FINAL_CHIP_DATA)/PLCO_GSA.fam GRAF.extract GRAF.update_names
#	$(PLINK) --bed $< --bim $(word 2,$^) --fam $(word 3,$^) --extract $(word 4,$^) --update-name $(word 5,$^) --exclude-snp 17:49461290 --make-bed --out $(subst .bed,,$@)

GRAF.extract: /CGF/Bioinformatics/Production/palmercd/GRAF/GRAF/G1000FpGeno.bim
	awk '{print $$2}' $< > $@

GRAF.update_names: /CGF/Bioinformatics/Production/palmercd/GRAF/GRAF/G1000FpGeno.bim
	awk '{print $$1":"$$4"\t"$$2}' $< > $@


PLCO_%.relatedness.txt: PLCO_%.fpg
	-$(GRAF) -geno $< -out $@

PLCO_%.fpg: PLCO_%_rsids.bed
	-$(GRAF) -exfp $(subst .bed,,$<) -out $@ -type 4
