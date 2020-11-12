require(ggplot2)
require(RColorBrewer)



my.theme <- theme_light() + theme(
  plot.title = element_text(size = 18, hjust = 0.5),
  axis.title = element_text(size = 16),
  axis.text = element_text(size = 14)
)

remap.p.values <- function(input.p,
                           gc.correct) {
  y <- input.p
  if (gc.correct) {
    print(paste("gc correcting"))
    y.low <- y[y < 1e-10]
    y.hi <- y[y >= 1e-10]
    if (length(y.low) > 0) {
      y.low <- qchisq(log(y.low), 1, lower.tail = FALSE, log.p = TRUE)
    }
    if (length(y.hi) > 0) {
      y.hi <- qchisq(y.hi, 1, lower.tail = FALSE)
    }
    inflate <- median(c(y.hi, y.low)) / 0.455
    print(paste("raw inflation factor is ", inflate, sep = ""))
    if (inflate < 1) {
      print(paste("WARNING: inflation factor less than 1 detected, ",
        "setting to 1: ", inflate,
        sep = ""
      ))
      inflate <- 1
    }
    if (length(y.low) > 0) {
      y[input.p < 1e-10] <- exp(pchisq(y.low / inflate,
        1,
        lower.tail = FALSE,
        log.p = TRUE
      ))
    }
    if (length(y.hi) > 0) {
      y[input.p >= 1e-10] <- pchisq(y.hi / inflate,
        1,
        lower.tail = FALSE
      )
    }
  }
  print(paste("remapping pvalues"))
  -log10(y)
}

render.qq.plot <- function(raw.data,
                           pval.col.header,
                           qq.sim.nsims,
                           qq.sim.npoints,
                           output.filestem) {
  print(paste("calculating confidence interval for qq plot"))
  qq.sim.data <- c()
  for (i in seq_len(qq.sim.nsims)) {
    qq.sim.curdata <- sort(-log10(runif(qq.sim.npoints, 0, 1) *
      qq.sim.npoints / nrow(raw.data)))
    if (is.vector(qq.sim.data)) {
      qq.sim.data <- rbind(qq.sim.curdata)
    } else {
      qq.sim.data <- rbind(qq.sim.data, qq.sim.curdata)
    }
  }
  qq.poly.x <- sort(-log10(seq(1, qq.sim.npoints, 1) / nrow(raw.data)))
  qq.poly.x <- c(qq.poly.x, -log10(1 / nrow(raw.data)))
  qq.poly.upper.y <- c()
  qq.poly.lower.y <- c()
  for (i in seq_len(ncol(qq.sim.data))) {
    qq.poly.upper.y <- c(
      qq.poly.upper.y,
      sort(qq.sim.data[, i])[
        ceiling(qq.sim.nsims * 0.975)
      ]
    )
    qq.poly.lower.y <- c(
      qq.poly.lower.y,
      sort(qq.sim.data[, i])[
        ceiling(qq.sim.nsims * 0.025)
      ]
    )
  }
  qq.poly.upper.y <- c(qq.poly.upper.y, -log10(1 / nrow(raw.data)))
  qq.poly.lower.y <- c(qq.poly.lower.y, -log10(1 / nrow(raw.data)))
  qq.y.max <- max(c(
    y.max - 1, ceiling(max(qq.poly.upper.y)),
    ceiling(max(qq.poly.lower.y))
  ))

  ## plot the sucker
  print(paste("rendering qq plot"))
  qq.limits <- c(0, max(ceiling(-log10(1 / nrow(raw.data))), qq.y.max))
  qq.labels <- c()
  for (i in 0:qq.limits[2]) {
    qq.labels <- c(qq.labels, paste(i))
  }
  qq.data <- data.frame(
    x = sort(-log10(seq(1, nrow(raw.data), 1) / nrow(raw.data))),
    y = sort(raw.data[, pval.col.header])
  )
  qq.poly <- data.frame(
    x = c(qq.poly.x, qq.poly.x[rev(seq_along(qq.poly.x))]),
    y = c(qq.poly.lower.y, qq.poly.upper.y[rev(seq_along(qq.poly.upper.y))])
  )
  my.plot <- ggplot2::ggplot(ggplot2::aes(
    x = .data$x,
    y = .data$y
  ),
  data = qq.data
  )
  my.plot <- my.plot + my.theme + ggplot2::scale_x_continuous(
    breaks = 0:qq.limits[2],
    labels = qq.labels
  ) +
    ggplot2::scale_y_continuous(breaks = 0:qq.limits[2], labels = qq.labels)
  my.plot <- my.plot + ggplot2::geom_polygon(ggplot2::aes(
    x = .data$x,
    y = .data$y
  ),
  data = qq.poly,
  fill = "purple", alpha = 0.2
  )
  my.plot <- my.plot + ggplot2::geom_abline(slope = 1, intercept = 0)
  my.plot <- my.plot + ggplot2::geom_point()
  my.plot <- my.plot + ggplot2::xlab(expression("-log"[10] * "(Expected P)")) +
    ggplot2::ylab(expression("-log"[10] * "(Observed P)"))

  options(bitmapType = "cairo", device = "jpeg")
  ggsave(paste(output.filestem, ".qq.jpg", sep = ""),
    plot = my.plot,
    height = 10,
    width = 16 / 9 * 10,
    units = "in"
  )
}

compute.manhattan.settings <- function(raw.data,
                                       chr.col.header,
                                       pos.col.header,
                                       rsid.col.header,
                                       snp.color.one,
                                       snp.color.two,
                                       prev.loci.color,
                                       novel.loci.color,
                                       filename.prev.hits,
                                       filename.novel.hits,
                                       locus.width) {
  print(paste("setting default colors for SNPs"))
  all.colors <- rep(snp.color.one, nrow(raw.data))
  all.colors[raw.data[, chr.col.header] %% 2 == 1] <- snp.color.two
  ## start the process of labelling
  snp.labels <- c()
  snp.label.x.positions <- c()
  snp.label.y.positions <- c()
  snp.label.colors <- c()
  ## for each set of previously known loci, overwrite the color
  ##   as prev.loci.color
  if (!is.na(filename.prev.hits)) {
    prev.hits <- read.table(filename.prev.hits, header = FALSE)
    prev.hits[, 1] <- as.vector(prev.hits[, 1], mode = "character")
    prev.hits[, 2] <- as.vector(prev.hits[, 2], mode = "character")
    for (i in seq_len(prev.hits)) {
      snp <- prev.hits[i, 1]
      snp.label <- prev.hits[i, 2]
      print(paste("annotating snp ", snp, sep = ""))
      if (length(raw.data[, pos.col.header][
        raw.data[, rsid.col.header] == snp
      ]) >= 1) {
        locus.pos.center <- raw.data[, pos.col.header][
          raw.data[, rsid.col.header] == snp
        ][1]
        all.colors[abs(raw.data[, pos.col.header] -
          locus.pos.center) < locus.width] <-
          prev.loci.color
        ## handle label
        snp.labels <- c(snp.labels, snp.label)
        snp.label.x.positions <- c(
          snp.label.x.positions,
          locus.pos.center
        )
        plotmax <- max(raw.data[, pval.col.header][
          abs(raw.data[, pos.col.header] - locus.pos.center) <
            locus.width
        ])
        snp.label.y.positions <- c(
          snp.label.y.positions,
          plotmax
        )
        snp.label.colors <- c(snp.label.colors, prev.loci.color)
      }
    }
  }
  ## for each set of previously unknown loci,
  ##   overwrite the color as novel.loci.color
  if (!is.na(filename.novel.hits)) {
    novel.hits <- read.table(filename.novel.hits, header = FALSE)
    novel.hits[, 1] <- as.vector(novel.hits[, 1], mode = "character")
    novel.hits[, 2] <- as.vector(novel.hits[, 2], mode = "character")
    for (i in seq_len(nrow(novel.hits))) {
      snp <- novel.hits[i, 1]
      snp.label <- novel.hits[i, 2]
      print(paste("annotating snp ", snp, sep = ""))
      stopifnot(length(raw.data[, pos.col.header][
        raw.data[, rsid.col.header] == snp
      ]) == 1)
      locus.pos.center <- raw.data[, pos.col.header][
        raw.data[, rsid.col.header] == snp
      ]
      all.colors[abs(raw.data[, pos.col.header] -
        locus.pos.center) < locus.width] <-
        novel.loci.color
      ## handle label
      snp.labels <- c(snp.labels, snp.label)
      snp.label.x.positions <- c(
        snp.label.x.positions,
        locus.pos.center
      )
      plotmax <- max(raw.data[, pval.col.header][
        abs(raw.data[, pos.col.header] - locus.pos.center) <
          locus.width
      ])
      snp.label.y.positions <- c(
        snp.label.y.positions,
        plotmax
      )
      snp.label.colors <- c(snp.label.colors, novel.loci.color)
    }
  }
  list(
    snp.labels,
    snp.label.x.positions,
    snp.label.y.positions,
    all.colors
  )
}

render.manhattan.plot <- function(raw.data,
                                  pos.col.header,
                                  pval.col.header,
                                  all.colors,
                                  prev.loci.color,
                                  novel.loci.color,
                                  snp.color.one,
                                  snp.color.two,
                                  gws.threshold,
                                  chr.center,
                                  chr.labels,
                                  y.max,
                                  filename.prev.hits,
                                  filename.novel.hits,
                                  snp.labels,
                                  snp.label.x.positions,
                                  snp.label.y.positions,
                                  output.filestem) {
  print(paste("rendering manhattan plot"))
  manhattan.data <- data.frame(
    x = raw.data[, pos.col.header],
    y = raw.data[, pval.col.header],
    colour = all.colors,
    colour.factor = factor(ifelse(all.colors == prev.loci.color,
      "Known Locus",
      ifelse(all.colors == novel.loci.color,
        "Novel Locus",
        ifelse(all.colors == snp.color.one,
          "Null Variant 1", "Null Variant 2"
        )
      )
    ))
  )
  gg.colour.levels <- c(snp.color.one, snp.color.two)
  if (length(which(all.colors == novel.loci.color)) > 0) {
    gg.colour.levels <- c(novel.loci.color, gg.colour.levels)
  }
  if (length(which(all.colors == prev.loci.color)) > 0) {
    gg.colour.levels <- c(prev.loci.color, gg.colour.levels)
  }
  my.plot <- ggplot2::ggplot(ggplot2::aes(
    x = .data$x,
    y = .data$y,
    colour = colour.factor
  ),
  data = manhattan.data
  )
  my.plot <- my.plot + my.theme +
    ggplot2::theme(
      panel.grid = element_blank(),
      axis.text = element_text(size = 11),
      axis.line.x = element_blank(),
      axis.line.y.right = element_blank()
    )
  my.plot <- my.plot + ggplot2::geom_point()
  if (!is.na(gws.threshold)) {
    my.plot <- my.plot +
      ggplot2::geom_hline(
        yintercept = -log10(gws.threshold),
        colour = "red",
        lty = 2,
        alpha = 0.2
      )
  }
  if (length(gg.colour.levels < 3)) {
    my.plot <- my.plot +
      ggplot2::scale_colour_manual(values = gg.colour.levels, guide = FALSE)
  } else {
    legend.breaks <- c()
    if (length(which(colour.factor == "Known Locus")) > 0) {
      legend.breaks <- c(legend.breaks, "Known Locus")
    }
    if (length(which(colour.factor == "Novel Locus")) > 0) {
      legend.breaks <- c(legend.breaks, "Novel Locus")
    }
    my.plot <- my.plot + ggplot2::scale_colour_manual(
      breaks = legend.breaks,
      values = gg.colour.levels,
      name = "Locus Types"
    )
  }
  my.plot <- my.plot + ggplot2::xlab("Chromosomes") +
    ggplot2::ylab(expression("-log"[10] * "(P)"))
  my.plot <- my.plot + ggplot2::scale_x_continuous(
    breaks = chr.center,
    labels = chr.labels
  )
  my.plot <- my.plot + ggplot2::scale_y_continuous(breaks = 0:y.max)

  if (!is.na(filename.novel.hits)) {
    novel.hit.data <- data.frame(
      x = raw.data[, pos.col.header][all.colors == novel.loci.color],
      y = raw.data[, pval.col.header][all.colors == novel.loci.color]
    )
    my.plot <- my.plot + ggplot2::geom_point(ggplot2::aes(
      x = .data$x,
      y = .data$y
    ),
    data = novel.hit.data,
    colour = novel.loci.color
    )
  }
  if (!is.na(filename.prev.hits)) {
    prev.hit.data <- data.frame(
      x = raw.data[, pos.col.header][all.colors == prev.loci.color],
      y = raw.data[, pval.col.header][all.colors == prev.loci.color]
    )
    my.plot <- my.plot + ggplot2::geom_point(ggplot2::aes(
      x = .data$x,
      y = .data$y
    ),
    data = prev.hit.data,
    colour = prev.loci.color
    )
  }
  if (write.locus.labels) {
    annotate("text",
      snp.label.x.positions,
      snp.label.y.positions,
      label = snp.labels
    )
  }
  options(bitmapType = "cairo", device = "jpeg")
  ggsave(paste(output.filestem, ".manhattan.jpg", sep = ""),
    plot = my.plot, height = 10, width = 16 / 9 * 10, units = "in"
  )
}

manhattan.coded.hits <- function(filename.pvals,
                                 trait.name,
                                 filename.prev.hits = NA,
                                 filename.novel.hits = NA,
                                 output.filestem = "output",
                                 gc.correct = FALSE,
                                 write.locus.labels = TRUE,
                                 rsid.header = "SNP",
                                 pval.header = "PVAL",
                                 chr.header = "CHR",
                                 pos.header = "POS",
                                 background.snp.color.one = "darkgrey",
                                 background.snp.color.two = "lightgrey",
                                 known.locus.color = "blue",
                                 novel.locus.color = "red",
                                 gws.threshold = NA,
                                 truncate.p = NA) {
  ## input error checking
  stopifnot(is.vector(filename.pvals, mode = "character"))
  stopifnot(is.vector(trait.name, mode = "character"))
  stopifnot(is.vector(filename.prev.hits, mode = "character") |
    is.na(filename.prev.hits))
  stopifnot(is.vector(filename.novel.hits, mode = "character") |
    is.na(filename.novel.hits))
  stopifnot(is.vector(output.filestem, mode = "character"))
  stopifnot(is.logical(gc.correct))
  stopifnot(is.logical(write.locus.labels))
  stopifnot(is.vector(rsid.header, mode = "character") |
    (is.na(rsid.header) &
      is.na(filename.prev.hits) &
      is.na(filename.novel.hits)))
  stopifnot(is.vector(pval.header, mode = "character"))
  stopifnot(is.vector(chr.header, mode = "character") |
    (is.na(chr.header) &
      is.na(pos.header)))
  stopifnot(is.vector(pos.header, mode = "character") |
    (is.na(chr.header) & is.na(pos.header)))
  stopifnot(is.vector(background.snp.color.one, mode = "character"))
  stopifnot(length(colours()[colours() == background.snp.color.one]) == 1)
  stopifnot(is.vector(background.snp.color.two, mode = "character"))
  stopifnot(length(colours()[colours() == background.snp.color.two]) == 1)
  stopifnot(is.vector(known.locus.color, mode = "character"))
  stopifnot(length(colours()[colours() == known.locus.color]) == 1)
  stopifnot(is.vector(novel.locus.color, mode = "character"))
  stopifnot(length(colours()[colours() == novel.locus.color]) == 1)
  ## "global" variables
  rsid.col.header <- rsid.header
  pval.col.header <- pval.header
  chr.col.header <- chr.header
  pos.col.header <- pos.header
  pos.adjust.factor <- 100
  chr.buffer <- 8000000 / pos.adjust.factor
  snp.color.one <- background.snp.color.one
  snp.color.two <- background.snp.color.two
  locus.width <- 250000 / pos.adjust.factor
  prev.loci.color <- known.locus.color
  novel.loci.color <- novel.locus.color
  qq.sim.nsims <- 1000
  qq.sim.npoints <- 10000
  ## DO NOT CHANGE THESE GLOBALS
  qq.only <- is.na(pos.header) & is.na(chr.header)
  ## read data
  print(paste("reading file ", filename.pvals, sep = ""))
  raw.data <- read.table(filename.pvals, header = TRUE)
  ## more input error checking
  stopifnot(length(colnames(raw.data)[colnames(raw.data) ==
    rsid.col.header]) == 1 |
    (is.na(filename.prev.hits) & is.na(filename.novel.hits)))
  stopifnot(length(colnames(raw.data)[colnames(raw.data) ==
    pval.col.header]) == 1)
  stopifnot(length(colnames(raw.data)[colnames(raw.data) ==
    chr.col.header]) == 1 | qq.only)
  stopifnot(length(colnames(raw.data)[colnames(raw.data) ==
    pos.col.header]) == 1 | qq.only)
  ## reduce simulations if needed
  qq.sim.npoints <- min(qq.sim.npoints, nrow(raw.data))
  ## deal with annoying factors
  raw.data[, rsid.col.header] <- as.vector(raw.data[, rsid.col.header],
    mode = "character"
  )
  if (!is.na(truncate.p)) {
    raw.data <- raw.data[!is.na(raw.data[, pval.col.header]), ]
    raw.data[, pval.col.header][raw.data[, pval.col.header] <
      truncate.p] <- truncate.p
  }
  ## determine chromosome boundaries
  if (!qq.only) {
    print(paste("recalculating position boundaries"))
    raw.data[, pos.col.header] <- raw.data[, pos.col.header] /
      pos.adjust.factor
    min.chr <- min(raw.data[, chr.col.header])
    max.chr <- max(raw.data[, chr.col.header])
    chr.lower.bound <- c()
    chr.upper.bound <- c()
    for (i in seq(min.chr, max.chr, 1)) {
      current.chr <- raw.data[, pos.col.header][
        raw.data[, chr.col.header] == i
      ]
      if (length(current.chr) > 0) {
        ## shift every chromosome so the first SNP is at position 1
        raw.data[, pos.col.header][raw.data[, chr.col.header] == i] <-
          raw.data[, pos.col.header][
            raw.data[, chr.col.header] == i
          ] - min(current.chr) + 1
        current.chr <- raw.data[, pos.col.header][
          raw.data[, chr.col.header] == i
        ]
        chr.lower.bound <- c(chr.lower.bound, min(current.chr))
        chr.upper.bound <- c(chr.upper.bound, max(current.chr))
      } else {
        chr.lower.bound <- c(chr.lower.bound, 0)
        chr.upper.bound <- c(chr.upper.bound, 0)
      }
    }
    ## adjust positions in memory to x-axis scale
    for (i in 2:length(chr.lower.bound)) {
      raw.data[, pos.col.header][raw.data[, chr.col.header] == i] <-
        raw.data[, pos.col.header][raw.data[, chr.col.header] == i] +
        chr.upper.bound[i - 1] + chr.buffer
      chr.lower.bound[i] <- chr.lower.bound[i] + chr.upper.bound[i - 1] +
        chr.buffer
      chr.upper.bound[i] <- chr.upper.bound[i] + chr.upper.bound[i - 1] +
        chr.buffer
    }
    ## determine center of each chromosome in x-axis units
    chr.center <- (chr.lower.bound + chr.upper.bound) / 2
    ## set labels
    chr.seq <- unique(raw.data[, chr.col.header])
    chr.center <- chr.center[chr.seq]
    chr.labels <- ifelse(chr.seq == 23, "X",
      ifelse(chr.seq == 24, "Y",
        ifelse(chr.seq == 25, "XY",
          ifelse(chr.seq == 26, "M", paste(chr.seq))
        )
      )
    )
  }
  ## adjust the pvalues
  raw.data[, pval.col.header] <- remap.p.values(
    raw.data[, pval.col.header],
    gc.correct
  )

  y.max <- as.double(ceiling(max(raw.data[, pval.col.header])) + 2)



  manhattan.settings <- NULL
  snp.labels <- snp.label.x.positions <- snp.label.y.positions <- NULL
  all.colors <- NULL
  if (!qq.only) {
    manhattan.settings <- compute.manhattan.settings(
      raw.data,
      chr.col.header,
      pos.col.header,
      rsid.col.header,
      snp.color.one,
      snp.color.two,
      prev.loci.color,
      novel.loci.color,
      filename.prev.hits,
      filename.novel.hits,
      locus.width
    )
    snp.labels <- manhattan.settings@snp.labels
    snp.label.x.positions <- manhattan.settings@snp.label.x.positions
    snp.label.y.positions <- manhattan.settings@snp.label.y.positions
    all.colors <- manhattan.settings@all.colors
  }

  ## get confidence bounds for qq plot
  ## qq.sim.npoints qq.sim.nsims
  render.qq.plot(
    raw.data,
    pval.col.header,
    qq.sim.nsims,
    qq.sim.npoints,
    output.filestem
  )
  if (!qq.only) {
    render.manhattan.plot(
      raw.data,
      pos.col.header,
      pval.col.header,
      all.colors,
      prev.loci.color,
      novel.loci.color,
      snp.color.one,
      snp.color.two,
      gws.threshold,
      chr.center,
      chr.labels,
      y.max,
      filename.prev.hits,
      filename.novel.hits,
      snp.labels,
      snp.label.x.positions,
      snp.label.y.positions,
      output.filestem
    )
  }
}
