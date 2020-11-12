## Cameron Palmer, 03 June 2020
## Create ldscores files for BOLT

include $(PROJECT_BASE_DIR)/Makefile.config

.PHONY: all
.DELETE_ON_ERROR:
.SECONDARY:
.SECONDEXPANSION:
1KG_POPS := AFR EUR SAS EAS AMR
ALL_TARGETS := $(patsubst %,LDSCORE.1000G_%.l2.ldscore-reformatted.gz$(TRACKING_SUCCESS_SUFFIX),$(1KG_POPS) ALL AFRAMR)
all: $(filter-out %_ALL.l2.ldscore-reformatted.gz$(TRACKING_SUCCESS_SUFFIX),$(ALL_TARGETS))
LDSC := $(LDSC_PY)
HG38_CM_MAP := $(GRCH38_RECOMBINATION_MAP)
MAF_THRESHOLD := $(LDSC_MAF_THRESHOLD)

## patterns:
##    output: LDSCORE.1000G_{POP}.l2.ldscore-reformatted.gz$(TRACKING_SUCCESS_SUFFIX)
##    input:  LDSCORE.1000G_{POP}.l2.ldscore.gz$(TRACKING_SUCCESS_SUFFIX)
## Notes: modify header for apparent compatibility with BOLT
$(ALL_TARGETS): $$(subst -reformatted.gz,.gz,$$@)
	$(call log_handler,$(subst $(TRACKING_SUCCESS_SUFFIX),,$@),gunzip -c $(subst $(TRACKING_SUCCESS_SUFFIX),,$<) | sed 's/L2/LDSCORE/' | gzip -c > $(subst $(TRACKING_SUCCESS_SUFFIX),,$@))

## patterns:
##    output: LDSCORE.1000G_{POP}.l2.ldscore.gz$(TRACKING_SUCCESS_SUFFIX)
##    input:  1KG_{POP}.bed$(TRACKING_SUCCESS_SUFFIX)
## Notes: run LDSC on a selected 1KG ancestry group
$(subst -reformatted.gz,.gz,$(ALL_TARGETS)): 1KG_$$(word 2,$$(subst 1000G_, ,$$(subst .l2.ldscore.gz$(TRACKING_SUCCESS_SUFFIX),,$$@))).bed$(TRACKING_SUCCESS_SUFFIX)
	$(call qsub_handler,$(subst $(TRACKING_SUCCESS_SUFFIX),,$@),$(LDSC) --bfile $(subst .bed$(TRACKING_SUCCESS_SUFFIX),,$<) --maf $(MAF_THRESHOLD) --l2 --ld-wind-cm 1 --out $(subst .l2.ldscore.gz$(TRACKING_SUCCESS_SUFFIX),,$@) > $(subst .l2.ldscore.gz$(TRACKING_SUCCESS_SUFFIX),.log,$@))

## patterns:
##    output: 1KG_AFRAMR.bed$(TRACKING_SUCCESS_SUFFIX)
##    input:  1KG_AFR.bed$(TRACKING_SUCCESS_SUFFIX)
##    input:  1KG_EUR.bed$(TRACKING_SUCCESS_SUFFIX)
## Notes: construct African American pseudo dataset by merging African and European supercontinental subjects
1KG_AFRAMR.bed$(TRACKING_SUCCESS_SUFFIX): 1KG_AFR.bed$(TRACKING_SUCCESS_SUFFIX) 1KG_EUR.bed$(TRACKING_SUCCESS_SUFFIX)
	$(call qsub_handler,$(subst $(TRACKING_SUCCESS_SUFFIX),,$@),$(PLINK19) --bfile $(subst .bed$(TRACKING_SUCCESS_SUFFIX),,$<) --bmerge $(subst .bed$(TRACKING_SUCCESS_SUFFIX),,$(word 2,$^)) --make-bed --out $(subst .bed$(TRACKING_SUCCESS_SUFFIX),,$@))

## patterns:
##    output: 1KG_ALL.bed$(TRACKING_SUCCESS_SUFFIX)
##    input:  1KG_EUR.bed$(TRACKING_SUCCESS_SUFFIX)
##    input:  1KG_ALL.merge_list$(TRACKING_SUCCESS_SUFFIX)
## Notes: construct "ALL" supergroup by merging the results of the five supercontinents
1KG_ALL.bed$(TRACKING_SUCCESS_SUFFIX): 1KG_EUR.bed$(TRACKING_SUCCESS_SUFFIX) 1KG_ALL.merge_list$(TRACKING_SUCCESS_SUFFIX)
	$(call qsub_handler,$(subst $(TRACKING_SUCCESS_SUFFIX),,$@),$(PLINK19) --bfile $(subst .bed$(TRACKING_SUCCESS_SUFFIX),,$<) --merge-list $(subst $(TRACKING_SUCCESS_SUFFIX),,$(word 2,$^)) --make-bed --out $(subst .bed$(TRACKING_SUCCESS_SUFFIX),,$@))

## patterns:
##    output: 1KG_ALL.merge_list$(TRACKING_SUCCESS_SUFFIX)
##    input:  1KG_AFR.bed$(TRACKING_SUCCESS_SUFFIX)
##    input:  1KG_AMR.bed$(TRACKING_SUCCESS_SUFFIX)
##    input:  1KG_EAS.bed$(TRACKING_SUCCESS_SUFFIX)
##    input:  1KG_SAS.bed$(TRACKING_SUCCESS_SUFFIX)
## Notes: add all but one 1KG supercontinent to a plink-format merge list
1KG_ALL.merge_list$(TRACKING_SUCCESS_SUFFIX): $(patsubst %,1KG_%.bed$(TRACKING_SUCCESS_SUFFIX),$(filter-out EUR,$(1KG_POPS)))
	$(call log_handler,$(subst $(TRACKING_SUCCESS_SUFFIX),,$@),echo "$^" | sed 's/ /\n/g ; s/\t/\n/g ; s/.bed$(TRACKING_SUCCESS_SUFFIX)//g' > $(subst $(TRACKING_SUCCESS_SUFFIX),,$@))

## patterns:
##    output: 1KG_{POP}.bed$(TRACKING_SUCCESS_SUFFIX)
##    input:  1KG_{POP}.chr1_nodups.bed$(TRACKING_SUCCESS_SUFFIX)
##    input:  1KG_{POP}.merge_list$(TRACKING_SUCCESS_SUFFIX)
## Notes: for populations other than ALL or AFRAMR, merge chromosomes into a single genome-wide dataset
$(patsubst %,1KG_%.bed$(TRACKING_SUCCESS_SUFFIX),$(1KG_POPS)): $$(subst .bed,.chr1_nodups.bed,$$@) $$(subst .bed,.merge_list,$$@)
	$(call qsub_handler,$(subst $(TRACKING_SUCCESS_SUFFIX),,$@),$(PLINK19) --bfile $(subst .bed$(TRACKING_SUCCESS_SUFFIX),,$<) --merge-list $(subst $(TRACKING_SUCCESS_SUFFIX),,$(word 2,$^)) --make-bed --out $(subst .bed$(TRACKING_SUCCESS_SUFFIX),,$@))

## patterns:
##    output: 1KG_{POP}.merge_list$(TRACKING_SUCCESS_SUFFIX)
##    input:  1KG_{POP}.chr{CHR|CHR>1}_nodups.bed$(TRACKING_SUCCESS_SUFFIX)
## Notes: add all but one chromosome to a plink-format merge list
$(patsubst %,1KG_%.merge_list$(TRACKING_SUCCESS_SUFFIX),$(1KG_POPS)): $$(patsubst %,$$(subst .merge_list$(TRACKING_SUCCESS_SUFFIX),,$$@).chr%_nodups.bed$(TRACKING_SUCCESS_SUFFIX),$$(filter-out $$(word 1,$$(CHRS)),$$(CHRS)))
	$(call log_handler,$(subst $(TRACKING_SUCCESS_SUFFIX),,$@),echo "$(subst .bed$(TRACKING_SUCCESS_SUFFIX),,$^)" | sed 's/ /\n/g ; s/\t/\n/g' > $(subst $(TRACKING_SUCCESS_SUFFIX),,$@))


## patterns:
##    output: 1KG_{POP}.chr{CHR}_nodups.bed$(TRACKING_SUCCESS_SUFFIX)
##    input:  1KG_{POP}.chr{CHR}.bed$(TRACKING_SUCCESS_SUFFIX)
##    input:  1KG_{POP}.chr{CHR}_updated-ids.bim$(TRACKING_SUCCESS_SUFFIX)
##    input:  1KG_{POP}.chr{CHR}_updated-ids.exclude$(TRACKING_SUCCESS_SUFFIX)
## Notes: remove multiallelic sites before downstream merging
1KG_%_nodups.bed$(TRACKING_SUCCESS_SUFFIX): 1KG_%.bed$(TRACKING_SUCCESS_SUFFIX) 1KG_%_updated-ids.bim$(TRACKING_SUCCESS_SUFFIX) 1KG_%_updated-ids.exclude$(TRACKING_SUCCESS_SUFFIX)
	$(call qsub_handler,$(subst $(TRACKING_SUCCESS_SUFFIX),,$@),$(PLINK19) --bed $(subst $(TRACKING_SUCCESS_SUFFIX),,$<) --bim $(subst $(TRACKING_SUCCESS_SUFFIX),,$(word 2,$^)) --fam $(subst .bed$(TRACKING_SUCCESS_SUFFIX),.fam,$<) --exclude $(subst $(TRACKING_SUCCESS_SUFFIX),,$(lastword $^)) --make-bed --out $(subst .bed$(TRACKING_SUCCESS_SUFFIX),,$@))

## patterns:
##    output: 1KG_{POP}.chr{CHR}_updated-ids.exclude$(TRACKING_SUCCESS_SUFFIX)
##    input:  1KG_{POP}.chr{CHR}_updated-ids.bim$(TRACKING_SUCCESS_SUFFIX)
## Notes: flag multiallelic sites for removal before downstream merging
1KG_%_updated-ids.exclude$(TRACKING_SUCCESS_SUFFIX): 1KG_%_updated-ids.bim$(TRACKING_SUCCESS_SUFFIX)
	$(call log_handler,$(subst $(TRACKING_SUCCESS_SUFFIX),,$@),awk '{print $$1":"$$4}' $(subst $(TRACKING_SUCCESS_SUFFIX),,$<) | sort | uniq -d | grep -wf - $(subst $(TRACKING_SUCCESS_SUFFIX),,$<) | awk '{print $$2}' > $(subst $(TRACKING_SUCCESS_SUFFIX),,$@))

## patterns:
##    output: 1KG_{POP}.chr{CHR}_updated-ids.bim$(TRACKING_SUCCESS_SUFFIX)
##    input:  1KG_{POP}.chr{CHR}.bed$(TRACKING_SUCCESS_SUFFIX) [really .bim]
## Notes: synchronize variant IDs with CHR:POS:A1:A2 nomenclature. be careful not to break file's relationship with .bed
1KG_%_updated-ids.bim$(TRACKING_SUCCESS_SUFFIX): 1KG_%.bed$(TRACKING_SUCCESS_SUFFIX)
	$(call log_handler,$(subst $(TRACKING_SUCCESS_SUFFIX),,$@),awk '$$5 < $$6 {print $$1"\t"$$1":"$$4":"$$5":"$$6"\t"$$3"\t"$$4"\t"$$5"\t"$$6} ; $$5 >= $$6 {print $$1"\t"$$1":"$$4":"$$6":"$$5"\t"$$3"\t"$$4"\t"$$5"\t"$$6}' $(subst .bed$(TRACKING_SUCCESS_SUFFIX),.bim,$<) > $(subst .success,,$@))

## patterns:
##    output: 1KG_{POP}.{CHR}.bed$(TRACKING_SUCCESS_SUFFIX)
##    input:  {1KG data for chromosome CHR}
##    input:  {POP}.samples.plinkformat.tsv$(TRACKING_SUCCESS_SUFFIX)
##    input:  genetic_map_chr{CHR}.txt$(TRACKING_SUCCESS_SUFFIX)
## Notes: parse 1000 Genomes vcf data for a chromosome, extract subjects from desired ancestry, write to plink bed/bim/fam
1KG_%.bed$(TRACKING_SUCCESS_SUFFIX): $$(KG_GENOTYPES_PREFIX)$$(subst chr,,$$(word 2,$$(subst ., ,$$@)))$(KG_GENOTYPES_SUFFIX) $$(word 1,$$(subst 1KG_,,$$(subst .chr, ,$$@))).samples.plinkformat.tsv$(TRACKING_SUCCESS_SUFFIX) genetic_map_chr$$(subst chr,,$$(word 2,$$(subst ., ,$$@))).txt$(TRACKING_SUCCESS_SUFFIX)
	$(call qsub_handler,$(subst $(TRACKING_SUCCESS_SUFFIX),,$@),$(PLINK19) --vcf $< --double-id --vcf-half-call m --keep $(subst $(TRACKING_SUCCESS_SUFFIX),,$(word 2,$^)) --cm-map $(subst $(TRACKING_SUCCESS_SUFFIX),,$(word 3,$^)) $(word 2,$(subst .chr, ,$(subst .bed$(TRACKING_SUCCESS_SUFFIX),,$@))) --make-bed --out $(subst .bed$(TRACKING_SUCCESS_SUFFIX),,$@))

## patterns:
##    output: {POP}.samples.plinkformat.tsv$(TRACKING_SUCCESS_SUFFIX)
##    input:  {POP}_samples.tsv
## Notes: reformat 1000 Genomes supercontinent membership data into plink keep format.
## untracked, derived from http://ftp.1000genomes.ebi.ac.uk/vol1/ftp/technical/working/20130606_sample_info/20130606_sample_info.xlsx
%.samples.plinkformat.tsv$(TRACKING_SUCCESS_SUFFIX): %_samples.tsv
	$(call log_handler,$(subst $(TRACKING_SUCCESS_SUFFIX),,$@),awk '{print $$1"\t"$$1}' $(subst $(TRACKING_SUCCESS_SUFFIX),,$<) > $(subst $(TRACKING_SUCCESS_SUFFIX),,$@))

## patterns:
##    output: genetic_map_chr{CHR}.txt$(TRACKING_SUCCESS_SUFFIX)
##    input:  [genome-wide recombination map, likely bundled with BOLT]
## Notes: extract relevant chromosome and fix format of recombination data for use with LDSC
genetic_map_chr%.txt$(TRACKING_SUCCESS_SUFFIX): $(HG38_CM_MAP)
	$(call log_handler,$(subst $(TRACKING_SUCCESS_SUFFIX),,$@),gunzip -c $< | awk 'NR == 1 {print "pposition rrate gposition"} ; NR > 1 && $$1 == "$(subst genetic_map_chr,,$(subst .txt$(TRACKING_SUCCESS_SUFFIX),,$@))" {print $$2" "$$3" "$$4}' > $(subst $(TRACKING_SUCCESS_SUFFIX),,$@))

## test set to run after completion
check: testing/Makefile$(TRACKING_SUCCESS_SUFFIX)
	$(MAKE) -C testing check

testing/Makefile$(TRACKING_SUCCESS_SUFFIX): testing/Makefile.am testing/configure.ac
	$(call log_handler,$(subst $(TRACKING_SUCCESS_SUFFIX),,$@),cd testing && autoreconf -vi && ./configure && cd ../)


