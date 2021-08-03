
library(yaml)
library(tidyverse)
library(data.table)

cargs <- commandArgs(trailingOnly = TRUE)

stopifnot(length(cargs) == 4)

configDir <- cargs[1]
autosomesResultsDir <- cargs[2]
xChromosoemResultsDir <- cargs[3]
outputDir <- cargs[4]

#takes the config file, finds the autosome and X GWAS summary files, concatenate them
#writes to outputDir and report sucess or fail
#sucess: - find both files and the concatenation was successful
#        - both files aren't found
combine_autosome_x <- function (config_file, ancestry, autosomesResultsDir, xChromosoemResultsDir, outputDir) {
    curr_yaml <- read_yaml(config_file)
    autosomeResultsFile <- paste0(autosomesResultsDir, "/", curr_yaml$analysis_prefix, "/", ancestry, "/", toupper(curr_yaml$algorithm),
                                      "/", curr_yaml$analysis_prefix, ".", ancestry, ".", toupper(curr_yaml$algorithm), 
                                       ".tsv.gz")
            
    xResultsFile <- paste0(xChromosoemResultsDir, "/", curr_yaml$analysis_prefix, "/", ancestry, "/", toupper(curr_yaml$algorithm),
                                      "/", curr_yaml$analysis_prefix, ".", ancestry, ".", toupper(curr_yaml$algorithm), 
                                       ".tsv.gz") 
    
    autosomeFound = file.exists(autosomeResultsFile)
    xFound = file.exists(xResultsFile)
    
    if (autosomeFound!=xFound ||  autosomeFound==FALSE ) {
        return (FALSE)
    } 
    
    message("Combining ", autosomeResultsFile, " and ", xResultsFile)
    
    
    outputFile <- paste0(outputDir, "/", curr_yaml$analysis_prefix, "/", ancestry, "/", toupper(curr_yaml$algorithm),
                                    "/", curr_yaml$analysis_prefix, ".", ancestry, ".", 
                                    toupper(curr_yaml$algorithm), ".tsv.gz") 
    outputFileDir <- dirname(outputFile) 
    dir.create(outputFileDir, recursive=TRUE)
    
    message ("writing ", outputFile, " to ", outputFileDir)
    
    autosomeResults <- fread(autosomeResultsFile)
    xResults <- fread(xResultsFile)

    xResults <- xResults %>% mutate (CHR = ifelse (CHR=="X"), 23, CHR)

    allResults <- rbind(autosomeResults, xResults)
    
    
    write.table(allResults, gzfile(outputFile), quote=F, col.names = T, row.names = F, sep="\t")
    
    return (TRUE)
    
}

config_files <- list.files(configDir, pattern = ".yaml", full.names= T )

for (config_file in config_files) {
     for (pop in c("African_American", "East_Asian", "European")) {
       combine_autosome_x (config_file, pop, autosomesResultsDir, xChromosoemResultsDir, outputDir)
     }    
}

