require(ggplot2)
plot.xy <- function(input.filename, plot.title, output.filestem) {
    my.plot <- ggplot(aes_string(x = colnames(h)[,1], y = colnames(h)[,2]), data = h)
    my.plot <- my.plot + theme_light() + theme(plot.title = element_text(size = 18, hjust = 0.5),
                                               axis.title = element_text(size = 16),
                                               axis.text = element_text(size = 14))
    my.plot <- my.plot + geom_abline(slope = 1, intercept = 0) + geom_point()
    my.plot <- my.plot + ggtitle(plot.title)
    options(bitmapType="cairo", device="jpeg")
    ggsave(paste(output.filestem, ".jpg", sep=""), plot=my.plot, height=10, width=16/9*10, units="in")
}
