#!/usr/bin/Rscript

### USAGE : ./heatmap.R [ DATE ]

source("fun/collect.R")
out <- collect()
tab <- out$tab
day <- out$day

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

png(sprintf("plots/heatmap_%s.png", day), width=2000, height=1000, res=100)

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
	text = levels(tab$server)
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
