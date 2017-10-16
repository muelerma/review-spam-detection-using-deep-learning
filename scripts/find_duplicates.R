### detect duplicates (without streaming, much memory needed)
# setwd("C://Users/muelerma.hub/Documents/amazon_local/")

library(textreuse)
library(jsonlite)

## stream-in
file.name <- "Electronics"
file.json <- paste0("./clean/reviews_",file.name,"_CLEAN.json")
# yelp
# file.json <- "./yelp/yelp_academic_dataset_review.json"

pagesize <- 5000
bands <- 18
hashes <- 90

reviews.raw <- stream_in(con=file(file.json), pagesize=pagesize)

# clean 
rev.txt <- reviews.raw$reviewText
rev.txt <- gsub("[[:punct:]]","",rev.txt)
rev.txt <- tolower(rev.txt)
rev.txt <- gsub("[[:space:]][[:space:]]+"," ",rev.txt)


## min-hasing & LSH

## how many hashes and what bandwith for particular similarity?
lsh_threshold(h=240,b=30)

lsh_probability(h = 240, b = 30, s = 0.8)
# docs with s = x similarity will be matched with ca. y% probability

minhash <- minhash_generator(n = hashes, seed = 3552)

corpus <- TextReuseCorpus(text = rev.txt,
                          tokenizer = tokenize_ngrams, 
                          n = 2,
                          minhash_func = minhash,
                          keep_tokens = FALSE,
                          progress = TRUE)

buckets <- lsh(corpus, bands = bands, progress = TRUE)

candidates <- lsh_candidates(buckets)

true.duplicates <- lsh_compare(candidates, corpus, f = jaccard_similarity)
hist(true.duplicates$score)
# save for later use
save(true.duplicates, file = paste0("candidates_",file.name,".RData"))

## now create final dataset from candidates (spam) and random negative samples (ham)



### --- ARCHIVE --- ###

## look at some actual reviews
# range <- true.duplicates$score > 0.7 & true.duplicates$score < 0.71
# sample.reviews <- true.duplicates[range,]

# are there "valid" duplicates? (same product, same reviewer)
# length(which(duplicated(dupl.reviews.raw[,c("reviewerID", "asin")])))  # -> No
