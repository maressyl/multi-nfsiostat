#!/usr/bin/Rscript

# Collect data for the date provided (or not) through CLI
collect <- function() {
	# CLI arguments
	args <- commandArgs(TRUE)
	if(length(args) == 1L) {
		day <- args[1]
	} else {
		day <- strftime(Sys.time(), "%Y-%m-%d")
	}
	
	# Loop over nfsiostat files
	tab <- NULL
	inputFiles <- dir("store", pattern=sprintf("%s_.*\\.txt$", day), full.names=TRUE)
	for(inputFile in inputFiles) {
		# Server IP
		server <- sub("^.+_(.+)\\.txt$", "\\1", basename(inputFile))
		server <- sub("\\.chu-lyon\\.fr$", "", server)
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
	
	# Loop over df files
	inputFile <- sprintf("store/%s.txt", day)
	if(file.exists(inputFile)) {
		df <- read.table(inputFile, stringsAsFactors=FALSE, col.names=c("time", "filesystem", "blocks.1K", "used", "available", "used.%", "mountpoint"), check.names=FALSE)
		df$time <- strptime(paste(day, df$time, sep="T"), format="%Y-%m-%dT%H:%M:%S")
	} else {
		df <- data.frame(
			"time"       = as.POSIXct(integer(0), origin="1970-01-01"),
			"filesystem" = character(0),
			"blocks.1K"  = numeric(0),
			"used"       = numeric(0),
			"available"  = numeric(0),
			"used.%"     = numeric(0),
			"mountpoint" = character(0),
			stringsAsFactors=FALSE,
			check.names=FALSE
		)
	}
	
	return(list(tab=tab, day=day, df=df))
}

