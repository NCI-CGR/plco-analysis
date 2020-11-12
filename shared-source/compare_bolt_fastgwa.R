require(ggplot2)
require(stringr)

binnify <- function(vec.orig, bolt.p, fastgwa.p) {
  vec <- vec.orig
  vec[vec > 0.5] <- 1 - vec[vec > 0.5]
  res <- rep("", length(vec))
  res.levels <- c()
  for (i in 1:10) {
    level.name <- paste((i - 1) / 20, " <= MAF <= ", i / 20, sep = "")
    targets <- vec >= (i - 1) / 20 & vec <= i / 20
    if (i == 0) {
      level.name <- "0 < MAF <= 0.05"
      targets <- vec > 0 & vec <= 0.05
    }
    if (length(which(targets)) > 0) {
      wilcox.p <- wilcox.test(bolt.p[targets], fastgwa.p[targets],
        paired = TRUE, alt = "two.sided"
      )$p.val
      level.name <- paste(level.name, " (p[diff] = ",
        signif(wilcox.p, 3), ")",
        sep = ""
      )
      res[targets] <- level.name
      res.levels <- c(res.levels, level.name)
    }
  }
  factor(res, levels = res.levels)
}

cargs <- commandArgs(trailingOnly = TRUE)
stopifnot(length(cargs) == 1)
output.filename <- cargs[1]
output.prefix <- str_replace(output.filename, ".jpg", "")

trait.slash.anc <- str_split(
  str_split(
    output.filename,
    "results/"
  )[[1]][2],
  "/comparisons/"
)[[1]][1]
just.jpg <- str_split(
  str_split(output.filename, "results/")[[1]][2],
  "/comparisons/"
)[[1]][2]
trait <- str_split(trait.slash.anc, "/")[[1]][1]
anc <- str_split(trait.slash.anc, "/")[[1]][2]
chip <- str_split(just.jpg, "[.]")[[1]][2]


input.bolt.name <- str_replace(
  str_replace(
    output.filename,
    "comparisons/",
    "BOLTLMM/"
  ),
  ".bolt-versus-fastgwa.jpg", ".boltlmm"
)
input.fastgwa.name <- str_replace(
  str_replace(
    output.filename,
    "comparisons/",
    "FASTGWA/"
  ),
  ".bolt-versus-fastgwa.jpg", ".fastGWA"
)
if (file.exists(input.bolt.name) & file.exists(input.fastgwa.name)) {
  bolt <- read.table(input.bolt.name,
    header = TRUE,
    sep = "\t",
    stringsAsFactors = FALSE
  )
  fastgwa <- read.table(input.fastgwa.name,
    header = TRUE,
    sep = "\t",
    stringsAsFactors = FALSE
  )
  stopifnot(nrow(bolt) == nrow(fastgwa))
  stopifnot(identical(bolt$SNP, fastgwa$SNP))
  stopifnot(identical(bolt$ALLELE1, fastgwa$Tested_Allele))
  plot.data <- data.frame(
    bolt.p = bolt$P_BOLT_LMM_INF,
    fastgwa.p = fastgwa$P,
    freq.bins = binnify(bolt$A1FREQ, bolt$P_BOLT_LMM_INF, fastgwa$P)
  )
  my.plot <- ggplot(aes(
    x = -log10(bolt.p),
    y = -log10(fastgwa.p)
  ),
  data = plot.data
  )
  my.plot <- my.plot + theme_light() +
    theme(
      plot.title = element_text(size = 18, hjust = 0.5),
      axis.title = element_text(size = 16),
      axis.text = element_text(size = 14),
      strip.background = element_blank(),
      strip.text = element_text(size = 14, colour = "black")
    )
  my.plot <- my.plot + geom_point() + geom_abline(slope = 1, intercept = 0)
  my.plot <- my.plot + xlab(expression("-log"[10] * "(BOLT p-value)")) +
    ylab(expression("-log"[10] * "(FASTGWA p-value)"))
  my.plot <- my.plot +
    ggtitle(paste("Comparison Between BOLT-LMM and FASTGWA for ",
      trait, "/", chip, "/", anc,
      sep = ""
    ))
  ## save this banger for last
  my.plot.overall <- my.plot
  my.plot <- my.plot + facet_wrap(vars(freq.bins), nrow = 2, ncol = 5)
  ggsave(paste(output.prefix, ".split-by-maf.jpg", sep = ""),
    plot = my.plot, height = 10, width = 16 / 9 * 10, units = "in"
  )
  ggsave(paste(output.prefix, ".jpg", sep = ""),
    plot = my.plot.overall,
    height = 10, width = 16 / 9 * 10, units = "in"
  )
}
