#!/usr/bin/Rscript

### USAGE : ./nfsiostat-barplot.R [ DATE ]

# CLI arguments
args <- commandArgs(TRUE)
if(length(args) == 1L) {
	day <- args[1]
} else {
	day <- strftime(Sys.time(), "%Y-%m-%d")
}

tmp <- read.csv("../hosts.csv", stringsAsFactors=FALSE)
hosts <- tmp[[2]]
names(hosts) <- tmp[[1]]

tab <- NULL
inputFiles <- dir("../pull", pattern=sprintf("%s_.*\\.txt$", day), full.names=TRUE)
for(inputFile in inputFiles) {
	# Server IP
	server <- sub("^.+_([0-9\\.]+)\\.txt$", "\\1", basename(inputFile))
	message(inputFile)
	
	# Parse nfsiostat output
	content <- scan(inputFile, what="", sep="\n", quiet=TRUE)
	
	# Consider only full frames
	frameStarts <- grep("^20[0-9]{2}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}\\+[0-9]{2}:00$", content, perl=TRUE)
	validFrame <- grepl("^read:", content[frameStarts + 4L]) & grepl("%\\)", content[frameStarts + 5L]) & grepl("^write:", content[frameStarts + 6L]) & grepl("%\\)", content[frameStarts + 7L])
	frameStarts <- frameStarts[validFrame]
	
	if(length(frameStarts) > 0L) {
		# Measures
		read  <- do.call(rbind, strsplit(content[ frameStarts + 5L ], split=" {2,}"))[,-1]
		write <- do.call(rbind, strsplit(content[ frameStarts + 7L ], split=" {2,}"))[,-1]
		time <- strptime(content[ frameStarts ], format="%Y-%m-%dT%H:%M:%S")
		
		# Headers
		colnames(read) <- sprintf("read - %s", strsplit(content[ frameStarts[1] + 4L ], split=" {2,}")[[1]][-1])
		colnames(write) <- sprintf("write - %s", strsplit(content[ frameStarts[1] + 6L ], split=" {2,}")[[1]][-1])
		
		# Aggregate
		tab <- rbind(
			tab,
			data.frame(
				server = server,
				time = time,
				read,
				write,
				check.names = FALSE,
				stringsAsFactors=FALSE
			)
		)
	}
}

# Round times to avoid second shifts
tab$time <- round(tab$tim, "mins")

# Reshape as array
times <- seq(from=min(tab$time), to=max(tab$time), by="min")
columns <- c("read - kB/s", "write - kB/s", "read - avg exe (ms)", "write - avg exe (ms)")
arr <- array(
	as.double(NA),
	dim = c(length(times), length(hosts), length(columns)),
	dimnames = list(NULL, names(hosts), columns)
)

# Store FIXME
for(column in columns) {
	i <- cbind(
		match(as.character(tab$time), as.character(times)),
		match(tab$server, names(hosts)),
		match(column, columns)
	)
	f <- !apply(is.na(i), 1, any)
	arr[ i[f,] ] <- as.double(tab[f,column])
}


# Palette (only for non-idle servers)
i <- apply(arr, 2, sum, na.rm=TRUE) > 0L
pal <- rep("white", length(hosts))
pal[i] <- rainbow(sum(i))

png(sprintf("nfsiostat-barplot_%s.png", day), width=2000, height=1000, res=100)

# Layout
par(mar=c(2,7,1,1))
layout(matrix(c(1:4,5,5,5,5), ncol=2), widths=c(7,1))

for(column in columns) {
	# Matrix to plot
	mtx <- as.matrix(t(arr[,,column]))
	mtx[ is.na(mtx) ] <- 0L
	rownames(mtx) <- hosts[ rownames(mtx) ]
	
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
