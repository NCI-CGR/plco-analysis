User Vignette
=============

I'm going to try to elaborate some use cases, so you don't have to make sense of all these things at once
to still be able to run the pipelines out of the box.

.. note::
   All ``make`` commands below are to be run at top-level in the pipeline installation directory,
   by default named ``plco-analysis``. If you attempt these commands elsewhere, you will get
   an immediate error complaining that ``/Makefile.config`` is unavailable.

A Complete Run, End to End
--------------------------

* Install the pipeline and configure your ``Makefile.config``; see
  :ref:`installation guide` and the inline comments in ``Makefile.config``
  for more instructions
* Run one-time preprocessing steps. These can be run in three chunks concurrently:

  * ``make cleaned-chips-by-ancestry`` (use conda environment ``plco-analysis``)
  * ``make bgen`` (use conda environment ``plco-analysis``)
  * ``make ldsc`` (use conda environment ``plco-analysis-ldsc``)

* Configure your analysis model(s); see :ref:`configuration guide` for more instructions.
* Launch your primary analysis tool of choice:

  * ``make boltlmm`` (use conda environment ``plco-analysis``)
  * ``make saige`` (use conda environment ``plco-analysis``)

    * note ``saige`` is really slow!

* Launch meta-analysis

  * ``make meta`` (use conda environment ``plco-analysis``)

* Concurrently run LD score regression, QC plotting

  * ``make ldscores`` (use conda environment ``plco-analysis-ldsc``)
  * ``make plotting`` (use conda environment ``plco-analysis``)

* **Check the results of ``make ldscores`` and ``make plotting`` before proceeding**

  * LD score regression results should be in ``$(RESULTS_OUTPUT_DIR)/ldscore_summary.tsv``
  * QC plots are all ``.jpg`` files under $(RESULTS_OUTPUT_DIR)
  * creates QQ and Manhattan plots for every platform/ancestry combination
  * creates QQ and Manhattan plots for every within-ancestry meta-analysis
  * creates QQ and Manhattan plots for every **meta-analysis heterogeneity distribution**

* Results are ``.tsv.gz`` output files under $(RESULTS_OUTPUT_DIR)
    
* Optional: prepare results for globus distribution

  * edit the target directory for your run in ``shared-makefiles/Makefile.globus``, variable OUTPUT_DIR

    * if you prefer, you can instead override this on the command line
      
  * ``make globus [OUTPUT_DIR=path/to/globus/RELEASE_DIR]``
