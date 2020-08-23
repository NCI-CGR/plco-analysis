cargs <- commandArgs(trailingOnly=TRUE)
filename.pvals <- cargs[1]
trait.name <- cargs[2]
output.filestem <- cargs[3]
known.signals.file <- NA
source.dir <- cargs[4]

if (length(cargs) > 4) {
    known.signals.file <- cargs[4]
    source.dir <- cargs[5]
}
gws.threshold <- 5e-8
truncate.p <- 1e-50

source(paste(source.dir, "/manhattan_loci_colored.R", sep=""))

manhattan.coded.hits(filename.pvals, trait.name, filename.prev.hits=known.signals.file, output.filestem=output.filestem, gws.threshold=gws.threshold, truncate.p=truncate.p)
