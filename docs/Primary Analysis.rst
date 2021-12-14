.. _`primary analysis`:
   
Primary Analysis
================

The pipeline currently supports BOLT-LMM analysis for continuous (normally-distributed)
traits and SAIGE for binary and categorical/ordinal traits. See :ref:`advanced developer notes`
for information about adding additional pipelines, and for the standard input/output
interface for primary analysis modules.

.. warning::

   The minimum sample sizes described below are heuristic minima that seemed to correlate
   with interpretable output during PLCO "Atlas" tranche 1. These minima are absurdly low
   compared to the sample sizes both BOLT-LMM and SAIGE were tested on. All limits
   are approximate, and you *will* see analyses fail at larger sample sizes.

BOLT-LMM
--------

- select this method with ``$(CONFIG_INPUT_DIR)/*config.yaml`` setting ``algorithm: boltlmm``

- BOLT-LMM expects traits to be continuous

  - continuous traits are inverse normal transformed with random tie resolution by ``construct.model.matrix``

- minimum sample size for BOLT-LMM defaults to 3000 per platform/ancestry group

  - this setting is controlled by ``$(BOLTLMM_MINIMUM_VALID_SUBJECT_COUNT)``
  - the relatively high minimum sample size is due to the algorithm BOLT uses for heritability estimation

SAIGE
-----

- select this method with ``$(CONFIG_INPUT_DIR)/*config.yaml`` setting ``algorithm: saige``

- SAIGE expects traits to be binary or categorical/ordinal

  - be warned: ordinal traits are treated as unordered categories

- categorical/ordinal analyses are split into N-1 binary comparisons
  and merged with a Bonferroni correction on the minimum p-value per variant

  - be warned: the Bonferroni on min-p operation is anticonservatively biased

- minimum sample size for SAIGE defaults to 1000 per platform/ancestry group

  - this setting is controlled by ``$(SAIGE_MINIMUM_VALID_SUBJECT_COUNT)``

- SAIGE additionally has a minimum case count of 30 by default

  - this setting is controlled by ``$(MINIMUM_VALID_CASE_COUNT)``
