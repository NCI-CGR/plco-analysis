cargs <- commandArgs(trailingOnly=TRUE)
filename.pvals <- cargs[1]
trait.name <- cargs[2]
output.filestem <- cargs[3]
source.dir <- cargs[4]
gws.threshold <- 5e-8

source(paste(source.dir, "/manhattan_loci_colored.R", sep=""))

manhattan.coded.hits(filename.pvals, trait.name, output.filestem=output.filestem, gws.threshold=gws.threshold)
