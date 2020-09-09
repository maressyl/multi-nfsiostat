#!/usr/bin/Rscript

### USAGE : ./nfsiostat-heatmap.R [ DATE ]

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

# Time range
xlim <- range(tab$time)

# Heatmap colors
ymax <- NULL
colGroups <- unique(sub("^(read|write) - ", "", grep("^read|write - ", colnames(tab), value=TRUE)))
for(colGroup in colGroups) {
	# Columns
	r <- sprintf("read - %s", colGroup)
	w <- sprintf("write - %s", colGroup)
	
	# Cast measures as numeric
	tab[[r]] <- log(as.double(sub(" .+$", "", tab[[r]])) + 1, 10)
	tab[[w]] <- log(as.double(sub(" .+$", "", tab[[w]])) + 1, 10)
	
	# Max value
	x <- c(tab[[r]], tab[[w]])
	ymax[colGroup] <- quantile(x[ x > 0L ], 0.99)
	if(is.na(ymax[colGroup])) ymax[colGroup] <- 1
	
	# Colors
	tab[[colGroup]] <- rgb(
		red = pmin(tab[[r]] / ymax[colGroup], 1),
		green = 0,
		blue = pmin(tab[[w]] / ymax[colGroup], 1),
	)
}

# Server IP as factor
tab$server <- factor(tab$server)

png(sprintf("nfsiostat-heatmap_%s.png", day), width=2000, height=1000, res=100)

layout(matrix(1:2, nrow=1), widths=c(8,1))

# Background
par(mar=c(4,6,0.5,0.5))
plot(x=NA, y=NA, xlim=xlim, ylim=c(0, length(levels(tab$server))*(length(colGroups)+1)), xaxs="i", yaxs="i", xaxt="n", yaxt="n", bty="n", xlab="", ylab="")

# Plot frames
for(i in 1:length(colGroups)) {
	rect(
		xleft = tab$time,
		xright = tab$time + 60,
		ybottom = (as.integer(tab$server) - 1) * (length(colGroups) + 1) + i,
		ytop = (as.integer(tab$server) - 1) * (length(colGroups) + 1) + i + 1,
		col = tab[[ colGroups[i] ]],
		border = NA
	)
}

# Server axis
mtext(
	side=2, las=1, adj=c(0.5, 0.5), line=3, 
	at = (1:length(levels(tab$server)) - 1) * (length(colGroups) + 1) + 0.5 + (length(colGroups) + 1) / 2,
	text = sprintf("%s\n%s", levels(tab$server), hosts[levels(tab$server)])
)

# Time axis
at <- pretty(xlim, n=10)
axis(side=1, at=at, labels=strftime(at, format="%H:%M:%S"))

# Legend background
par(mar=c(0,0,0,0))
plot(x=NA, y=NA, xlim=0:1, ylim=0:1, xlab="", ylab="", xaxt="n", yaxt="n", bty="n")

# Legend boxes
for(i in 1:length(colGroups)) {
	legend(
		x=0.5, y=i / (length(colGroups) + 1),
		xjust=0.5, yjust=0.5,
		title = colGroups[i],
		fill = c("#FF0000", "#000000", "#0000FF"),
		legend = c(
			sprintf("read log(%g)", 10^ymax[ colGroups[i] ]),
			"idle",
			sprintf("write log(%g)", 10^ymax[ colGroups[i] ])
		)
	)
}

void <- dev.off()
