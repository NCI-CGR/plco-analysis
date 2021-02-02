Methods Summary
===============

Preface
-------

This document assumes you are using as input the PLCO chip freeze,
imputed data freeze, and IMS phenotype data (v10). A description of
the methods leading to these files is beyond scope and can be found
elsewhere.

Preprocessing
-------------

Relatedness Estimation
~~~~~~~~~~~~~~~~~~~~~~

Genotype data from the five PLCO platforms were updated to match
the variant IDs present in the `graf`_ reference dataset ``G1000GpGeno``.
Each chip dataset in turn was converted to `graf`_ fpg format and used
to estimate within-platform subject relatedness with ``graf -geno``.

.. _graf: https://github.com/ncbi/graf

Ancestry Estimation
~~~~~~~~~~~~~~~~~~~

Genotype data from relatedness estimation were used to estimate
subject ancestry with ``graf -pop`` and `graf`_ ``PlotPopulations.pl``.
As ancestry estimation was conducted separately for each platform,
several subjects with borderline ancestry calls had discordant ancestry
calls between platforms. In these instances, the ancestry call was resolved
by setting the call from the Oncoarray (which happened to always be involved
in these discordances) to the calls determined from denser arrays.

Chip Cleaning by Ancestry Group
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Genotype data from each of the five PLCO platforms were split by ancestry
using the computed `graf`_ ancestry calls. Variants were filtered within
platform/ancestry subset, removing variants with minor allele frequency
less than 1%, variant-level missingness greater than 2%, or Hard-Weinberg
Equilibrium exact p-value less than 0.001 using `plink 1.9`_. The remaining
variants were then weakly pruned for linkage equilibrium using successive
passes of `plink 1.9`_ commands ``--indep 50 5 2`` and ``--indep-pairwise 50 5 0.2``.
Heterozygosity outliers were computed and removed at ``|F| > 0.2``.
Principal components within platform/ancestry subset were estimated using `smartpca`_ fastmode.

.. _`plink 1.9`: https://www.cog-genomics.org/plink/

.. _`smartpca`: http://data.broadinstitute.org/alkesgroup/EIGENSOFT/


LD Score Regression Reference Files
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

1000 Genomes reference files in GRCh38 tagged ``20181203`` were downloaded from
the `1000 Genomes ftp site`_. Genotypes were split out by 1000 Genomes supercontinent
(AFR: African; AMR: admixed American; EAS: East Asian; EUR: European; SAS: South Asian),
converted to plink format with `plink 1.9`_, updated with genetic map estimates from the
hg38 recombination map provided with `BOLT-LMM`_. LD Score estimates for these reference
groups were estimated by `ldsc`_ with the following options:
``ldsc.py --maf 0.005 --l2 --ld-wind-cm 1``. For datasets for which these data are available,
stock reference data were downloaded from ``https://data.broadinstitute.org/alkesgroup/LDSCORE/``.

.. _`1000 Genomes ftp site`: ftp://ftp.1000genomes.ebi.ac.uk/vol1/ftp/data_collections/1000_genomes_project/release

.. _`BOLT-LMM`: https://alkesgroup.broadinstitute.org/BOLT-LMM

.. _`ldsc`: https://github.com/bulik/ldsc

BGEN v1.2 Imputed Data Conversion
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

All primary analysis tools used during initial "Atlas" testing accepted `bgen v1.2`_ format
imputed data, so all imputed genotypes were converted to this format with `plink 2`_ in two
passes. The data were first converted to ``pgen`` format with ``plink2 --vcf {file} dosage=HDS --id-delim _ --make-pgen erase-phase``;
then the resulting pgen files were reformatted to `bgen v1.2`_ with ``plink2 --recode bgen-1.2 bits=8``.

.. _`bgen v1.2`: https://www.well.ox.ac.uk/~gav/bgen_format/

.. _`plink 2`: https://www.cog-genomics.org/plink/2.0/


Primary Analysis
----------------

Phenotype Modeling
~~~~~~~~~~~~~~~~~~

Phenotype and covariate data from IMS v10, along with indicator variables reporting
genotyping platform batch and ``Other Asian`` raw ancestry calls from `graf`_,
were processed and formatted into model matrix files. Continuous traits were
inverse normal transformed within ancestry group, stratified by sex. Categorical
traits were processed into individual binary contrasts between a single reference
group (category 0, with the largest number of subjects); any non-reference group
with fewer than 10 subjects was combined into a single meta-group based on
the PLCO analysis plan document guidelines. All categorical covariates were similarly
processed, and turned into binary covariates to maintain compatibility with
analysis tools without direct support for qualitative covariates.

Primary Analysis with BOLT-LMM
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

For each platform/ancestry combination with at least 3000 subjects, chip subsets
corresponding to these data were lifted from GRCh37 to GRCh38 with `liftOver`_.
Linear mixed model association with `BOLT-LMM`_ was run with the following parameters:

* ``--bgenFile {filename}``
* ``--sampleFile {filename}``
* ``--lmm``
* ``--LDscoresFile {filename}``
* ``--statsFile {filename}``
* ``--statsFileBgenSnps {filename}``
* ``--phenoFile {filename}``
* ``--phenoCol {column name}``
* ``--covarFile {filename}``
* ``--qCovarCol {covariate list}``
* ``--LDscoresMatchBp``
* ``--geneticMapFile {filename}``

.. _`liftover`: http://hgdownload.soe.ucsc.edu/admin/exe/

Primary Analysis with SAIGE
~~~~~~~~~~~~~~~~~~~~~~~~~~~

For each platform/ancestry combination with at least 1000 subjects and 30 cases
for a given model matrix, chip subsets corresponding to these data were lifted
from GRCh37 to GRCh38 with `liftOver`_. Logistic mixed model association with `SAIGE`_
was run in two passes with the following functions and settings.

For round one:

* ``SAIGE::fitNULLGLMM``
* ``plinkFile {file prefix}``
* ``phenoFile {filename}``
* ``phenoCol {column name}``
* ``sampleIDColinphenoFile {column name}``
* ``covarColList {covariate list}``
* ``nThreads 4``
* ``traitType "binary"``
* ``outputPrefix {file prefix}``
* ``IsSparseKin TRUE``
* ``relatednessCutoff 0.05``

For round two:

* ``SAIGE::SPAGMMATtest``
* ``bgenFile {filename}``
* ``bgenFileIndex {filename}``
* ``vcfField DS``
* ``chrom {chromosome}``
* ``minMAF 0.01``
* ``GMMATmodelFile {filename}``
* ``sampleFile {filename}``
* ``minMAC 1``
* ``varianceRatioFile {filename}``
* ``SAIGEOutputFile {filename}``
* ``IsOutputAFinCaseCtrl TRUE``
* ``sparseSigmaFile {filename}``
  
.. _`SAIGE`: https://github.com/weizhouUMICH/SAIGE

Primary Analysis Postprocessing
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

After each analysis, the native result format was converted to the file
format agreed upon with CBIIT. Allele frequencies from raw results were updated
to approximate TOPMed reference frequencies estimated from test imputations
of 1000 Genomes subjects from each supercontinent versus the TOPMed 5b reference panel.


Meta-Analysis
-------------

For each continuous and binary phenotype, platform subsets of the same `graf`_ ancestry group
were meta-analyzed together with `metal`_ with heterogeneity analysis.

For categorical phenotypes, each ancestry group was meta-analyzed across platforms as
listed above. Then, each of the (N-1) binary comparisons against the same reference
group were combined using a Bonferroni correction on the minimum p-value per variant,
correcting for (N-1) tests. This p-value is biased by minimum p-value selection,
and should be replaced in future iterations of this analysis.

.. _`metal`: https://genome.sph.umich.edu/wiki/METAL


LD Score Regression
-------------------

Results files from each analysis were processed to contain
signed summary statistics. These files were then processed with the `ldsc`_
helper script ``munge_sumstats.py`` using the following parameters:

* ``--signed-sumstats STAT,0``
* ``--out {filename}``
* ``--a1-inc``
* ``--frq Freq_Tested_Allele_in_TOPMed``
* ``--N-col N``
* ``--a1 Tested_Allele``
* ``--a2 Other_Allele``
* ``--snp SNP``
* ``--sumstats {filename}``
* ``--p P``


Finally, the resulting processed files were used to estimate LD score regression
intercepts with `ldsc`_ script ``ldsc.py`` against reference LD scores from the
matched supercontinent.
