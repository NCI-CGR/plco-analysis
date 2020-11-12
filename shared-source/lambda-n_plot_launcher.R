## usage: scriptname.R input-filename-with-extension
##                     plot-title-quoted output-prefix-without-extension
##                     source-directory
cargs <- commandArgs(trailingOnly = TRUE)
stopifnot(length(cargs) == 4)
input.filename <- cargs[1]
plot.title <- cargs[2]
output.prefix <- cargs[3]
source.directory <- cargs[4]
source(paste(source.directory, "plot_xy.R", sep = "/"))
h <- read.table(input.filename, header = TRUE, sep = "\t")
h <- cbind(h[, 4], log10(as.numeric(max.sample.size)))
colnames(h) <- c("lambda-GC", "log10-maxn")
plot.xy(h, plot.title, output.prefix)
