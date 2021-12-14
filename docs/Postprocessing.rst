Postprocessing
==============

Downstream postprocessing, before globus distribution, comes
in two separate, optional flavors.

LD Score Regression
-------------------

LD score regression is conducted with ``ldsc``. ``$(RESULT_OUTPUT_DIR)``
is scanned for valid-looking output files, and when runs are complete,
the results are aggregated and dumped into ``$(RESULT_OUTPUT_DIR)/ldscore_summary.tsv``.

The LD score regression pipeline was recently expanded to support
individual comparison files from SAIGE for categorical/ordinal variable
analysis. This support appears to be working but has not been thoroughly
tested.

Note that due to the readiness of backend LD files, this pipeline
has only been run on European ancestry association results to date.

QC Plotting
-----------

The pipeline ``shared-makefiles/Makefile.plotting`` creates
QQ and Manhattan plots for any existing output files ``.tsv.gz``
under ``$(RESULT_OUTPUT_DIR)``. This follows the same logic
as the :ref:`meta-analysis pipeline`, in that it aggressively detects
whatever happens to be present, without going through the phenotype
model configuration files. This has the benefit of allowing some
analyses to be missing, due to sample size limitations in most
cases. However, it makes it particularly dangerous to trust
the output of this pipeline alone. Be sure the files that
are not present are ones you're ok with being absent!

Note that the Manhattan plotter pulls in "known signals"
from ``$(KNOWN_SIGNALS_INPUT_DIR)`` if available, matched
by phenotype. These were originally files generated from
either data collected by Sonja Berndt, or a database
dump from the GWAS Catalog. There was originally some hope
of automating that process, but that was never completed.
However, if you have some known signals for some traits,
feel free to dump them in there in the right format,
and the plotter will try to annotate them.

Sonja Berndt requested QC plots for heterogeneity from
metal's ``ANALYZE HETEROGENEITY`` command. Those plots
are generated for all files. Note that the heterogeneity
distribution is known to be extremely nonrandom and so
deviations *other than excessive heterogeneity* are acceptable.
