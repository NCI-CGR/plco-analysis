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
- bash >= 4.1.2
- PyYAML >= 3.12
- Make >= 4.2
- gcc/g++ let's say >= 7 but like, what are you doing with your life
- boost >= 1.71
- GRAF: >= 2.3.1
- plink: 1.9 and 2
- eigensoft/smartpca: = 6.1.4

Optional depending on individual requirements:
- fastGWA:
  - fastGWA: >= gcta_1.93.1beta
- BOLT-LMM:
  - ldsc: >= 02.01.20
  - BOLT-LMM: >= v2.3.4
- SAIGE:
  - conda: ??
  - SAIGE: >= 0.36.3.1
  - R: >= 3.6.1
- meta-analysis
  - metal: July 2010
- LD score regression:
  - ldsc: >= 02.01.20


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
  - [ ] support for SAIGE/categorical (#1)
- [ ] full resumability
  - [x] resumable for cluster-submitted jobs
  - [ ] resumable for non-cluster jobs (#9)
- [ ] full logging
  - [x] logging for cluster-submitted jobs
  - [ ] logging for non-cluster jobs (#9)
- [x] SGE/qsub support
- [x] configuration via YAML
- [ ] testing via yaml (#13)
- [ ] heuristic testing to support above (#4 #5 #6)
- [ ] documentation: barebones installation instructions, conda for saige (#2)
- [ ] this README (#3)

##### v2.0 (approximately corresponding with the end of PLCO Atlas)
- [ ] polmm/ordinal phenotype support (#14)
- [ ] top-level parameter exposure for analysis tools (#22)
- [ ] slurm support (#7)
- [ ] scalable testing with per-test dependency specification (#17)
- [ ] force post-primary analysis tools to ignore analysis results absent from config (#10)
- [ ] heuristic testing to support above
- [ ] documentation: full installation for multiple platforms, clusters; possibly docker
- [ ] this README (#3)

##### v3.0 (the Confluence build)
- [ ] complete (straightforward and documented) platform independence (#16)
- [ ] config-level parameter exposure for analysis tools (#23)
- [ ] integration of external meta-analysis files (#11)
- [ ] distributed meta-analysis best practice QC measures (#12)
- [ ] LSF support (#8)
- [ ] documentation: R-style vignette for generalized usage (#15)
- [ ] heuristic testing to support above
- [ ] this README (#3)

### Version History
No locked versions exist yet!
