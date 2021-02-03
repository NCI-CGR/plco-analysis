User Vignette
=============

I'm going to try to elaborate some use cases, so you don't have to make sense of all these things at once
to still be able to run the pipelines out of the box.

.. note::
   All ``make`` commands below are to be run at top-level in the pipeline installation directory,
   by default named ``plco-analysis``. If you attempt these commands elsewhere, you will get
   an immediate error complaining that ``/Makefile.config`` is unavailable.

.. note::
   Unless otherwise noted, all commands below should be run with the default ``plco-analysis``
   ``conda`` environment active.

A Complete Run, End to End
--------------------------

* Install the pipeline and configure your ``Makefile.config``; see
  :ref:`installation guide` and the inline comments in ``Makefile.config``
  for more instructions
* Run one-time preprocessing steps. These can be run in three chunks concurrently:

  * ``make cleaned-chips-by-ancestry``
  * ``make bgen``
  * ``make ldsc`` (use conda environment ``plco-analysis-ldsc``)

* Configure your analysis model(s); see :ref:`configuration guide` for more instructions.
* Launch your primary analysis tool of choice:

  * ``make boltlmm``
  * ``make saige``

    * note ``saige`` is really slow!

* Launch meta-analysis

  * ``make meta``

* Concurrently run LD score regression, QC plotting

  * ``make ldscores`` (use conda environment ``plco-analysis-ldsc``)
  * ``make plotting``

* **Check the results of "make ldscores" and "make plotting" before proceeding**

  * LD score regression results should be in ``$(RESULTS_OUTPUT_DIR)/ldscore_summary.tsv``
  * QC plots are all ``.jpg`` files under $(RESULTS_OUTPUT_DIR)
  * creates QQ and Manhattan plots for every platform/ancestry combination
  * creates QQ and Manhattan plots for every within-ancestry meta-analysis
  * creates QQ and Manhattan plots for every **meta-analysis heterogeneity distribution**

* Results are ``.tsv.gz`` output files under ``$(RESULTS_OUTPUT_DIR)``
    
* Optional: prepare results for globus distribution

  * edit the target directory for your run in ``shared-makefiles/Makefile.globus``, variable ``$(OUTPUT_DIR)``

    * if you prefer, you can instead override this on the command line
      
  * ``make globus [OUTPUT_DIR=path/to/globus/RELEASE_DIR]``



Run a Subset of Analyses Only
-----------------------------

The pipeline detects what primary analyses should be run by checking which rule is run (``make boltlmm``, ``make saige``),
extracting the models specified in ``$(CONFIG_INPUT_DIR)/*config.yaml`` that have an ``algorithm`` entry matching the rule,
and then pruning out combinations of platform/ancestry that have insufficiently many subjects for that software.
The pipeline will check *all* valid configurations fitting those criteria. So if you just want to run one thing only,
but you have a bunch of other valid configuration files sitting around, you need to get creative.

We will assume for this vignette that you've already run any necessary preprocessing steps; if not, do that first!

* Make a new config directory, somewhere. Let's call it ``config_new``

* Optional: make a new results directory; if you don't do this and other analyses are present in ``$(RESULT_OUTPUT_DIR)``,
  they will be considered by the meta-analysis pipeline for updating; whether or not this is acceptable depends.

* Run your favorite primary analysis, updating the config (and optionally results) directories: ``make boltlmm CONFIG_INPUT_DIR=/path/to/config_new [RESULT_OUTPUT_DIR=/path/to/results_new``

* Run meta-analysis, ldscore regression, and QC plotting as usual, overriding ``$(RESULT_OUTPUT_DIR)`` if needed: ``make meta [RESULT_OUTPUT_DIR=/path/to/results_new]``, etc.

* If desired, run globus packaging: ``make globus CONFIG_INPUT_DIR=/path/to/config_new [RESULT_OUTPUT_DIR=/path/to/results_new]``



Run Your Own Boutique Traits
----------------------------

Let's imagine you're an enterprising champion of analysis and think: wow, these basic traits are super boring,
but I've got 14 custom, delicate, gorgeous traits I've custom-built in SAS and I want to run them against
all the imputed data in this pipeline.

* Format your phenotypes like the default phenotypes in ``$(PHENOTYPE_FILENAME)``: plaintext, tab-delimited, a subject ID column named ``$(PHENOTYPE_ID_COLNAME)``

* Create a configuration file (in ``$(CONFIG_INPUT_DIR)``, which as usual you can override if you like) that has as its ``phenotype`` entry the column name you've made for yourself

* Add other model parameters. Note that, except for principal components, **the pipeline can only see variables in your new phenotype file**. So if you want covariates,
  you need to add them to your custom phenotype file too

* Launch the relevant pipeline, as indicated in the ``algorithm`` section of your configuration file: ``make saige PHENOTYPE_FILENAME=/path/to/your_file.tsv``

* After that, you should be able to run all remaining pipelines as usual; you can continue to override ``$(PHENOTYPE_FILENAME)`` if you like, but it won't have any impact either way

