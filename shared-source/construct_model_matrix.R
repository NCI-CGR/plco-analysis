require(construct.model.matrix)

cargs <- commandArgs(trailingOnly = TRUE)

stopifnot(length(cargs) == 12)

phenotype.filename <- cargs[1]
chip.samplefile <- cargs[2]
ancestry <- cargs[3]
chip <- cargs[4]
phenotype.name <- cargs[5]
covariate.list.csv <- cargs[6]
output.filename <- cargs[7]
category.filename <- cargs[8]
transformation <- cargs[9]
sex.specific <- cargs[10]
control.inclusion.filename <- cargs[11]
control.exclusion.filename <- cargs[12]

construct.model.matrix::construct.model.matrix(
  phenotype.filename = phenotype.filename,
  chip.samplefile = chip.samplefile,
  ancestry = ancestry,
  chip = chip,
  phenotype.name = phenotype.name,
  covariate.list.csv = covariate.list.csv,
  output.filename = output.filename,
  category.filename = category.filename,
  transformation = transformation,
  sex.specific = sex.specific,
  control.inclusion.filename = control.inclusion.filename,
  control.exclusion.filename = control.exclusion.filename
)
