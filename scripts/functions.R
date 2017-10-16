### --- FUNCTIONS --- ###

## final dataset and descriptive statistics

# select particular pair with specific similarity score (to check manually how similar texts are)
candidate_pair <- function(candidate.pairs, threshold){
  
  pair <- candidate.pairs[candidate.pairs$score==threshold,]
  
  if(nrow(pair) > 1) pair <- pair[sample(nrow(pair),1),]
  
  cand.index <- c(pair$a, pair$b)
  pairs.index <- as.numeric(gsub("doc-","",cand.index))
  return(pairs.index)
}


# create column for cleaned text in order to find common duplicates
clean_text <- function(string.vec){
  
  sapply(string.vec, function(x){
    x <- gsub("[[:punct:]]","",x)
    x <- tolower(x)
    x <- gsub("[[:space:]][[:space:]]+"," ",x)
    return(x)
  }, USE.NAMES = FALSE)
}


# build index from true.duplicates
index_extr <- function(candidate.scores, threshold=0.9){
  
  filter.duplicates <- candidate.scores[candidate.scores$score >= threshold,]
  
  # create index for duplicate reviews
  cand.index <- c(filter.duplicates$a,filter.duplicates$b)
  cand.index.final <- cand.index[ !duplicated(cand.index) ]
  
  cand.index.num <- as.numeric(gsub("doc-","",cand.index.final))
  
  return(cand.index.num)
}


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

## clean raw text in order to use it as VW input (ie remove :, | etc)
clean_text_VW <- function(text, pos = FALSE){
  # set pos = TRUE if a POS annotated text is to be cleaned (as it contains /: string)
  if(pos){
    
    sapply(text, function(x){
      
      x <- gsub("\\/\\:","/COL",x)
      x <- gsub("\\:","",x)
      x <- gsub("\\|","",x)
      x <- gsub("\\\n","",x)
      x <- gsub("[[:space:]][[:space:]]+"," ",x)
      return(x)
      
    }, USE.NAMES = FALSE)
  }else{
    
    sapply(text, function(x){
      
      x <- gsub("\\:","",x)
      x <- gsub("\\|","",x)
      x <- gsub("\\\n","",x)
      x <- gsub("[[:space:]][[:space:]]+"," ",x)
      return(x)
      
    }, USE.NAMES = FALSE)
  }
}


f1_score <- function(predictions, labels){
  
  require(caret)
  precision <- posPredValue(as.factor(predictions), as.factor(labels), positive = "1")
  recall <- sensitivity(as.factor(predictions), as.factor(labels), positive = "1")
  
  2*precision*recall / (precision + recall)
}



### --- ARCHIVE --- ###

# ## F1 Score
# truePos <- sum(labels == 1 & preds.labels == 1)
# falsePos <- sum(labels == 0 & preds.labels == 1)
# falseNeg <- sum(labels == 1 & preds.labels == 0)
# 
# precision <- truePos / (truePos + falsePos)
# 
# recall <- truePos / (truePos + falseNeg)
# 
# f1_score <- 2*precision*recall / (precision + recall)
