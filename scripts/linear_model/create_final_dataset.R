# setwd("C:/Users/muelerma.hub/Documents/amazon_local")

source("functions.R")

## extract duplicates and some negative samples from complete category

file.name <- "Electronics"

file.json <- paste0("./clean/reviews_",file.name,"_CLEAN.json")
library(jsonlite)
reviews.raw <- stream_in(con=file(file.json), pagesize=5000)

load(paste0("./candidates/candidates_",file.name,".RData"))

# Make sure short generic reviews ("great product", "will buy again" etc.) are not sampled in large numbers due to high similarity:
# 1.) keep reviews above similarity threshold AND longer than certain length...
# 2.) ... and keep reviews above second threshold below this length when duplicate in both, summary AND review
# (see category_descr_stats.R for an analysis of word length and duplicates)
firstThresh <- 0.6
scndThresh <- 0.80000001
lengthToKeep <- 6

first.index <- index_extr(true.duplicates, firstThresh)
scnd.index <- index_extr(true.duplicates, scndThresh)

# stay below 2nd threshold (but above 1st)
index.spam1 <- first.index[!(first.index %in% scnd.index)]
reviews.spam.1 <- reviews.raw[ first.index[!(first.index %in% scnd.index)] ,]
length(index.spam1) == nrow(reviews.spam.1)
all.equal(reviews.spam.1$ID, index.spam1)

reviews.spam.1$reviewsClean <- clean_text(reviews.spam.1$reviewText)
reviews.spam.1$summaryClean <- clean_text(reviews.spam.1$summary)
reviews.spam.1$reviewWords <- sapply(reviews.spam.1$reviewsClean, function(x){
  length(unlist(strsplit(x, " ")))
}, USE.NAMES = FALSE)

table(reviews.spam.1$reviewWords > lengthToKeep)

# keep those between firstThresh and scndThresh with more words than lengthToKeep 
index.spam1.length <- index.spam1[reviews.spam.1$reviewWords > lengthToKeep]
reviews.spam.1.length <- reviews.spam.1[reviews.spam.1$reviewWords > lengthToKeep,]

length(index.spam1.length) == nrow(reviews.spam.1.length)
all.equal(index.spam1.length, reviews.spam.1.length$ID)

## now 2nd part: keep only those above 2nd threshold and those of short length which are duplicates in summary AND text
reviews.spam.2 <- reviews.raw[scnd.index,]

reviews.spam.2$summaryClean <- clean_text(reviews.spam.2$summary)
reviews.spam.2$reviewsClean <- clean_text(reviews.spam.2$reviewText)
reviews.spam.2$reviewWords <- sapply(reviews.spam.2$reviewsClean, function(x){
  length(unlist(strsplit(x, " ")))
}, USE.NAMES = FALSE)


shortLength <- reviews.spam.2$reviewWords < lengthToKeep
duplSummary <- duplicated(reviews.spam.2[,c("reviewsClean", "summaryClean")]) | 
  duplicated(reviews.spam.2[,c("reviewsClean", "summaryClean")],fromLast = TRUE)
table(!(shortLength & !duplSummary)) # drop the ones who are short and no dupl in summary and text
reviews.spam.2 <- reviews.spam.2[!(shortLength & !duplSummary),]
# index
index.spam2 <- scnd.index[!(shortLength & !duplSummary)]

length(index.spam2) == nrow(reviews.spam.2)
all.equal(index.spam2, reviews.spam.2$ID)

## concat 
reviews.spam.filtered <- rbind(reviews.spam.1.length, reviews.spam.2)
nrow(reviews.spam.filtered) / nrow(reviews.raw) # as percentage of all reviews
# index
spam.index <- c(index.spam1.length, index.spam2)

length(spam.index) == nrow(reviews.spam.filtered)
all.equal(spam.index, reviews.spam.filtered$ID)

# attach spam column
reviews.spam.filtered$spam <- 1

## for negative class: randomly select reviews from raw data
index.without.spam <- c(1:nrow(reviews.raw))[-spam.index]
set.seed(456)
negative.index <- sample(index.without.spam, nrow(reviews.spam.filtered))
reviews.nonspam <- reviews.raw[negative.index,]

all.equal(reviews.nonspam$ID, negative.index)

# add the same columns as for reviews.spam
reviews.nonspam$summaryClean <- clean_text(reviews.nonspam$summary)
reviews.nonspam$reviewsClean <- clean_text(reviews.nonspam$reviewText)
reviews.nonspam$reviewWords <- sapply(reviews.nonspam$reviewsClean, function(x){
  length(unlist(strsplit(x, " ")))
}, USE.NAMES = FALSE)

# attach spam column
reviews.nonspam$spam <- 0

## combine 
reviews.final <- rbind(reviews.spam.filtered, reviews.nonspam)
# final index
final.index <- c(spam.index, negative.index)
!any(duplicated(final.index))

length(final.index) == nrow(reviews.final)
table(duplicated(reviews.final[,setdiff(colnames(reviews.final), "spam")]))
all.equal(final.index, reviews.final$ID)

## save final file...
# save(reviews.final, file=paste0("reviews_final_", file.name, ".RData")
## ... or indices
save(spam.index, negative.index, file = paste0("final_indices_", file.name, ".RData"))


### --- for "simple" > 0.9 similarity dataset --- ###

# # load review data set and candidates
# 
# spam.index <- index_extr(true.duplicates, firstThresh)
# 
# index.without.spam <- c(1:nrow(reviews.raw))[-spam.index]
# 
# set.seed(456)
# negative.index <- sample(index.without.spam, length(spam.index))
# 
# save(spam.index, negative.index, file = paste0("final_indices_0.9_", file.name, ".RData"))
