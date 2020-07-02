require(ggplot2)
require(RColorBrewer)



my.theme <- theme_light() + theme(plot.title = element_text(size = 18, hjust = 0.5),
                                                                  axis.title = element_text(size = 16),
                                                                  axis.text = element_text(size = 14))

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
	#input error checking	
	stopifnot(is.vector(filename.pvals, mode="character"))
	stopifnot(is.vector(trait.name, mode="character"))
	stopifnot(is.vector(filename.prev.hits, mode="character") | is.na(filename.prev.hits))
	stopifnot(is.vector(filename.novel.hits, mode="character") | is.na(filename.novel.hits))
	stopifnot(is.vector(output.filestem, mode="character"))
	stopifnot(is.logical(gc.correct))
	stopifnot(is.logical(write.locus.labels))
	stopifnot(is.vector(rsid.header, mode="character") | (is.na(rsid.header) & is.na(filename.prev.hits) & is.na(filename.novel.hits)))
	stopifnot(is.vector(pval.header, mode="character"))
	stopifnot(is.vector(chr.header, mode="character") | (is.na(chr.header) & is.na(pos.header)))
	stopifnot(is.vector(pos.header, mode="character") | (is.na(chr.header) & is.na(pos.header)))
	stopifnot(is.vector(background.snp.color.one, mode="character"))
	stopifnot(length(colours()[colours() == background.snp.color.one]) == 1)
	stopifnot(is.vector(background.snp.color.two, mode="character"))
	stopifnot(length(colours()[colours() == background.snp.color.two]) == 1)
	stopifnot(is.vector(known.locus.color, mode="character"))
	stopifnot(length(colours()[colours() == known.locus.color]) == 1)
	stopifnot(is.vector(novel.locus.color, mode="character"))
	stopifnot(length(colours()[colours() == novel.locus.color]) == 1)
	#"global" variables
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
	my.cex.text <- 0.9
	my.cex.points <- 0.5
	my.cex.legend.points <- 1.25 * my.cex.points
	my.cex.axis <- 0.9
	qq.sim.nsims <- 1000
	qq.sim.npoints <- 10000
	qq.conf.color <- "darkgrey"
	#DO NOT CHANGE THESE GLOBALS
	qq.only <- is.na(pos.header) & is.na(chr.header)
	#read data
	print(paste("reading file ", filename.pvals, sep=""))
	raw.data <- read.table(filename.pvals, header=TRUE)
	#more input error checking
	stopifnot(length(colnames(raw.data)[colnames(raw.data) == rsid.col.header]) == 1 | (is.na(filename.prev.hits) & is.na(filename.novel.hits)))
	stopifnot(length(colnames(raw.data)[colnames(raw.data) == pval.col.header]) == 1)
	stopifnot(length(colnames(raw.data)[colnames(raw.data) == chr.col.header]) == 1 | qq.only)
	stopifnot(length(colnames(raw.data)[colnames(raw.data) == pos.col.header]) == 1 | qq.only)
	#reduce simulations if needed
	qq.sim.npoints <- min(qq.sim.npoints, nrow(raw.data))
	#deal with annoying factors
	raw.data[,rsid.col.header] <- as.vector(raw.data[,rsid.col.header], mode="character")
	if (!is.na(truncate.p)) {
		raw.data <- raw.data[!is.na(raw.data[,pval.col.header]),]
		raw.data[,pval.col.header][raw.data[,pval.col.header] < truncate.p] <- truncate.p
	}
	#determine chromosome boundaries
	if (!qq.only) {
		print(paste("recalculating position boundaries"))
		raw.data[,pos.col.header] <- raw.data[,pos.col.header] / pos.adjust.factor
		min.chr <- min(raw.data[,chr.col.header])
		max.chr <- max(raw.data[,chr.col.header])
		chr.lower.bound <- c()
		chr.upper.bound <- c()
		for (i in seq(min.chr, max.chr, 1)) {
			current.chr <- raw.data[,pos.col.header][raw.data[,chr.col.header] == i]
			if (length(current.chr) > 0) {
				#shift every chromosome so the first SNP is at position 1
				raw.data[,pos.col.header][raw.data[,chr.col.header] == i] <- raw.data[,pos.col.header][raw.data[,chr.col.header] == i] - min(current.chr) + 1
				current.chr <- raw.data[,pos.col.header][raw.data[,chr.col.header] == i]
				chr.lower.bound <- c(chr.lower.bound, min(current.chr))
				chr.upper.bound <- c(chr.upper.bound, max(current.chr))
			} else {
				chr.lower.bound <- c(chr.lower.bound, 0)
				chr.upper.bound <- c(chr.upper.bound, 0)
			}
		}
		#adjust positions in memory to x-axis scale
		for (i in 2:length(chr.lower.bound)) {
			raw.data[,pos.col.header][raw.data[,chr.col.header] == i] <- raw.data[,pos.col.header][raw.data[,chr.col.header] == i] + chr.upper.bound[i-1] + chr.buffer
			chr.lower.bound[i] <- chr.lower.bound[i] + chr.upper.bound[i-1] + chr.buffer
			chr.upper.bound[i] <- chr.upper.bound[i] + chr.upper.bound[i-1] + chr.buffer
		}
		#determine center of each chromosome in x-axis units
		chr.center <- (chr.lower.bound + chr.upper.bound) / 2
		#set labels
		##chr.seq <- seq(min.chr, max.chr, 1)
		chr.seq <- unique(raw.data[,chr.col.header])
		chr.center <- chr.center[chr.seq]
		chr.labels <- ifelse(chr.seq == 23, "X", ifelse(chr.seq == 24, "Y", ifelse(chr.seq == 25, "XY", ifelse(chr.seq == 26, "M", paste(chr.seq)))))
	
	}
	#adjust the pvalues
	if (gc.correct) {
		print(paste("gc correcting"))
		y <- raw.data[,pval.col.header]
		y_low <- y[y<1e-10]
                y_hi <- y[y>=1e-10]
                if (length(y_low) > 0) {
                        y_low <- qchisq(log(y_low), 1, lower.tail=FALSE, log.p=TRUE)
                }
                if (length(y_hi) > 0) {
                        y_hi <- qchisq(y_hi, 1, lower.tail=FALSE)
                }
                inflate <- median(c(y_hi, y_low))/0.455
                print_inflate <- inflate
                print(paste("raw inflation factor is ", inflate, sep=""))
                if (inflate < 1) {
                        print(paste("WARNING: inflation factor less than 1 detected, setting to 1: ",inflate, sep=""))
                        inflate <- 1
                }
                if (length(y_low) > 0) {
			raw.data[,pval.col.header][raw.data[,pval.col.header] < 1e-10] <- 
				exp(pchisq(qchisq(log(raw.data[,pval.col.header][raw.data[,pval.col.header] < 1e-10]), 1, lower.tail=FALSE, log.p=TRUE)/inflate, 
					   1, lower.tail=FALSE, log.p=TRUE))
                }
                if (length(y_hi) > 0) {
			raw.data[,pval.col.header][raw.data[,pval.col.header] >= 1e-10] <- 
				pchisq(qchisq(raw.data[,pval.col.header][raw.data[,pval.col.header] >= 1e-10], 1, lower.tail=FALSE)/inflate,
				       1, lower.tail=FALSE)
                }
	}
	print(paste("remapping pvalues"))
	raw.data[,pval.col.header] <- -log10(raw.data[,pval.col.header])
	y_max <- as.double(ceiling(max(raw.data[,pval.col.header]))+2)




	#set SNP colors (manhattan only)
	if (!qq.only) {
		print(paste("setting default colors for SNPs"))
		all.colors <- rep(snp.color.one, nrow(raw.data))
		all.colors[raw.data[,chr.col.header] %% 2 == 1] <- snp.color.two
		#start the process of labelling
		snp.labels <- c()
		snp.label.x.positions <- c()
		snp.label.y.positions <- c()
		snp.label.colors <- c()
		#for each set of previously known loci, overwrite the color as prev.loci.color
		if (!is.na(filename.prev.hits)) {
			prev.hits <- read.table(filename.prev.hits, header=FALSE)
			prev.hits[,1] <- as.vector(prev.hits[,1], mode="character")
			prev.hits[,2] <- as.vector(prev.hits[,2], mode="character")
			for (i in 1:nrow(prev.hits)) {
				snp <- prev.hits[i,1]
				snp.label <- prev.hits[i,2]
				print(paste("annotating snp ", snp, sep=""))
				stopifnot(length(raw.data[,pos.col.header][raw.data[,rsid.col.header] == snp]) == 1)
				locus.pos.center <- raw.data[,pos.col.header][raw.data[,rsid.col.header] == snp]
				all.colors[abs(raw.data[,pos.col.header] - locus.pos.center) < locus.width] <- prev.loci.color
				#handle label
				snp.labels <- c(snp.labels, snp.label)
				snp.label.x.positions <- c(snp.label.x.positions, locus.pos.center)
				snp.label.y.positions <- c(snp.label.y.positions, max(raw.data[,pval.col.header][abs(raw.data[,pos.col.header] - locus.pos.center) < locus.width]))
				snp.label.colors <- c(snp.label.colors, prev.loci.color)
			}
		}
		#for each set of previously known loci, overwrite the color as known.loci.color
		if (!is.na(filename.novel.hits)) {
			novel.hits <- read.table(filename.novel.hits, header=FALSE)
			novel.hits[,1] <- as.vector(novel.hits[,1], mode="character")
			novel.hits[,2] <- as.vector(novel.hits[,2], mode="character")
			for (i in 1:nrow(novel.hits)) {
				snp <- novel.hits[i,1]
				snp.label <- novel.hits[i,2]
				print(paste("annotating snp ", snp, sep=""))
				stopifnot(length(raw.data[,pos.col.header][raw.data[,rsid.col.header] == snp]) == 1)
				locus.pos.center <- raw.data[,pos.col.header][raw.data[,rsid.col.header] == snp]
				all.colors[abs(raw.data[,pos.col.header] - locus.pos.center) < locus.width] <- novel.loci.color
				#handle label
				snp.labels <- c(snp.labels, snp.label)
				snp.label.x.positions <- c(snp.label.x.positions, locus.pos.center)
				snp.label.y.positions <- c(snp.label.y.positions, max(raw.data[,pval.col.header][abs(raw.data[,pos.col.header] - locus.pos.center) < locus.width]))
				snp.label.colors <- c(snp.label.colors, novel.loci.color)
			}
		}
	}

	#get confidence bounds for qq plot
	#qq.sim.npoints qq.sim.nsims
	print(paste("calculating confidence interval for qq plot"))
	qq.sim.data <- c()
	for (i in 1:qq.sim.nsims) {
		qq.sim.curdata <- sort(-log10(runif(qq.sim.npoints, 0, 1) * qq.sim.npoints / nrow(raw.data)))
		if (is.vector(qq.sim.data)) qq.sim.data <- rbind(qq.sim.curdata)
		else qq.sim.data <- rbind(qq.sim.data, qq.sim.curdata)
	}
	qq.poly.x <- sort(-log10(seq(1, qq.sim.npoints, 1)/nrow(raw.data)))
	qq.poly.x <- c(qq.poly.x, -log10(1/nrow(raw.data)))
	qq.poly.upper.y <- c()
	qq.poly.lower.y <- c()
	for (i in 1:ncol(qq.sim.data)) {
		qq.poly.upper.y <- c(qq.poly.upper.y, sort(qq.sim.data[,i])[ceiling(qq.sim.nsims * 0.975)])
		qq.poly.lower.y <- c(qq.poly.lower.y, sort(qq.sim.data[,i])[ceiling(qq.sim.nsims * 0.025)])
	}
	qq.poly.upper.y <- c(qq.poly.upper.y, -log10(1/nrow(raw.data)))
	qq.poly.lower.y <- c(qq.poly.lower.y, -log10(1/nrow(raw.data)))
	qq.y.max <- max(c(y_max - 1, ceiling(max(qq.poly.upper.y)), ceiling(max(qq.poly.lower.y))))

	#plot the sucker
	print(paste("rendering qq plot"))
	##jpeg(paste(output.filestem, ".qq.jpg", sep=""), width=5, height=5, res=1000, units="in", pointsize=8)
	qq.limits <- c(0, max(ceiling(-log10(1/nrow(raw.data))), qq.y.max))
	qq.labels <- c()
	for (i in 0:qq.limits[2]) {
		qq.labels <- c(qq.labels, paste(i))
	}
	qq.data <- data.frame(x = sort(-log10(seq(1, nrow(raw.data), 1)/nrow(raw.data))),
						  y = sort(raw.data[,pval.col.header]))
	qq.poly <- data.frame(x = c(qq.poly.x, qq.poly.x[length(qq.poly.x):1]),
						  y = c(qq.poly.lower.y, qq.poly.upper.y[length(qq.poly.upper.y):1]))
	my.plot <- ggplot(aes(x = x, y = y), data = qq.data)
	my.plot <- my.plot + my.theme + scale_x_continuous(breaks = 0:qq.limits[2], labels = qq.labels) + scale_y_continuous(breaks = 0:qq.limits[2], labels = qq.labels)
	my.plot <- my.plot + geom_polygon(aes(x = x, y = y), data = qq.poly, fill="purple", alpha=0.2)
	my.plot <- my.plot + geom_abline(slope = 1, intercept = 0)
	my.plot <- my.plot + geom_point()
	my.plot <- my.plot + xlab(expression("-log"[10]*"(Expected P)")) + ylab(expression("-log"[10]*"(Observed P)"))

	#plot(0, min(raw.data[,pval.col.header]), xlab=expression("-log"[10]*"(Expected P)"), ylab=expression("-log"[10]*"(Observed P)"),
	#     pch=20, cex=my.cex.points, cex.lab=my.cex.text, pin=c(5,5), xlim=qq.limits, ylim=qq.limits, frame.plot=FALSE)
	#axis(side=1, at=0:qq.limits[2], labels=qq.labels, cex.axis=my.cex.axis)
	#axis(side=2, at=0:qq.limits[2], labels=qq.labels, cex.axis=my.cex.axis)
	#polygon(qq.poly.x, qq.poly.lower.y, col=qq.conf.color, border=NA)
	#polygon(qq.poly.x, qq.poly.upper.y, col=qq.conf.color, border=NA)
	#abline(0,1)
	#points(sort(-log10(seq(1, nrow(raw.data), 1)/nrow(raw.data))), sort(raw.data[,pval.col.header]), pch=20, cex=my.cex.points)
	#dev.off()
	#dev.new(width=10, height=6)
	options(bitmapType="cairo", device="jpeg")
	ggsave(paste(output.filestem, ".qq.jpg", sep=""), plot = my.plot, height=10, width=16/9*10, units="in")
	if (!qq.only) {
		print(paste("rendering manhattan plot"))
		##jpeg(paste(output.filestem, ".manhattan.jpg", sep=""), width=9, height=5, res=1000, units="in", pointsize=8)
		manhattan.data <- data.frame(x = raw.data[,pos.col.header],
									 y = raw.data[,pval.col.header],
									 colour = all.colors,
									 colour.factor = factor(ifelse(all.colors == prev.loci.color, "Known Locus", 
															ifelse(all.colors == novel.loci.color, "Novel Locus", 
															ifelse(all.colors == snp.color.one, "Null Variant 1", "Null Variant 2")))))
		gg.colour.levels <- c(snp.color.one, snp.color.two)
		if (length(which(all.colors == novel.loci.color)) > 0) {
			gg.colour.levels <- c(novel.loci.color, gg.colour.levels)
		}
		if (length(which(all.colors == prev.loci.color)) > 0) {
			gg.colour.levels <- c(prev.loci.color, gg.colour.levels)
		}
		my.plot <- ggplot(aes(x = x, y = y, colour = colour.factor), data = manhattan.data)
		my.plot <- my.plot + my.theme + theme(panel.grid = element_blank(),
											  axis.text = element_text(size = 11),
											  axis.line.x = element_blank(),
											  axis.line.y.right = element_blank())
		my.plot <- my.plot + geom_point()
		if (!is.na(gws.threshold)) {
			my.plot <- my.plot + geom_hline(yintercept = -log10(gws.threshold), colour = "red", lty = 2, alpha = 0.2)
		}
		if (length(gg.colour.levels < 3)) {
			my.plot <- my.plot + scale_colour_manual(values = gg.colour.levels, guide=FALSE)
		} else {
			legend.breaks <- c()
			if (length(which(colour.factor == "Known Locus")) > 0) {
				legend.breaks <- c(legend.breaks, "Known Locus")
			}
			if (length(which(colour.factor == "Novel Locus")) > 0) {
				legend.breaks <- c(legend.breaks, "Novel Locus")
			}
			my.plot <- my.plot + scale_colour_manual(breaks = legend.breaks, values = gg.colour.levels, name = "Locus Types")
		}
		my.plot <- my.plot + xlab("Chromosomes") + ylab(expression("-log"[10]*"(P)"))
		my.plot <- my.plot + scale_x_continuous(breaks = chr.center, labels = chr.labels)
		my.plot <- my.plot + scale_y_continuous(breaks = 0:y_max)
		#plot(raw.data[,pos.col.header], raw.data[,pval.col.header], col=all.colors, xlab="Chromosomes", ylab=expression("-log"[10]*"(P)"), 
		#     xaxt="n", yaxt="n", pch=20, ylim=c(0,y_max), cex=my.cex.points, cex.lab=my.cex.text, pin=c(9,5), frame.plot=FALSE)
		#axis(side=1, at=chr.center, labels=chr.labels, cex.axis=my.cex.axis, lwd=0, lwd.ticks=1)
		#axis(side=2, las=0, at=0:y_max, cex.axis=my.cex.axis)
		if (!is.na(filename.novel.hits)) {
			#points(raw.data[,pos.col.header][all.colors==novel.loci.color],
			#       raw.data[,pval.col.header][all.colors==novel.loci.color],
			#       pch=20, cex=my.cex.points, col=novel.loci.color)
			novel.hit.data <- data.frame(x = raw.data[,pos.col.header][all.colors == novel.loci.color],
										 y = raw.data[,pval.col.header][all.colors == novel.loci.color])
			my.plot <- my.plot + geom_point(aes(x = x, y = y), data = novel.hit.data, colour = novel.loci.color)
		}
		if (!is.na(filename.prev.hits)) {
			#points(raw.data[,pos.col.header][all.colors==prev.loci.color],
			#       raw.data[,pval.col.header][all.colors==prev.loci.color],
			#       pch=20, cex=my.cex.points, col=prev.loci.color)
			prev.hit.data <- data.frame(x = raw.data[,pos.col.header][all.colors == prev.loci.color],
										y = raw.data[,pval.col.header][all.colors == prev.loci.color])
			my.plot <- my.plot + geom_point(aes(x = x, y = y), data = prev.hit.data, colour = prev.loci.color)
		}
		if (FALSE) {
		if (!is.na(filename.prev.hits) | !is.na(filename.novel.hits)) {
			legend.labels <- c()
			legend.colors <- c()
			if (!is.na(filename.prev.hits)) {
				legend.labels <- c(legend.labels, paste("Previous", trait.name, "loci", sep=" "))
				legend.colors <- c(legend.colors, prev.loci.color)
			}
			if (!is.na(filename.novel.hits)) {
				legend.labels <- c(legend.labels, paste("Novel", trait.name, "loci", sep=" "))
				legend.colors <- c(legend.colors, novel.loci.color)
			}
			legend("topright", legend=legend.labels, cex=my.cex.text, pt.cex=my.cex.legend.points, col=legend.colors, pch=rep(20,2), bty="n")
		}
		}
		if (write.locus.labels) {
			annotate("text", snp.label.x.positions, snp.label.y.positions, label = snp.labels)
			#text(snp.label.x.positions, snp.label.y.positions, snp.labels, pos=3, offset=1.25, cex=my.cex.text, col=snp.label.colors)
		}
		options(bitmapType="cairo", device="jpeg")
		ggsave(paste(output.filestem, ".manhattan.jpg", sep=""), plot = my.plot, height=10, width=16/9*10, units="in")
		#dev.off()
	}
}
