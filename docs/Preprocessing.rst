Preprocessing
=============

Overview
~~~~~~~~

This content should provide an overview of the one-time steps you'll need to perform when running this pipeline for the first time
on a given chip or imputation build. You do not need to run this multiple times for the same build! This should save you lots of time.

.. _`relatedness pipeline`:

Relatedness
~~~~~~~~~~~

Relatedness estimation is primarily required as an intermediate in the ancestry estimation process using graf_. The files are stored
and can be used for other QC reasons of course; see **relatedness/PLCO_{chip_name}.relatedness.txt** for relevant output files in standard
graf format.

*  Usage: **make relatedness**
*  Dependencies:

   *  chip freeze
      
*  Assumptions:

   *  input chip data are in plink_ bed/bim/fam format
   *  variant annotations are in GRCh38

.. _graf: https://github.com/ncbi/graf

.. _plink: https://www.cog-genomics.org/plink/

.. topic:: Debugging
   
   Very little can go wrong in this early step of the pipeline. Most likely any issues would be related to fundamental
   misunderstandings about the formatting of the input chip data.
   
.. warning::

   graf_ is mildly frustrating to use: it has some non-compliant behaviors. Notably, its exit codes are not standard,
   so it doesn't exit `0` on success. Always check the output log from graf_ before proceeding! And note that the overall
   `make` run will have some "exit code ignored" warnings due to this behavior.
   
   Additionally, graf_ complains when the output files it tries to create already exist. So, if you're running graf_ in an
   existing directory, you will likely need to purge intermediates (or just kill the "relatedness/" directory and check it out again)
   before rerunning. However, this is an early step that doesn't expect to be rerun frequently. It can definitely be patched to
   work better; or you can use the version in the upstream QC pipeline that's much better.

.. _`ancestry pipeline`:

Ancestry Estimation
~~~~~~~~~~~~~~~~~~~

Ancestry estimation is required for chip processing and various sanity checks. As with relatedness, this is computed with graf_. The files
are stored and can be used for various QC purposes; see **ancestry/PLCO_{chip_name}.graf_estimates.txt**.

Note that the final ancestry calls listed above are modified according to the consensus instructions of the "Atlas" analysis group.
Subjects from the default "African" graf_ ancestry are merged into the "African American" label to more consistently represent
the sampling distribution of the PLCO project. Subjects from the default "Other Asian or Pacific Islander" graf_ ancestry are merged
into the "East Asian" label according to the instructions of collaborators.

*  Usage: **make ancestry**
*  Dependencies:

   *  `relatedness pipeline`_
   *  chip freeze

*  Assumptions:

   *  same as `relatedness pipeline`_

.. topic:: Debugging
   
   As with the `relatedness pipeline`_, there isn't much that can go particularly wrong here. If you find anything, do feel free
   to add it to this note block for posterity.

.. warning:: See the `relatedness pipeline`_ for warnings about graf_ idiosyncracies. There's an additional issue with 
   graf_ at this step, as it uses a mildly malformed Perl script. The conda_ installed version of graf_ from the `CGR conda channel`_
   has an installation hack that repairs one of the issues; but I think it's likely there are more corner case issues that may
   yet pop up.


.. _conda: https://docs.conda.io/en/latest/

.. _`CGR conda channel`: https://github.com/NCI-CGR/conda-cgr

.. _`cleaned chip by ancestry pipeline`:

Genotype Cleaning by Ancestry
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

The PLCO chip freeze provides five files: one for each platform (GSA, Oncoarray, OmniX, Omni25, Omni5), with each graf_ ancestry group
combined into a single plink_ bed/bim/fam dataset. These files need to be processed and cleaned with the following aims:

*  GWAS chip cleaning must take place on a per-ancestry level. This pipeline does not assume this step has been correctly handled,
   and will apply such cleaning as is minimally required for successful execution
*  Individual plink_ files by ancestry/platform are required for certain downstream processing steps
*  PCA estimation by ancestry/platform are required for certain downstream association steps
*  An intermediate of PCA and IBS/IBD estimation, LD pruned genotypes by ancestry/platform, are required for certain downstream
   processing steps

Note that some of these files and calculations, such as `heterozygosity outliers`_ and `IBS/IBD estimates`_, are not directly
used by the pipeline in its current form but were useful in the processing of the PLCO chip freeze, and are included for posterity.

.. _`heterozygosity outliers`: https://www.cog-genomics.org/plink/1.9/basic_stats#ibc

.. _`IBS/IBD estimates`: https://www.cog-genomics.org/plink/1.9/ibd

*  Usage: **make cleaned-chips-by-ancestry**
*  Dependencies:

   *  `ancestry pipeline`_
   *  chip freeze

*  Assumptions:

   *  same as `ancestry pipeline`_
   *  this was developed separately from the rest of the pipeline and folded in later. thus there exist some redundancies
      between this and other aspects of the pipeline that might be refactored out in later development. this is also one
      of the oldest of the subpipelines, so structurally it differs from some of the other pipelines. nevertheless the
      overall idea is the same: apply the same methods to each chip and ancestry in a project in a uniform and dynamic fashion
   *  for PLCO, these internal QC steps have already been applied upstream of the latest chip freeze. thus it is expected
      that the results for these platforms for heterozygosity are empty. if this is not true in later applications of the
      pipeline, some amount of restructuring may be necessary
   *  for PLCO, an entire cleaning process based on IBS/IBD pruning was applied upstream of the chip freeze. that process
      (or frankly some better version of it) should be applied to chip data before actual use in association; but no such
      method is implemented here. if there's interest, this might be the place to do it, someday during future development
      

.. topic:: Debugging
   
   This pipeline extensively uses plink_ for filtering and QC operations. plink_'s memory allocation is limited to 16G
   in **Makefile.config**. That's a completely *ad hoc* bit of nonsense that may need to be changed depending on your
   individual project's parameters.
   
   The pipeline is designed to allow different combinations of platform/ancestry to not exist. That seems to work well,
   but some issues may pop up if plink_ finds something it doesn't like in a small dataset.
   
   The IBS/IBD calculation with plink_ **--genome** is somewhat quirkly set up. For datasets above a fixed (configurable)
   threshold of number of subjects, the IBS/IBD calculation is split into chunks with **--parallel** and then glued back
   together in a separate rule. These various thresholds were selected to make PLCO/GSA/Europeans run reasonably efficiently.
   For much larger chips, you may need to fiddle with the thresholds and number of quasiparallelized jobs to make things
   go ok.
   
   PCA with smartpca_ makes use of the frankly underdocumented fastmode to make things go in a reasonable amount of time.
   This is not ideal in a variety of circumstances, most notably if you want to do PCA outlier removal. PCA in this context
   is really a blunt instrument, and not suitable for chip QC, which should have been handled earlier. So just... keep that
   in mind. For posterity, I'll record that the eigenvalues from smartpca_ fastmode are included in the header of the raw
   smartpca_ output.
   
.. _`smartpca`: https://alkesgroup.broadinstitute.org/EIGENSOFT/

.. _`bgen_pipeline`:

Imputed Data Reformatting
~~~~~~~~~~~~~~~~~~~~~~~~~

PLCO uses imputed data files from minimac4_ from the `Michigan Imputation Server`_. These files come in a standard VCF +
annotation format; the pipeline further assumes that post-imputation (Rsq-based) QC has been applied to the files, and you're
working with something like an imputed data freeze.

Association tools sometimes handle VCF format input, but often offer speed improvements when operating on other formats.
Thus, based on the tools requested during the initial "Atlas" testing phase, the format bgen_ has been selected as a common
analysis format for all tools. Imputed data files for each platform/ancestry combination are generated once per dataset,
and then used as fixed input for all association testing.

.. _minimac4: https://genome.sph.umich.edu/wiki/Minimac4

.. _`Michigan Imputation Server`: https://imputationserver.sph.umich.edu/index.html

.. _bgen: https://www.well.ox.ac.uk/~gav/bgen_format/

.. _saige: https://github.com/weizhouUMICH/SAIGE

.. _bolt-lmm: https://alkesgroup.broadinstitute.org/BOLT-LMM/BOLT-LMM_manual.html

* Usage: **make bgen**
* Dependencies:

  *  imputed data freeze
  *  list of unique subjects across platforms with corresponding platform to choose their unique instance from

* Assumptions:

  *  currently saige_ and bolt-lmm_ use bgen_ as an input format. if you're not using those tools, or another that accepts
     bgen_ input, then there's no reason to run this pipeline and waste a ton of hard drive space
  *  the bgen_ format in use here is v1.2, based on bolt-lmm_ documentation and other software support suggesting that
     that's the most efficient version accepted by all current tools. this may need to be changed in the future
  *  the bgen_ reformatting process is conducted using plink_. the resultant ***.sample** files are slightly malformatted,
     and so an additional step fixes the included **NA** values by setting them to **0**. this could well be changed in
     a future version depending on upstream behavior

.. topic:: Debugging
   
   bgen_ support in conversion tools is pretty limited. I've ended up using plink_ for VCF->BGEN conversion in two steps,
   even bearing in mind the apparent bug in output ***.sample** format files created with it. But I could very much see
   the possibility of needing a different adapter program in the future depending on one's needs and any format discrepancies
   I've not found, and it would have the benefit of potentially removing an extra rule/intermediate file from this pipeline.


.. _`1000 Genomes pipeline`:

1000 Genomes Reference Data
~~~~~~~~~~~~~~~~~~~~~~~~~~~

Certain pipelines (see below) use derived information from the `1000 Genomes Project`_. This is (always?) split
by supercontinent.

.. _`1000 Genomes Project`: https://www.internationalgenome.org

* Usage: **make 1KG_files**
* Dependencies:

  * a functional internet connection

* Assumptions:

  *  the 1000 Genomes files downloaded are frozen at a particular latest release according to the configuration information
     in **Makefile.config**. that can obviously be changed if you want
  *  most target installations should actually have some sort of copy of the 1000 Genomes data present already somewhere
     on their filesystem; however, this pipeline is not designed to support that as-is. it should be pretty easy to modify
     if you really want

.. topic:: Debugging
   
   This step in the process was the source of one of the weirdest bugs I've found during this development process.
   I don't think it should ever come up again, but do run the `1KG_files-check`

.. _`ldsc pipeline`:

LD Score/BOLT Reference Files
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

ldsc_ and bolt-lmm_ use data files derived from 1000 Genomes reference supercontinental data. Though some standard
reference data are provided in these packages (at least at time of initial download), that information only
covered European subjects, and more generalized data were/are needed.

.. _ldsc: https://github.com/bulik/ldsc

*  Usage: **make ldsc**

*  Dependencies:

   *  `1000 Genomes pipeline`_
   *  1000 Genomes supercontinental definitions (included by default)

*  Assumptions:

   *  the reference files included with bolt-lmm_ have a description of (in theory) how they were generated, but when you
      actually run ldsc_ you find that none of the output matches the included reference files exactly. this is probably
      some sort of weird versioning issue. regardless, this pipeline just hacks the result into submission. that results
      in some discrepancies from the stock reference files, but there's no indication of exactly which subjects/variants
      were used for those files, so that's not unexpected. basically: ymmv
   *  default built-in files include an African American (**AFRAMR**) meta-group for appropriate subjects. note however
      that "African American" as a human genetics group label is a very heterogeneous group, so there's no guarantee
      that this reference group will be appropriate for a given set of African American study subjects
