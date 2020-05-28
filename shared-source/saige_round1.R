require(SAIGE)
cargs <- commandArgs(trailingOnly = TRUE)
stopifnot(length(cargs) == 6)
plink.prefix <- cargs[1]
model.matrix <- cargs[2]
phenotype <- cargs[3]
covariates <- cargs[4]
relatedness.cutoff <- as.numeric(cargs[5])
output.prefix <- cargs[6]

covar.col.list <- NULL
if (covariates != "NA") {
   covar.col.list <- unlist(strsplit(covariates, ","))
}

SAIGE::fitNULLGLMM(plink.prefix, model.matrix, phenotype, sampleIDColinphenoFile="IID", covarColList=covar.col.list, nThreads=4, traitType="binary", outputPrefix=output.prefix, IsSparseKin=TRUE, relatednessCutoff=relatedness.cutoff)
