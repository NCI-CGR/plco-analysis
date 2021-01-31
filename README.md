## plco-analysis: reproducible post-imputation association studies

### Overview

This pipeline system is designed to enable reproducible post-imputation analysis,
primarily with (G)LMM software packages, as well as meta-analysis and QC plotting.
The pipelines are written in Make and interface seamlessly with computational clusters;
This software was initially designed for the "PLCO Atlas" project, with the intent
of running hundreds of association studies with as little person-power as possible,
though with little effort it can be used for more reasonably-scoped analyses in standard
GWAS. It is highly configurable and extensible, specifically regarding association tools
that can be modularly added, either with Make pipelines or tools in other languages.

### Installation Instructions

See installation instructions [here](https://plco-analysis.readthedocs.io/en/latest/Installation.html)

### Development Schedule
##### v1.0 (approximately corresponding to PLCO Atlas tranche 1 release)
- [x] BOLT-LMM support
- [x] fastGWA support
- [x] SAIGE support (binary traits)
- [x] SAIGE support (categorical traits)
- [x] meta-analysis with metal
  - [x] support for fastGWA
  - [x] support for BOLT-LMM
  - [x] support for SAIGE/binary
  - [x] support for SAIGE/categorical
- [x] rsID support request
- [x] full resumability
  - [x] resumable for cluster-submitted jobs
  - [x] resumable for non-cluster jobs
- [x] full logging
  - [x] logging for cluster-submitted jobs
  - [x] logging for non-cluster jobs
- [x] SGE/qsub support
- [x] configuration via YAML
- [x] more efficient yaml access in preprocessor
- [x] testing via yaml
- [x] heuristic testing to support above
- [x] hunt down last untracked auxiliary files
- [x] complete (straightforward and documented) platform independence with conda
- [ ] documentation: R-style vignette for generalized usage
- [x] this README

##### v2.0 (approximately corresponding with the end of PLCO Atlas)
- [ ] polmm/ordinal phenotype support
- [ ] top-level parameter exposure for analysis tools
- [ ] slurm support
- [ ] scalable testing with per-test dependency specification
- [ ] force post-primary analysis tools to ignore analysis results absent from config
- [ ] heuristic testing to support above
- [ ] documentation: full installation for multiple platforms, clusters; possibly docker
- [ ] documentation: doxygen support
- [ ] this README

##### v3.0 (the Confluence build)
- [ ] config-level parameter exposure for analysis tools
- [ ] integration of external meta-analysis files
- [ ] distributed meta-analysis best practice QC measures 
- [ ] LSF support
- [ ] heuristic testing to support above
- [ ] this README

### Version History

- 30 January 2021: remove manual dependency tracking in favor of conda and real installation instructions

- 13 January 2021: urgent patches. v1.0.0 is merely for recordkeeping for T1 run

- 12 January 2021: initial migration to CGR GitHub! v1.0.0, for tranche 1
