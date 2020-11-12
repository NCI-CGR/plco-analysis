require(POLMM)
cargs <- commandArgs(trailingOnly = TRUE)
stopifnot(length(cargs) == 5)
plink.prefix <- cargs[1]
model.matrix <- cargs[2]
phenotype <- cargs[3]
covariates <- cargs[4]
output.rds <- cargs[5]

covar.col.list <- "1"
if (covariates != "NA") {
  covar.col.list <- unlist(strsplit(covariates, ","))
}
model.data <- read.table(model.matrix, header = TRUE)
model.formula <- formula(paste(
  phenotype,
  " ~ ",
  paste(covar.col.list, collapse = " + ")
),
sep = ""
)
x <- POLMM::POLMM_Null_Model(model.formula,
  model.data,
  plink.prefix,
  subjData = model.data$IID,
  subjPlink = read.table(paste(plink.prefix,
    ".fam",
    sep = ""
  ),
  header = FALSE
  )[, 2],
  control = list(
    onlyCheckTime = TRUE,
    numThreads = 4
  )
)
saveRDS(x, output.rds)
