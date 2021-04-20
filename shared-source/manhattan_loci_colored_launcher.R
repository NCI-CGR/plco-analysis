require(gwasqcplots)

cargs <- commandArgs(trailingOnly = TRUE)

## yes, this is a total hackjob

## input data filename plus path
filename.pvals <- cargs[1]
## name of phenotype for plotting
trait.name <- cargs[2]
## prefix including path of all output plots
output.filestem <- cargs[3]
## optional file of variants with known associations, for plotting
known.signals.file <- NA

if (length(cargs) > 3) {
  known.signals.file <- cargs[4]
}

## assorted presets for plotting, maybe expose them in the future?
gws.threshold <- 5e-8
truncate.p <- 1e-50

## run the plotter
make.qq.manhattan(filename.pvals, trait.name,
  filename.prev.hits = known.signals.file,
  output.filestem = output.filestem,
  gws.threshold = gws.threshold,
  truncate.p = truncate.p
)
