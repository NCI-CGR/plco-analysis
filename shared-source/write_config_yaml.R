library(optparse)
library(tidyverse)
library(yaml)

option_list = list(
  make_option(c("-y", "--yaml"), type="character", default=NULL, 
              help="yaml file name", metavar="character"),
  make_option(c("-o", "--outDir"), type="character", default=NULL, 
              help="output files dictory", metavar="character"),
  make_option(c("-i", "--input"), type="character", default=NULL, 
              help="input excel file", metavar="character"),
  make_option(c("-s", "--sheet"), type="character", default=NULL, 
              help="input excel file sheet name", metavar="character")
); 

opt_parser = OptionParser(option_list=option_list);
opt = parse_args(opt_parser)

if (is.null(opt$yaml) | is.null(opt$outDir) | is.null(opt$input) | is.null(opt$sheet)){
  print_help(opt_parser)
  stop("See help above", call.=FALSE)
}

#write yaml function
write_default_yaml <- function (yaml, phenotype, ancestries, algorithm, sex_specific, misc_options, outdir) {
  
  yaml$phenotype <- phenotype 
  yaml$ancestries <- ancestries
  yaml$algorithm <- tolower(algorithm)
  
  if (grep("clean_control", tolower(misc_options))) {
    yaml$control_inclusion$clean_control = "1" 
  }
  
  
  if (sex_specific == "Y" | sex_specific == "M") {
    yaml_male <- yaml
    yaml_male$analysis_prefix = paste0(phenotype, "_male")
    yaml_male$`sex-specific` = "male"
    write_yaml(yaml_male, paste0(outdir, "/", yaml_male$phenotype, ".male.config.yaml"))
    print (paste0(outdir, "/", yaml$phenotype, ".male.config.yaml"))
  }
  
  if (sex_specific == "Y" | sex_specific == "F") {
    yaml_female <- yaml
    yaml_female$analysis_prefix = paste0(phenotype, "_female")
    yaml_female$`sex-specific` = "female"
    write_yaml(yaml_female, paste0(outdir, "/", yaml_female$phenotype, ".female.config.yaml"))
    print (paste0(outdir, "/", yaml$phenotype, ".female.config.yaml"))
  }
  
  if (sex_specific == "Y") {
    write_yaml(yaml, paste0(outdir, "/", yaml$phenotype, ".config.yaml"))
    print (paste0(outdir, "/", yaml$phenotype, ".config.yaml"))
  }
  
}

ancestries <- c("European", "East_Asian", "African_American")


for (i in 1:nrow(input_targets)) {
  write_default_yaml (base_config, input_targets$`Trait variable name`[i], ancestries,
                      input_targets$`Analysis tool`[i], input_targets$`Sex-specific analysis?`[i],
                      input_targets$`Collaborator to guide covariate selection for modeling?`[i],
                      opt$outdir)
}


write_default_yaml <- function (yaml, phenotype, ancestries, algorithm, sex_specific, misc_options, outdir) {
  
  yaml$phenotype <- phenotype 
  yaml$ancestries <- ancestries
  yaml$algorithm <- tolower(algorithm)
  
  if (grep("clean_control", tolower(misc_options))) {
    yaml$control_inclusion$clean_control = "1" 
  }
  
  
  if (sex_specific == "Y" | sex_specific == "M") {
    yaml_male <- yaml
    yaml_male$analysis_prefix = paste0(phenotype, "_male")
    yaml_male$`sex-specific` = "male"
    write_yaml(yaml_male, paste0(outdir, "/", yaml_male$phenotype, ".male.config.yaml"))
    print (paste0(outdir, "/", yaml$phenotype, ".male.config.yaml"))
  }
  
  if (sex_specific == "Y" | sex_specific == "F") {
    yaml_female <- yaml
    yaml_female$analysis_prefix = paste0(phenotype, "_female")
    yaml_female$`sex-specific` = "female"
    write_yaml(yaml_female, paste0(outdir, "/", yaml_female$phenotype, ".female.config.yaml"))
    print (paste0(outdir, "/", yaml$phenotype, ".female.config.yaml"))
  }
  
  if (sex_specific == "Y") {
    write_yaml(yaml, paste0(outdir, "/", yaml$phenotype, ".config.yaml"))
    print (paste0(outdir, "/", yaml$phenotype, ".config.yaml"))
  }
  
}