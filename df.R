#!/usr/bin/Rscript

tab <- NULL
files <- dir("store", pattern="^[0-9-]+\\.txt$", full.names=TRUE)
for(file in files) {
	
	message(file)
	
	day <- sub("\\.txt", "", basename(file))
	
	# Filter out badly formated lines
	tmp <- scan(file, what="", sep="\n", quiet=TRUE)
	tmp <- grep("^[0-9\\+:]+ +[a-z\\.-]+:/ +[0-9]+ +[0-9]+ +[0-9]+ +[0-9]+% +[a-z\\./-]+$", tmp, value=TRUE)
	
	# Parse
	tmp <- read.table(textConnection(tmp), stringsAsFactors=FALSE, col.names=c("time", "filesystem", "blocks.1K", "used", "available", "used.%", "mountpoint"), check.names=FALSE)
	tmp$time <- strptime(paste(day, tmp$time, sep="T"), format="%Y-%m-%dT%H:%M:%S")
	tab <- rbind(tab, tmp)
}

png("plots/df.png", width=1600, height=800, res=100)

# Plot
plot(x=tab$time, y=tab$available/(1024^3), type="l", cex=0.5, xlab="", ylab="\"Available\" according to df (Tio)", las=2, xaxt="n", main="Free space")

# Time axis
at <- seq(from=round(min(tab$time), "day"), to=round(max(tab$time), "day"), by="day")
axis(side=1, at=at, labels=strftime(at, "%a %d/%m"), las=2)

void <- dev.off()
