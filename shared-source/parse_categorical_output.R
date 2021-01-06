require(data.table)

args <- commandArgs(trailingOnly = TRUE)
stopifnot(length(args) == 2)

input.file <- args[1]
output.file <- args[2]

input.file <- data.table::fread(
  file = input.file,
  sep = "\t",
  header = TRUE,
  data.table = FALSE
)

effective.stat <- qchisq(input.file[, ncol(input.file) - 1],
  1,
  lower.tail = FALSE
)

output.data <- data.frame(
  SNP = paste(input.file[, 1], input.file[, 2], sep = ":"),
  Tested_Allele = input.file[, 4],
  Other_Allele = input.file[, 5],
  Freq_Tested_Allele_in_TOPMed = input.file[, 6],
  STAT = effective.stat,
  P = input.file[, ncol(input.file) - 1],
  N = input.file[, ncol(input.file)]
)

write.table(effective.stat,
  output.data,
  row.names = FALSE,
  col.names = TRUE,
  quote = FALSE,
  sep = "\t"
)
