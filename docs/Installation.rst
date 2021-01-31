Installation
============

Overview
--------

This document will cover the installation process for this pipeline.
Note that this in particular is a work in progress that will be finalized
by 05 February 2021, but until then should be considered incomplete
and not necessarily suitable for use.

The pipeline is configured for installation with conda_. Other installation
methods are possible but not supported.

.. _conda: https://docs.conda.io/en/latest/

Short Version (for experts)
---------------------------

*  Install or activate conda_
*  If needed, install git and git-lfs, and activate git-lfs
*  Clone the `analysis pipeline repository`_
*  Navigate into the repository directory
*  Add the `CGR conda channel`_ to your **.condarc**
*  Create the conda_ environments specified by **environment.yaml** and **environment-ldsc.yaml**
*  Activate the environments (ldsc for ``ldsc`` and ``ldscores`` pipeline; the other for everything else)
*  Update **Makefile.config** to point to your copies of the following:

   *  PLCO chip freeze
   *  PLCO imputed data freeze
   *  PLCO phenotype data

*  You are now ready to start running the pipeline, good luck!

.. _`analysis pipeline repository`: https://github.com/NCI-CGR/plco-analysis
.. _`CGR conda channel`: https://raw.githubusercontent.com/NCI-CGR/conda-cgr/default/conda-cgr

Long Version (for interested parties)
-------------------------------------

Environment Management with `conda`_
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

`conda`_ is a package management system used for installing software packages across different systems.
This is how the run environments for this pipeline are maintained. There are two environments in use:
one for most applications and with a copy of python3, and one for the limited set of tools (currently only
`ldsc`_) that require end-of-life python2.

.. _`ldsc`: https://github.com/bulik/ldsc

If you have not used `conda`_ before, you will need to install it for your user account. You can follow
`these conda installation instructions`_ for more detailed information. Be sure to add the channels they
list under "2. Set up channels"

.. _`these conda installation instructions`: https://bioconda.github.io/

.. warning::
   Default miniconda installation will recommend that you place your miniconda installation in ``~/miniconda3``.
   This is your home directory. Many systems, including ``cgems/ccad`` and ``biowulf``, have severe memory limits
   on home directories, which you will very promply fill if you place your miniconda installation there. Instead,
   when it prompts you for that installation patch, choose a directory in a space where you have a higher memory
   limit.

Check your ``~/.condarc``; add the channels ``r`` and ``https://raw.githubusercontent.com/NCI-CGR/conda-cgr/default/conda-cgr``
to the top of your list of channels if they are not already present.

.. warning::
   At the end of this step, your ``~/.condarc`` should contain, in its **channels** block, the following entries in order:

   * ``https://raw.githubusercontent.com/NCI-CGR/conda-cgr/default/conda-cgr``
   * ``r``
   * ``bioconda``
   * ``conda-forge``
   * ``defaults``

   If it does not do so, the environment resolution below will almost certainly fail.

Getting a Copy of the Pipeline
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
Before getting the pipeline, we need command line tools to appropriately download it, and we'll use conda for that.
Install required software packages into your base environment (or a development environment if you prefer):

.. code-block:: bash

   conda install mamba git git-lfs

.. note::
   If you already have ``git`` and ``git-lfs`` available on your system, installing them here is unnecessary. ``mamba``,
   however, is pretty essential on most systems.

Then activate your base environment (or proceed with your development environment if that's the path you're taking):

.. code-block:: bash

   conda activate base

If you have never used ``git-lfs`` before, activate it one time only:

.. code-block:: bash

   git lfs install

Now, navigate somewhere on your system where you want to install a copy of the pipeline. Then clone a copy of the pipeline repository
(due to large reference files, this clone operation may take up to 30 seconds on some systems):

.. code-block:: bash

   git clone https://github.com/NCI-CGR/plco-analysis

.. warning::

   If you do not have ``git-lfs`` installed correctly, this clone operation will fail with messages regarding ``lfs`` not operating
   correctly.

.. warning::

   At the time of first writing of this pipeline, the large reference backend files for this pipeline are stored on GitHub, due
   to a lack of publicly-exposed alternatives. If sufficiently many people download these files in a short span of time, GitHub
   prevents further use of ``lfs`` managed files for the calendar month, since CGR is evidently using a free GitHub account.
   Among other possible solutions, the bandwidth limit is evidently refreshed monthly, so if you hit the cap, you can just wait.
   But also, please don't try to clone multiple copies of this pipeline; once you have a copy, you can make other copies on a local
   system with **cp -R**.

Now, navigate into the pipeline directory:

.. code-block:: bash

   cd plco-analysis

Build conda Environments
~~~~~~~~~~~~~~~~~~~~~~~~

Create the two `conda`_ environments used by the pipeline using the environment specification files included in the pipeline repository:

.. code-block:: bash

   mamba env create -f environment.yaml
   mamba env create -f environment-ldsc.yaml

.. note::

   The environment specified by ``environment.yaml`` will be named ``plco-analysis`` by default. This is a python3 environment and
   has many dependencies; depending on your system and the state of your environment cache (if you don't know what that is, don't worry
   about it), this can take tens of minutes to complete.

   The environment specified by ``environment-ldsc.yaml`` will be named ``plco-analysis-ldsc`` by default. This is a python2 environment,
   and is very small, governing exclusively the operation of the LD score regression software `ldsc`_. As python2 has reached end of life,
   this environment should never be expanded unless absolutely necessary, and ideally should be removed when `ldsc`_ achieves python3
   compatibility (lol).

.. warning::
   `conda`_ environments can be finicky. The ``plco-analysis`` pipeline in particular is somewhat delicate. It works (as of 30 January 2021).
   However, the way `conda`_ is structured, it may well break at a future date. I will record here some thoughts on debugging the environment
   if you end up getting errors from ``mamba env create``.

   * See the above discussion of `conda`_ channels. They all need to be present. It's possible having extra channels not listed may create issues,
     so if you happen to have more, try temporarily removing them and see if that fixes it. Also note that the *order* of channels matters in
     resolving conflicting versions of the same package between channels.
   * If you get errors about an environment already existing, it's possible you have an environment named ``plco-analysis`` or ``plco-analysis-ldsc``
     already present in your miniconda installation. That's bad lol. You can check your existing environments with ``conda info --envs`` (or
     simply list the contents of the directory ``/path/to/miniconda3/envs``). If indeed there is an existing environment, perhaps you've already
     done this process before? Otherwise, you can override the name of the environment you're creating now by instead using
     ``mamba env create -f environment.yaml -n different_name`` or by changing the entry in ``environment.yaml``.
   * If you're getting truly bizarre errors (conflicting paths in packages, missing package files, etc.), it's possible your cache has become
     corrupted. Don't even ask me how this happens. It can (I have seen it) create inscrutable errors that simply vanish when you clean up the cache.
     A traditional method for doing this is just deleting and reinstalling `conda`_ entirely; that's certainly a time-honored approach. But it's
     more aggressive than you may need. You can instead try running ``conda clean --all``, or simply recursively deleting the contents of
     ``/path/to/miniconda3/pkgs``.
   * I'll note here that specific errors regarding ``boost-cpp=1.70`` are more troublesome. The packages ``bolt-lmm``, ``r-saige``, and some
     not-yet-tracked-down dependencies of ``r-saige`` were built specifically against ``boost-cpp=1.70`` and block newer versions. I've thus
     built the ``plco-analysis`` internal packages `annotate_frequency`_, `combine_categorical_runs`_, `initialize_output_directories`_,
     `merge_files_for_globus`_, and `qsub_job_monitor`_ against ``boost-cpp=1.70`` as well. If this breaks in the future, or if/when ``boost-cpp=1.70``
     leaves ``conda``, there's going to be trouble. My apologies to Future Person who has to deal with this nonsense.

.. _`annotate_frequency`: https://github.com/NCI-CGR/annotate_frequency
.. _`combine_categorical_runs`: https://github.com/NCI-CGR/combine_categorical_runs
.. _`initialize_output_directories`: https://github.com/NCI-CGR/initialize_output_directories
.. _`merge_files_for_globus`: https://github.com/NCI-CGR/merge_files_for_glbus
.. _`qsub_job_monitor`: https://github.com/NCI-CGR/qsub_job_monitor

     
Environment Usage
~~~~~~~~~~~~~~~~~

I've said it above and I'll say it again here so that when this inevitably causes problems, you'll hopefully see it somewhere:

* activate ``plco-analysis-ldsc`` when you are running the **ldsc** pipeline in ``ldsc/Makefile`` with ``make ldsc``; or when
  you are running the **ldscore regression** pipeline in ``shared-makefiles/Makefiles.ldscores`` with ``make ldscores``:

  ``conda activate plco-analysis-ldsc``

* activate ``plco-analysis`` for **all other pipelines**:

  ``conda activate plco-analysis``



Updating Project Configuration
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

At the time of this writing, project-wide configuration (primarily location of genotypes and phenotypes)
is controlled by variables in the file ``plco-analysis/Makefile.config``. The extent to which you need
to update variables in this file depends on where you're trying to install your copy of the pipeline,
and what directory permissions you have. Some defaults for ``cgems/ccad`` are present by default. Note that
the variables have defaults and commented explanations in-file, so you should read those for more details or examples.

You will likely need to change the following:

* ``PROJECT_BASE_DIR``: installation path of your pipeline, including the directory ``plco-analysis``.
* ``CHIP_FREEZE_INPUT_DIR``: path to your PLCO chip freeze files. By default it expects ``PLCO_GSA.{bed,bim,fam}``,
  and equivalent files for OmniX, Omni25, Omni5, and Oncoarray.
* ``EXTERNAL_FILE_INPUT_DIR``: this is a site for future development pulling in external metadata files; for the moment,
  it is merely the presumed location of the cross-platform subject deduplication file, by default named
  ``PLCO_final_subject_list_Ancestry_UniqGenotypePlatform_04132020.txt``
* ``FILTERED_IMPUTED_INPUT_DIR``: path to your PLCO imputation freeze files. This folder should contain post-Rsq-QC,
  non-redundant subjects files in `minimac4`_ format. For DUPS requests, the relevant folder is typically named
  something like ``Non_redundant_PLCO/Imputed/Post_Imputation_QCed/latest``
* ``PHENOTYPE_FILENAME``: path to and name of phenotype file for the study. The format is described briefly
  in ``Makefile.config``: plain-text, tab-delimited, single header row. Note that the ``Atlas`` analysis configuration
  files expect augmented covariate columns describing certain possible batch effects as binary indicator variables.
  This functionality can be disabled by removing the relevant rows from the configuration files ``plco-analysis/config/*config.yaml``

.. _`minimac4`: https://genome.sph.umich.edu/wiki/Minimac4
