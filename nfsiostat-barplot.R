#!/usr/bin/Rscript

### USAGE : ./nfsiostat-barplot.R [ DATE ]

source("fun/collect.R")
out <- collect()
tab <- out$tab
day <- out$day

# All servers
servers <- sort(unique(tab$server))

# Round times to avoid second shifts
tab$time <- round(tab$tim, "mins")

# Reshape as array
times <- seq(from=min(tab$time), to=max(tab$time), by="min")
columns <- c("read - kB/s", "write - kB/s", "read - avg exe (ms)", "write - avg exe (ms)")
arr <- array(
	as.double(NA),
	dim = c(length(times), length(servers), length(columns)),
	dimnames = list(NULL, servers, columns)
)

# Store FIXME
for(column in columns) {
	i <- cbind(
		match(as.character(tab$time), as.character(times)),
		match(tab$server, servers),
		match(column, columns)
	)
	f <- !apply(is.na(i), 1, any)
	arr[ i[f,] ] <- as.double(tab[f,column])
}


# Palette (only for non-idle servers)
i <- apply(arr, 2, sum, na.rm=TRUE) > 0L
pal <- rep("white", length(servers))
pal[i] <- rainbow(sum(i))

png(sprintf("plots/nfsiostat-barplot_%s.png", day), width=2000, height=1000, res=100)

# Layout
par(mar=c(2,7,1,1))
layout(matrix(c(1:4,5,5,5,5), ncol=2), widths=c(7,1))

for(column in columns) {
	# Matrix to plot
	mtx <- as.matrix(t(arr[,,column]))
	mtx[ is.na(mtx) ] <- 0L
	
	# Time "axis" (hours)
	i <- strftime(times, "%M") == "00"
	names.arg <- rep(NA, ncol(mtx))
	names.arg[i] <- strftime(times[i], "%H:%M")
	
	# Plot
	barplot(mtx/1000, border=NA, col=pal, names.arg=names.arg, las=1)
	
	# Title
	mtext(side=2, text=sub("ms", "s", sub("kB", "MB", column)), font=2, line=5)
}

# Legend background
par(mar=c(0,0,0,0), cex=1)
plot(x=NA, y=NA, xlim=0:1, ylim=0:1, xlab="", ylab="", xaxt="n", yaxt="n", bty="n")
legend(
	x=0.5, y=0.5, xjust=0.5, yjust=0.5,
	fill = pal,
	legend = rownames(mtx)
)

void <- dev.off()
