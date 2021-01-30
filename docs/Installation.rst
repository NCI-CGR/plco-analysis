Installation
============

Overview
~~~~~~~~

This document will cover the installation process for this pipeline.
Note that this in particular is a work in progress that will be finalized
by 05 February 2021, but until then should be considered incomplete
and not necessarily suitable for use.

The pipeline is configured for installation with conda_. Other installation
methods are possible but not supported.

.. _conda: https://docs.conda.io/en/latest/

Short Version (for experts)
~~~~~~~~~~~~~~~~~~~~~~~~~~~

*  Install or activate conda_
*  If needed, install git
*  Clone the `analysis pipeline repository`_
*  Navigate into the repository directory
*  Create the conda_ environment specified by **environment.yaml**
*  Activate the environment (make sure to do this whenever launching runs)
*  Update **Makefile.config** to point to your copies of the following:

   *  PLCO chip freeze
   *  PLCO imputed data freeze
   *  PLCO phenotype data

*  You are now ready to start running the pipeline, good luck!

.. _`analysis pipeline repository`: https://github.com/NCI-CGR/conda-cgr

Long Version (for interested parties)
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

TODO
