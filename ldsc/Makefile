## Cameron Palmer, 03 June 2020
## Create ldscores files for BOLT

include $(PROJECT_BASE_DIR)/Makefile.config

.PHONY: all
.DELETE_ON_ERROR:
.SECONDARY:
.SECONDEXPANSION:
1KG_POPS := AFR EUR SAS EAS AMR
ALL_TARGETS := $(patsubst %,LDSCORE.1000G_%.l2.ldscore-reformatted.gz,$(1KG_POPS) ALL AFRAMR)
all: $(filter-out LDSCORE.1000G_ALL.l2.ldscore-reformatted.gz,$(ALL_TARGETS))
LDSC := $(LDSC_PY)
HG38_CM_MAP := $(GRCH38_RECOMBINATION_MAP)
MAF_THRESHOLD := $(LDSC_MAF_THRESHOLD)

## patterns:
##    output: LDSCORE.1000G_{POP}.l2.ldscore-reformatted.gz
##    input:  LDSCORE.1000G_{POP}.l2.ldscore.gz.success
## Notes: modify header for apparent compatibility with BOLT
$(ALL_TARGETS): $$(subst -reformatted.gz,.gz.success,$$@)
	gunzip -c $(subst .success,,$<) | sed 's/L2/LDSCORE/' | gzip -c > $@

## patterns:
##    output: LDSCORE.1000G_{POP}.l2.ldscore.gz.success
##    input:  1KG_{POP}.bed.success
## Notes: run LDSC on a selected 1KG ancestry group
$(subst -reformatted.gz,.gz.success,$(ALL_TARGETS)): 1KG_$$(word 2,$$(subst 1000G_, ,$$(subst .l2.ldscore.gz.success,,$$@))).bed.success
	$(call qsub_handler,$(subst .success,,$@),$(LDSC) --bfile $(subst .bed.success,,$<) --maf $(MAF_THRESHOLD) --l2 --ld-wind-cm 1 --out $(subst .l2.ldscore.gz.success,,$@) > $(subst .l2.ldscore.gz.success,.log,$@))

## patterns:
##    output: 1KG_AFRAMR.bed.success
##    input:  1KG_AFR.bed.success
##    input:  1KG_EUR.bed.success
## Notes: construct African American pseudo dataset by merging African and European supercontinental subjects
1KG_AFRAMR.bed.success: 1KG_AFR.bed.success 1KG_EUR.bed.success
	$(call qsub_handler,$(subst .success,,$@),$(PLINK19) --bfile $(subst .bed.success,,$<) --bmerge $(subst .bed.success,,$(word 2,$^)) --make-bed --out $(subst .bed.success,,$@))

## patterns:
##    output: 1KG_ALL.bed.success
##    input:  1KG_EUR.bed.succcess
##    input:  1KG_ALL.merge_list
## Notes: construct "ALL" supergroup by merging the results of the five supercontinents
1KG_ALL.bed.success: 1KG_EUR.bed.success 1KG_ALL.merge_list
	$(call qsub_handler,$(subst .success,,$@),$(PLINK19) --bfile $(subst .bed.success,,$<) --merge-list $(word 2,$^) --make-bed --out $(subst .bed.success,,$@))

## patterns:
##    output: 1KG_ALL.merge_list
##    input:  1KG_AFR.bed.success
##    input:  1KG_AMR.bed.success
##    input:  1KG_EAS.bed.success
##    input:  1KG_SAS.bed.success
## Notes: add all but one 1KG supercontinent to a plink-format merge list
1KG_ALL.merge_list: $(patsubst %,1KG_%.bed.success,$(filter-out EUR,$(1KG_POPS)))
	echo "$^" | sed 's/ /\n/g ; s/\t/\n/g ; s/.bed.success//g' > 1KG_ALL.merge_list

## patterns:
##    output: 1KG_{POP}.bed.success
##    input:  1KG_{POP}.chr1_nodups.bed.success
##    input:  1KG_{POP}.merge_list
## Notes: for populations other than ALL or AFRAMR, merge chromosomes into a single genome-wide dataset
$(patsubst %,1KG_%.bed.success,$(1KG_POPS)): $$(subst .bed.success,.chr1_nodups.bed.success,$$@) $$(subst .bed.success,.merge_list,$$@)
	$(call qsub_handler,$(subst .success,,$@),$(PLINK19) --bfile $(subst .bed.success,,$<) --merge-list $(word 2,$^) --make-bed --out $(subst .bed.success,,$@))

## patterns:
##    output: 1KG_{POP}.merge_list
##    input:  1KG_{POP}.chr{CHR|CHR>1}_nodups.bed.success
## Notes: add all but one chromosome to a plink-format merge list
$(patsubst %,1KG_%.merge_list,$(1KG_POPS)): $$(patsubst %,$$(subst .merge_list,,$$@).chr%_nodups.bed.success,$$(filter-out $$(word 1,$$(CHRS)),$$(CHRS)))
	echo "$(subst .bed.success,,$^)" | sed 's/ /\n/g ; s/\t/\n/g' > $@


## patterns:
##    output: 1KG_{POP}.chr{CHR}_nodups.bed.success
##    input:  1KG_{POP}.chr{CHR}.bed.success
##    input:  1KG_{POP}.chr{CHR}_updated-ids.bim
##    input:  1KG_{POP}.chr{CHR}_updated-ids.exclude
## Notes: remove multiallelic sites before downstream merging
1KG_%_nodups.bed.success: 1KG_%.bed.success 1KG_%_updated-ids.bim 1KG_%_updated-ids.exclude
	$(call qsub_handler,$(subst .success,,$@),$(PLINK19) --bed $(subst .success,,$<) --bim $(word 2,$^) --fam $(subst .bed.success,.fam,$<) --exclude $(lastword $^) --make-bed --out $(subst .bed.success,,$@))

## patterns:
##    output: 1KG_{POP}.chr{CHR}_updated-ids.exclude
##    input:  1KG_{POP}.chr{CHR}_updated-ids.bim
## Notes: flag multiallelic sites for removal before downstream merging
1KG_%_updated-ids.exclude: 1KG_%_updated-ids.bim
	awk '{print $$1":"$$4}' $< | sort | uniq -d | grep -wf - $< | awk '{print $$2}' > $@

## patterns:
##    output: 1KG_{POP}.chr{CHR}_updated-ids.bim
##    input:  1KG_{POP}.chr{CHR}.bed.success [really .bim]
## Notes: synchronize variant IDs with CHR:POS:A1:A2 nomenclature. be careful not to break file's relationship with .bed
1KG_%_updated-ids.bim: 1KG_%.bed.success
	awk '$$5 < $$6 {print $$1"\t"$$1":"$$4":"$$5":"$$6"\t"$$3"\t"$$4"\t"$$5"\t"$$6} ; $$5 >= $$6 {print $$1"\t"$$1":"$$4":"$$6":"$$5"\t"$$3"\t"$$4"\t"$$5"\t"$$6}' $(subst .bed.success,.bim,$<) > $@

## patterns:
##    output: 1KG_{POP}.{CHR}.bed.success
##    input:  {1KG data for chromosome CHR}
##    input:  {POP}.samples.plinkformat.tsv
##    input:  genetic_map_chr{CHR}.txt
## Notes: parse 1000 Genomes vcf data for a chromosome, extract subjects from desired ancestry, write to plink bed/bim/fam
1KG_%.bed.success: $$(KG_GENOTYPES_PREFIX)$$(subst chr,,$$(word 2,$$(subst ., ,$$@)))$(KG_GENOTYPES_SUFFIX) $$(word 1,$$(subst 1KG_,,$$(subst .chr, ,$$@))).samples.plinkformat.tsv genetic_map_chr$$(subst chr,,$$(word 2,$$(subst ., ,$$@))).txt
	$(call qsub_handler,$(subst .success,,$@),$(PLINK19) --vcf $< --double-id --vcf-half-call m --keep $(word 2,$^) --cm-map $(word 3,$^) $(word 2,$(subst .chr, ,$(subst .bed.success,,$@))) --make-bed --out $(subst .bed.success,,$@))

## patterns:
##    output: {POP}.samples.plinkformat.tsv
##    input:  {POP}_samples.tsv
## Notes: reformat 1000 Genomes supercontinent membership data into plink keep format.
## untracked, derived from http://ftp.1000genomes.ebi.ac.uk/vol1/ftp/technical/working/20130606_sample_info/20130606_sample_info.xlsx
%.samples.plinkformat.tsv: %_samples.tsv
	awk '{print $$1"\t"$$1}' $< > $@

## patterns:
##    output: genetic_map_chr{CHR}.txt
##    input:  [genome-wide recombination map, likely bundled with BOLT]
## Notes: extract relevant chromosome and fix format of recombination data for use with LDSC
genetic_map_chr%.txt: $(HG38_CM_MAP)
	gunzip -c $< | awk 'NR == 1 {print "pposition rrate gposition"} ; NR > 1 && $$1 == $(subst genetic_map_chr,,$(subst .txt.gz,,$@)) {print $$2" "$$3" "$$4}' > $@
