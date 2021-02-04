.. _`meta-analysis pipeline`:

Meta-Analysis
=============

Meta-analysis is conducted with ``metal``. The process for determining
meta-analysis targets is almost completely automated, so be careful! It
is very aggressive.

- all directories under ``$(RESULT_OUTPUT_DIR)`` are scanned for
  ``*.saige.rawids.tsv`` or ``*.boltlmm.rawids.tsv`` files, which
  are used for meta-analysis input

  - note the alphabetic case of ``saige`` and ``boltlmm`` above! that is
    actually how primary and meta-analysis files are distinguished: lowercase
    means primary, uppercase means meta. yes, this is ridiculous! feel free
    to patch in something smarter than this moving forward
  - the ``rawids.tsv`` files are primary analysis intermediate files with
    ``chr:pos:ref:alt`` IDs. these intermediates are used to maintain variant
    uniqueness within the imputed datasets: using the rsID converted files,
    even with allele tags, creates redundancies. this behavior is documented
    in :ref:`advanced developer notes`.

- meta-analysis is configured according to preset options in ``shared-makefiles/Makefile.metal``.
  please see the respective rule for creating ``.par`` files for fiddling with this behavior,
  or exposing parameters to user-space
- meta-analysis of these files requires large memory allocations; be aware of this
  when extending the pipeline to other clusters
- when meta-analysis is complete, similar postprocessing as during primary analysis
  is conducted, with the additional step of resorting variants

  - the major exception here is for categorical/ordinal analysis with SAIGE.
    the logic branches here to meta-analyze within ``comparison#/`` subdirectories,
    and then apply the *ad hoc* minimum-p-value Bonferroni correction between
    comparisons. see :ref:`primary analysis` for slightly more details lol

.. warning::

   If you extend this pipeline with other algorithms but do not respect the
   case-sensitive software name tag behavior, all downstream functionality will break.

  
