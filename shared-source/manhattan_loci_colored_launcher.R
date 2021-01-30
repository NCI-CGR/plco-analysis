require(gwasqcplots)

cargs <- commandArgs(trailingOnly = TRUE)

## yes, this is a total hackjob

## input data filename plus path
filename.pvals <- cargs[1]
## name of phenotype for plotting
trait.name <- cargs[2]
## prefix including path of all output plots
output.filestem <- cargs[3]
## top-level directory of cleaned-chips-by-ancestry pipeline
cleaned.chip.dir <- cargs[4]
## top-level directory of ancestry pipeline plus "/" or file prefix ("PLCO_")
ancestry.prefix <- cargs[5]
## column name of subject IDs in phenotype file ("plco_id")
phenotype.id.colname <- cargs[6]
## chips in study, comma-delimited
supported.chips <- unlist(strsplit(cargs[7], ","))
## optional file of variants with known associations, for plotting
known.signals.file <- NA

if (length(cargs) > 7) {
  known.signals.file <- cargs[8]
}

## assorted presets for plotting, maybe expose them in the future?
gws.threshold <- 5e-8
truncate.p <- 1e-50

## run the plotter
manhattan.coded.hits(filename.pvals, trait.name,
  filename.prev.hits = known.signals.file,
  output.filestem = output.filestem,
  gws.threshold = gws.threshold,
  truncate.p = truncate.p,
  cleaned.chip.dir = cleaned.chip.dir,
  ancestry.prefix = ancestry.prefix,
  phenotype.id.colname = phenotype.id.colname,
  supported.chips = supported.chips
)
