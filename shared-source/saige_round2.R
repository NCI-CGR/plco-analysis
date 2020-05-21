require(SAIGE)

cargs <- commandArgs(trailingOnly = TRUE)
bgen.filename <- cargs[1]
bgi.filename <- cargs[2]
rda.filename <- cargs[3]
varrat.filename <- cargs[4]
sparsesigma.filename <- cargs[5]
sample.filename <- cargs[6]
output.prefix <- cargs[7]
chromosome <- cargs[8]

SAIGE::SPAGMMATtest(bgenFile=bgen.filename, bgenFileIndex=bgi.filename, vcfField="DS", chrom=chromosome, minMAF=0.01, GMMATmodelFile=rda.filename, sampleFile=sample.filename, minMAC=1, varianceRatioFile=varrat.filename, SAIGEOutputFile=paste(output.prefix, ".txt", sep=""), IsOutputAFinCaseCtrl=TRUE, sparseSigmaFile=sparsesigma.filename)
