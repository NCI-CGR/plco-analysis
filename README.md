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

TODO: conda environment requirements.txt, primarily for SAIGE

Running tally of dependencies:

Required for pipeline functionality
- bash
- PyYAML
- Make >= 4.2
- gcc/g++ let's say 7+
- boost >= 1.56
- GRAF: ??
- plink: 1.9 and 2
- eigensoft/smartpca: 6.1.4

Optional depending on individual requirements:
- fastGWA:
  - fastGWA: ??
- BOLT-LMM:
  - ldsc: ??
  - BOLT-LMM: ??
- SAIGE:
  - conda: ??
  - SAIGE: ??
  - R: ??
- meta-analysis
  - metal: July 2010
- LD score regression:
  - ldsc: ??


### Development Schedule
##### v1.0 (approximately corresponding to PLCO Atlas tranche 1 release)
- [x] BOLT-LMM support
- [x] fastGWA support
- [x] SAIGE support (binary traits)
- [x] SAIGE support (categorical traits)
- [ ] meta-analysis with metal
  - [x] support for fastGWA
  - [x] support for BOLT-LMM
  - [x] support for SAIGE/binary
  - [ ] support for SAIGE/categorical
- [ ] full resumability
  - [x] resumable for cluster-submitted jobs
  - [ ] resumable for non-cluster jobs
- [ ] full logging
  - [x] logging for cluster-submitted jobs
  - [ ] logging for non-cluster jobs
- [x] SGE/qsub support
- [x] configuration via YAML
- [ ] heuristic testing to support above
- [ ] this README

##### v2.0 (approximately corresponding with the end of PLCO Atlas)
- [ ] polmm/ordinal phenotype support
- [ ] slurm support
- [ ] scalable testing with per-test dependency specification
- [ ] heuristic testing to support above

##### v3.0 (the Confluence build)
- [ ] complete (straightforward and documented) platform independence
- [ ] integration of external meta-analysis files
- [ ] distributed meta-analysis best practice QC measures
- [ ] documentation: R-style vignette for generalized usage
- [ ] heuristic testing to support above

### Version History
No locked versions exist yet!
