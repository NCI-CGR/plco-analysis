require(stringr)
cargs <- commandArgs(trailingOnly = TRUE)
if (length(cargs) != 7) {
   stop(paste("Arguments to construct_model_matrix.R: phenotype_filename chip_samplefile ancestry chip phenotype_name covariate_list output_filename (expected 7, received ", length(cargs), sep=""))
}
phenotype.filename <- cargs[1]
chip.samplefile <- cargs[2]
ancestry <- cargs[3]
chip <- cargs[4]
chip.nosubsets <- strsplit(chip, "_")[[1]][1]
phenotype.name <- cargs[5]
covariate.list <- unlist(strsplit(cargs[6], ","))
covariate.list <- unique(covariate.list[covariate.list != "NA"])
output.filename <- cargs[7]

id.colname <- "plco_id"

possible.pcs <- paste("PC", 1:10, sep="")

## try to read phenotype data
h <- read.table(phenotype.filename, header=TRUE, sep="\t")
if (length(unique(colnames(h))) != length(colnames(h))) {
   stop(paste("duplicate column names detected in phenotype file \"", phenotype.filename, "\"", sep=""))
}
## enforce IDs present once
if (length(which(colnames(h) == id.colname)) != 1) {
   stop(paste("header of phenotype data does not contain exactly one ", id.colname, " column", sep=""))
}
## enforce phenotype present once
if (length(which(colnames(h) == phenotype.name)) != 1) {
   stop(paste("header of phenotype data does not contain requested phenotype \"", phenotype.name, "\" exactly once", sep=""))
}
## enforce requested covariates
if (length(covariate.list) > 0) {
   if (length(which(covariate.list %in% c(colnames(h), possible.pcs))) != length(covariate.list)) {
      stop(paste("some requested covariates not present in phenotype dataset: ", which(!(covariate.list %in% colnames(h))), sep=""))
   }
}


## apply inverse normalization to continuous variables
inverse.normalize <- function(i) {
## from SAIGE code https://github.com/weizhouUMICH/SAIGE/blob/master/R/SAIGE_fitGLMM_fast.R
	qnorm((rank(i, na.last="keep") - 0.5)/sum(!is.na(i)))
}

## try to hack diagnose phenotype distribution for mild consistency checking
unique.outcomes <- unique(h[,phenotype.name][!is.na(h[,phenotype.name])])
trait.is.binary <- length(unique.outcomes) == 2 & length(c(0,1) %in% unique.outcomes) == 2

## apply sex-stratified inverse normal transform when: covariate is continuous and not age covariate, or when analysis is FASTGWA or BOLT on the specified non-binary trait
for (col.index in which((grepl("_co$", colnames(h)) & !grepl("_age_", colnames(h))) | (grepl("bolt|fastgwa", output.filename, ignore.case=TRUE) & !trait.is.binary & colnames(h) == phenotype.name))) {
    for (i in 1:2) {
    	h[,col.index][h$sex == i] <- inverse.normalize(h[,col.index][h$sex == i])
    }
}

# load PCs for ANC/CHIP combo
pc.filename <- paste("/CGF/GWAS/Scans/PLCO/builds/1/cleaned-chips-by-ancestry/", ancestry, "/", chip.nosubsets, ".step7.evec", sep="")
pc.data <- data.frame()
if (file.exists(pc.filename)) {
   pc.data <- read.table(pc.filename, header=FALSE, skip=1, stringsAsFactors=FALSE)
   rownames(pc.data) <- pc.data[,1]
   pc.data[,1] <- NULL
   colnames(pc.data) <- c(possible.pcs, "smartpca.condition")
} else {
   warning(paste("components do not exist for ancestry/chip combination ", ancestry, " ", chip.nosubsets, ", due to inadequate sample size", sep=""))
}

## add component data if requested and do it messily and without plyr
for (pc in possible.pcs[possible.pcs %in% covariate.list]) {
    if (nrow(pc.data) == 0) {
       h <- transform(h, tmp = rep(NA, nrow(h)))
    } else {
       h <- h[h[,id.colname] %in% rownames(pc.data),]
       h <- h[order(h[,id.colname]),]
       pc.data <- pc.data[rownames(pc.data) %in% h[,id.colname],]
       pc.data <- pc.data[order(rownames(pc.data)),]
       h <- transform(h, tmp = pc.data[,pc])
    }
    colnames(h)[ncol(h)] <- pc
}

all.chips <- c("GSA", "Omni25", "Omni5", "OmniX", "Oncoarray")

## partition data down to requested chip/ancestry. This is a bit extra, but allows preflight sample size checking
ancestry.combined <- data.frame()
for (chip in all.chips) {
    ancestry.data <- read.table(paste("/CGF/GWAS/Scans/PLCO/builds/1/ancestry/PLCO_", chip, ".graf_estimates.txt", sep=""), header=TRUE, sep="\t", stringsAsFactors=FALSE)
    ancestry.combined <- rbind(ancestry.combined, ancestry.data)
}
ancestry.combined <- ancestry.combined[,c(1, ncol(ancestry.combined))]
ancestry.combined[,2] <- str_replace_all(ancestry.combined[,2], " ", "_")
ancestry.combined <- ancestry.combined[ancestry.combined[,2] == ancestry,]
h <- h[h[,id.colname] %in% ancestry.combined[,1],]

chip.samples <- read.table(chip.samplefile, header=FALSE, stringsAsFactors=FALSE)
chip.samples[,1] <- unlist(lapply(strsplit(chip.samples[,1], "_"), function(i) {i[1]}))
h <- h[h[,id.colname] %in% chip.samples[,1],]

output.df <- h[,c(rep(id.colname, 2), phenotype.name, covariate.list)]

## subset to complete cases, which are all that are used by SAIGE
output.df <- output.df[complete.cases(output.df),]

## identify non-binary categoricals and turn them into dummies
## wow this part is a pain
MINIMUM.FACTOR.LEVEL.COUNT <- 10
## flag things that need dummification
for (cat.var in colnames(output.df)[grepl("ca$", colnames(output.df)) | colnames(output.df) %in% c("center", "sex", "is.other.asian", paste("batch", c("GSA", "Oncoarray", "OmniX", "Omni25"), sep="."))]) {
    ## create n-1 dummies
    ## reorder the base factor so the most populous group is the reference
    output.df[,cat.var] <- factor(as.vector(output.df[,cat.var], mode="character"))
    counts <- summary(output.df[,cat.var])
    output.df[,cat.var] <- factor(output.df[,cat.var], levels=names(counts[order(counts, decreasing=TRUE)]))
    if (length(unique(output.df[,cat.var])) == 1) {
       output.df[,cat.var] <- NULL
       next
    }
    other.name <- paste(cat.var, "ref", levels(output.df[,cat.var])[1], "combined.other", sep=".")
    other.group <- rep(0, nrow(output.df))
    if (length(levels(output.df[,cat.var])) > 1) {
       for (fac.level in levels(output.df[,cat.var])) {
       	   ## skip the reference level
       	   if (fac.level == levels(output.df[,cat.var])[1]) next
	   cat.name <- paste(cat.var, "ref", levels(output.df[,cat.var])[1], fac.level, sep=".")
	   cat.values <- rep(0, nrow(output.df))
	   cat.values[output.df[,cat.var] == fac.level] <- 1
	   if (sum(cat.values) < MINIMUM.FACTOR.LEVEL.COUNT) {
	      other.group <- other.group + cat.values
	      next
	   }
	   output.df <- transform(output.df, tmp = cat.values)
	   colnames(output.df)[ncol(output.df)] <- cat.name
       }
       output.df[,cat.var] <- NULL
    }
    if (sum(other.group) > 0) {
       output.df <- transform(output.df, tmp = other.group)
       colnames(output.df)[ncol(output.df)] <- other.name
    }
}

## finally maybe report results
colnames(output.df)[1:2] <- c("FID", "IID")
output.df <- output.df[,(grepl(paste("batch", chip.nosubsets, sep="."), colnames(output.df)) | !grepl("batch.", colnames(output.df)))]
write.table(output.df, output.filename, row.names=FALSE, col.names=TRUE, quote=FALSE, sep="\t")
