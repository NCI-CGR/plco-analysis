Globus Distribution
===================

The plan for transfer of data to CBIIT involves posting files to
a globus directory, to enable fast up/download for all parties.
This functionality is governed by ``shared-makefiles/Makefile.globus``,
and the enabled globus directory is ``/CGF/GWAS/Scans/PLCO/builds/1/plco-analysis/globus``.
The process is briefly overviewed below.

- Each iterative release to CBIIT is in a dated subdirectory of the ``globus``
  directory. The date is set in ``shared-makefiles/Makefile.globus`` variable
  ``$(OUTPUT_DIR)``. This has not been parametrized out, sorry.
- The ``latest`` link in the ``globus`` directory is also updated manually.
- Files are combined across analyses in different ancestries and sex-specific
  analyses of the same phenotype. This is determined as follows:

  - for ancestry, directories in ``$(RESULT_OUTPUT_DIR)/{phenotype}`` are scanned
  - for sex-specific/combined analyses, directories with the same phenotype name
    prefix in ``$(RESULT_OUTPUT_DIR)`` are scanned for variants with ``_female``
    or ``_male`` suffixes. these suffixes are configured in ``config/*config.yaml``;
    some of the ``make check`` calls scan to be sure these folders are present
    in the right combinations, but you should still be careful when configuring
    new "Atlas" analyses that you configure them completely
  - data are merged across the aforementioned analyses by variant. this is at
    the request of CBIIT. this results in large instances of blockwise missingness
    where whole regions of variants have been QCed out of some ancestries but not
    others. this is evidently a desired behavior
  - this has only been tested on ``East_Asian`` and ``European`` ancestries,
    and will need to be tested/extended when other ancestries are introduced
  - for categorical/ordinal analyses, CBIIT once requested the results of individual
    ``comparison#/`` results to be able to display individual odds ratios and p-values.
    however, once I gave them those files, they chose not to do anything with them.
    as such, that kind of subset distribution is not automated, and there was not
    a pending plan to implement that
