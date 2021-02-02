.. _`configuration guide`:

Trait Configuration
===================

Overview
--------

This guide will briefly cover the configuration options available
for individual association models in this pipeline. This information
is only valid as of v2.0.0 and will likely be changed in the future.


Note that in most cases, a new analysis can be easily derived from the
model specification of a previous analysis. So please see the existing,
validated `configuration files`_ in the pipeline repository for examples
of how you might create simple association models for your traits.

.. _`configuration files`: https://github.com/NCI-CGR/plco-analysis/tree/default/config

A Quick Overview of YAML
------------------------

`YAML format`_ is a common configuration format in various applications. If you're not familiar
with it, there's a lot to know, but it'll be easiest to simply copy the format from existing
`configuration files`_. The one thing you absolutely must know: the leading whitespace in yaml
files are actually **spaces, not tabs**. If you put tabs instead, and sometimes text editors
get ambitious and do this on their own, you will get YAML compliance errors from the pipeline,
which does actually enforce YAML 1.2 compliance. If you're ever confused by format issues in yaml
files, check for tabs!

.. _`YAML format`: https://yaml.org/spec/1.2/spec.html



Mandatory Settings
------------------

* ``analysis_prefix``: a single string entry, with dashes or underscores, that will provide
  the unique folder name under ``$(RESULTS_OUTPUT_DIR)`` for this analysis model
* ``chips``: the list of **imputed datasets** that should be run in this analysis. For
  PLCO, the valid settings are: ``OmniX``; ``Omni25``; ``Oncoarray``; ``GSA_batch1``;
  ``GSA_batch2``; ``GSA_batch3``; ``GSA_batch4``; ``GSA_batch5``
* ``phenotype``: a single entry from the header of ``$(PHENOTYPE_FILENAME)``, corresponding
  to the variable that will be used as the outcome in the association model
* ``ancestries``: at least one GRAF ancestry to be analyzed. Whitespace in the default
  GRAF ancestry names should be replaced with underscores. Valid settings are: ``European``;
  ``East_Asian``; ``African_American``; ``Hispanic1``; ``Hispanic2``; ``South_Asian``; ``Other``.
* ``algorithm``: at least one software tool that should be run for this trait. This is how
  linear or logistic or polytomous regression is selected for a trait, so be sure to choose
  correctly! As of v2.0.0, supported methods are: ``boltlmm`` (continuous traits), ``fastgwa``
  (continuous traits), and ``saige`` (binary or categorical/ordinal traits)


.. note::

   Trait configuration goes through pretty extensive preprocessing with `construct.model.matrix`_
   and `initialize_output_directories`_. During that process, combinations of chips/ancestries/phenotypes
   that are invalid are automatically removed from consideration. The result is that you may
   simply specify as many chips and ancestries as you want, and combinations of those settings
   that do not meet minimum criteria (typically sample size or case count) are dropped without error.
   This makes trait configuration significantly easier for the "Atlas" than it would be otherwise;
   though please be careful to check that you see the final results that you expect to have
   available when all is said and done.

.. _`initialize_output_directories`: https://github.com/NCI-CGR/initialize_output_directories

Optional Settings
-----------------

* ``covariates``: set of entries from the header of ``$(PHENOTYPE_FILENAME)``, corresponding
  to variables to be *potentially* included in the association model. Also accepted
  are the special values ``PC#``, where ``#`` is the number of the principal component
  you want added to the model. The acceptable PC numbers are determined by ``$(SMARTPCA_N_PCS)``.
  Variables will be processed and dropped according to the preprocessing done by
  `construct.model.matrix`_. Notably, indicator variables not present in a particular
  platform/ancestry combination will automatically be dropped, so the union of all batch
  variables can be specified here. Though optional, you'll almost certainly want to at
  least specify 10 PCs here.
* ``id_mode``: one of ``chrpos`` (default) or ``rsid``. Controls the format of variant
  IDs in the final output files. ``rsid`` is requested for "Atlas" results.
* ``frequency_mode``: one of ``reference`` (default) or ``subject``. Controls the source
  of variant allele frequency data in the final output files. ``reference`` is requested
  for "Atlas" results, and is suitable for public release of association results.
* ``sex-specific``: one of ``combined`` (default), ``female``, or ``male``. Controls
  automatic restriction of analyzed subjects on all platforms to the requested subset
  of subjects. Subject sex is determined from ``$(PHENOTYPE_FILENAME)`` column ``sex``.
  Note that phenotypes that are restricted to a single sex already within ``$(PHENOTYPE_FILENAME)``
  (e.g. breast cancer, prostate cancer) should be run with this set to ``combined``.
  For postprocessing pipelines, if you want data combined across sex-specific and combined
  analyses for a trait, you should append ``_female`` or ``_male``, as appropriate,
  to the entry ``analysis_prefix``.
* ``control_inclusion``: a set of variables and levels of those variables that should be
  used for selecting valid controls for binary trait analyses. Subjects not matching
  these criteria will automatically be dropped from the association model. The intended
  purpose of this option was to specify ``clean_control: 1`` for all binary traits in
  the "Atlas". See `this binary trait configuration file`_ for an example.
* ``control_exclusion``: a set of variables and levels of those variables that should be
  used for removing invalid controls for binary trait analyses. Subjects matching
  these criteria will automatically be dropped from the association model. The intended
  purpose of this option was to specify ``bq_hyster_f_b: 1`` as an exclusion criterion
  for controls for endometrial cancer association; see `the corresponding configuration file`_
  for an example.


.. _`this binary trait configuration file`: https://github.com/NCI-CGR/plco-analysis/blob/default/config/colo_cancer.config.yaml

.. _`the corresponding configuration file`: https://github.com/NCI-CGR/plco-analysis/blob/default/config/endo_cancer.config.yaml

.. _`construct.model.matrix`: https://github.com/NCI-CGR/construct.model.matrix
