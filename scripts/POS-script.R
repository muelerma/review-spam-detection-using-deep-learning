
### --- POS annotation --- ###

# setwd("C:/Users/martin.m/Documents/3.SemMaster/MA/spam_data/amazon")


load("reviews_final_Electronics.RData")
# rename
reviews <- reviews.final
rm(reviews.final)


## POS function 
# function from www.martinschweinberger.de
POStag <- function(Corpus = Corpus){
  require("NLP")
  require("openNLP")
  #   require("openNLPmodels.en")
  #   corpus.files = list.files(path = path, pattern = NULL, all.files = T,
  #                             full.names = T, recursive = T, ignore.case = T, include.dirs = T)
  #   corpus.tmp <- lapply(corpus.files, function(x) {
  #     scan(x, what = "char", sep = "\t", quiet = T) }  )
  #   corpus.tmp <- lapply(corpus.tmp, function(x){
  #     x <- paste(x, collapse = " ")  }  )
  #   corpus.tmp <- lapply(corpus.tmp, function(x) {
  #     x <- enc2utf8(x)  }  )
  #   corpus.tmp <- gsub(" {2,}", " ", corpus.tmp)
  #   corpus.tmp <- str_trim(corpus.tmp, side = "both") 
  #   Corpus <- lapply(corpus.tmp, function(x){
  #     x <- as.String(x)  }  )
  sent_token_annotator <- Maxent_Sent_Token_Annotator()
  word_token_annotator <- Maxent_Word_Token_Annotator()
  pos_tag_annotator <- Maxent_POS_Tag_Annotator() 
  lapply(Corpus, function(x){
    if(x == "") return(x)
    y1 <- annotate(x, list(sent_token_annotator, word_token_annotator))
    y2 <- annotate(x, pos_tag_annotator, y1)
    #  y3 <- annotate(x, Maxent_POS_Tag_Annotator(probs = TRUE), y1)
    y2w <- subset(y2, type == "word")
    tags <- sapply(y2w$features, '[[', "POS")
    r1 <- sprintf("%s/%s", as.String(x)[y2w], tags)
    r2 <- paste(r1, collapse = " ")
    return(r2)})
}

pos_tagged_list <- POStag(reviews$reviewText)
pos_tagged_text <- unlist(pos_tagged_list)

reviews$POSreviewText <- pos_tagged_text

save(reviews, file="reviews_final_Electronics_POStagged.RData")

## next: turn into VW valid input format using vowpal.R
