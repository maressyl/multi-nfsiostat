#!/usr/bin/Rscript

# CLI arguments
args <- commandArgs(TRUE)
if(length(args) == 1L) {
	inputFile <- args[1]
	outputFile <- sub("\\.txt$", ".png", inputFile)
} else if(length(args) == 2L) {
	inputFile <- args[1]
	outputFile <- args[2]
} else {
	stop("USAGE : ./nfsiostat.R nfsiostat_DATE.txt [ output.png ]")
}



# Parse nfsiostat output
content <- scan(inputFile, what="", sep="\n", quiet=TRUE)

# Trim potentially incomplete last record
content <- content[ 1 : ((length(content) %/% 8L)*8L) ]

# Split per measure (8 non-empty rows)
content <- matrix(content, nrow=8)

# Measures
read  <- do.call(rbind, strsplit(content[6,], split=" {2,}"))[,-1]
write <- do.call(rbind, strsplit(content[8,], split=" {2,}"))[,-1]
time <- strptime(content[1,], format="%Y-%m-%dT%H:%M:%S")

# Headers
colnames(read) <- strsplit(content[5,1], split=" {2,}")[[1]][-1]
colnames(write) <- strsplit(content[7,1], split=" {2,}")[[1]][-1]

png(outputFile, width=max(120+0.5*nrow(read), 400), height=1000, res=100)

# Background
layout(matrix(1:6, ncol=1))
par(mar=c(1,5,1,1), oma=c(3,0,2,0), cex=1)
for(k in colnames(read)) {
	# Cast measures as numeric
	r <- as.double(sub(" .+$", "", read[,k]))
	w <- as.double(sub(" .+$", "", write[,k]))
	
	# Plot data
	plot(x=time, y=w, ylim=range(c(r, w)), type="h", col="#FF000088", las=1, xaxt="n", xaxs="i", xlab="", ylab="", bty="n")
	points(x=time, y=r, type="h", col="#0000FF88")
	
	if(k == tail(colnames(read), 1)) {
		# Time axis
		at <- pretty(time)
		axis(side=1, at=at, labels=strftime(at, format="%H:%M:%S"))
	}
	
	if(k == head(colnames(read), 1)) {
		# Legend
		legend(x="top", inset=-0.45, lty="solid", lwd=2, col=c("#FF000088", "#0000FF88"), legend=c("write", "read"), horiz=TRUE, xpd=NA)
	}
	
	# Measure name
	text(x=par("usr")[1], y=par("usr")[4], xpd=NA, labels=sprintf(" %s", k), font=2, adj=c(0,1.5))
}

void <- dev.off()
