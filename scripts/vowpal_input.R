### --- VW input text --- ###
# local
# setwd("C:/Users/martin.m/Documents/3.SemMaster/MA/spam_data")

source("functions.R")

## sample line of vw input:
# label 'tag |namespace var1 var2 ...
# 4 '22 |f good for the goose
library(caret)

file.name <- "Electronics"

## which features to VW format?
# 1 BOW (text only)
# 2 BOW + POS (POS annotated text)
# 3 BOW + hand-crafted
# 4 hand-crafted only
# 5 all: BOW + POS + hand-crafted
fs <- 1

## which hand-crafted features to include? (default/NULL is Jindal)
hcf <- NULL

## logistic error function in VW?
logistic <- TRUE

## class imbalance (spam as % of total obs; NULL is 1:1)
ci <- NULL


if(!exists("reviews")) reviews <- get(load(paste0("reviews_final_features_", file.name,".RData")))


# # in case this was not correct, rename
# colnames(reviews)[colnames(reviews)=="firstReview.x"] <- "firstReview"
# colnames(reviews)[colnames(reviews)=="firstReview.y"] <- "firstReviewDate"
# colnames(reviews)[colnames(reviews)=="lastReview"] <- "lastReviewDate"
# 
# ## recode alwaysSame into dummies (for better representation in VW format)
# reviews$alwaysGood <- ifelse(reviews$alwaysSame == "good", 1, 0)
# reviews$alwaysBad <- ifelse(reviews$alwaysSame == "bad", 1, 0)
# reviews$alwaysAverage <- ifelse(reviews$alwaysSame == "average", 1, 0)
# reviews$mixed <- ifelse(reviews$alwaysSame == "mixed", 1, 0)

## clean dirty text for VW input (i.e. remove : | etc.)
reviews$VWcleanText <- clean_text_VW(reviews$reviewText)

## class imbalance downsampling
if(!is.null(ci)){
  ci_r <- 1 / (1-ci) - 1
  nr.obs <- as.integer(ci_r * sum(reviews$spam == 1))
  select <- c(which(reviews$spam == 1)[1:nr.obs], which(reviews$spam == 0))
  reviews <- reviews[select,]
  
  table(reviews$spam)
}


## selected features
jindal.features <- c("onlyReview", "firstReview", "reviewWords", "ncharSummary", "reviewRank",
                     "overall", "overallSD", "helpfulRated", "helpfulVoted", "helpfulness", "opp2nd",
                     "reviewerAvg", "reviewerSD", "reviewerFirstsRatio", "reviewerOnlyRatio",
                     "alwaysGood", "alwaysAverage", "alwaysBad", "mixed",
                     "onlyBadAverage", "onlyGoodAverage", "onlyGoodBad", "onlyMixed", "reviewerOpp2ndRatio",
                     "productRatingAvg", "productRatingSD")
                    # price, sales rank NAs

if(is.null(hcf)) hcf <- jindal.features # can be imported from functions.R?


spam.label <- reviews$spam
# in case loss_function = logistic
if(logistic) spam.label <- ifelse(reviews$spam == 0, -1, 1)

tag <- row.names(reviews)

if(fs == 1 | fs == 3){
  textFeatures <- "|txt"
  txt <- reviews$VWcleanText
}

if(fs == 2 | fs == 5){
  posFeatures <- "|pos"
  pos_txt <- reviews$VWreviewTextPOS # stimmt der colname?
}

if(fs > 2){
  handFeatures <- "|non_txt"
  # format: feature1:float feature2:float ...
  reviews.feature.names <- colnames(reviews[,hcf])
  reviews.features <- apply(reviews[,hcf], MARGIN = 1, FUN = function(x, names){
    paste(names, sprintf("%.5f",x), sep=":", collapse = " ")
  }, names = reviews.feature.names)
  # clean spaces
  reviews.features <- gsub(" +", " ", gsub(": ", ":", reviews.features))
}


### --- create VW input file --- ###

switch(fs,
       vw_input <- paste0(spam.label, " '", tag, " ", textFeatures, " ", txt),
       vw_input <- paste0(spam.label, " '", tag, " ", posFeatures, " ", pos_txt),
       vw_input <- paste0(spam.label, " '", tag, " ", textFeatures, " ", txt, " ", 
                          handFeatures, " ", reviews.features),
       vw_input <- paste0(spam.label, " '", tag, " ", handFeatures, " ", reviews.features),
       vw_input <- paste0(spam.label, " '", tag, " ", posFeatures, " ", pos_txt, " ",
                          handFeatures, " ", reviews.features)
       )


if(!exists("data.split")){
  # set.seed(123)
  # data.split <- createDataPartition(reviews$spam, p = 0.8, list = FALSE)
  
  data.split <- get(load("data_split_backup.RData"))
}
  

vw_input.train <- vw_input[data.split]
vw_input.test <- vw_input[-data.split]


## test set downsampling
# test.labels <- sapply(vw_input.test, FUN = function(x) as.integer(unlist(strsplit(x, split = " "))[1]), USE.NAMES = FALSE)
# sample.size <- floor(0.02*sum(test.labels == 1))
# test.index.pos <- which(test.labels == 1)[1:sample.size]
# test.index.neg <- which(test.labels == -1)
# test.index <- c(test.index.pos, test.index.neg)
# test.index.final <- test.index[sample(length(test.index), length(test.index))]
# 
# vw_input.test <- vw_input.test[test.index.final]


## permutate order for VW
if(!exists("permu.train")) permu.train <- get(load("permu_train_backup.RData"))
# permu.train <- sample(length(vw_input.train), length(vw_input.train))
vw_input.train <- vw_input.train[permu.train]

if(!exists("permu.test")) permu.test <- get(load("permu_test_backup.RData"))
# permu.test <- sample(length(vw_input.test), length(vw_input.test))
vw_input.test <- vw_input.test[permu.test]


vw.path <- "C:/Users/martin.m/vw/data/"
ci_char <- if(!is.null(ci)){ paste0("_", ci) } else { paste0(ci) }

switch(fs,
       {
       write.table(vw_input.train, file=paste0(vw.path, "vw_input_train_", file.name, ci_char,"_BOW.vw"), sep="/n", col.names = FALSE, row.names = FALSE, quote = FALSE)
       write.table(vw_input.test, file=paste0(vw.path,"vw_input_test_", file.name, ci_char, "_BOW.vw"), sep="/n", col.names = FALSE, row.names = FALSE, quote = FALSE)
       },
       {
       write.table(vw_input.train, file=paste0(vw.path,"vw_input_train_", file.name, ci_char,"_POS.vw"), sep="/n", col.names = FALSE, row.names = FALSE, quote = FALSE)
       write.table(vw_input.test, file=paste0(vw.path, "vw_input_test_", file.name, ci_char,"_POS.vw"), sep="/n", col.names = FALSE, row.names = FALSE, quote = FALSE)
       },
       {
       write.table(vw_input.train, file=paste0(vw.path, "vw_input_train_", file.name, ci_char,"_BOW_hcf.vw"), sep="/n", col.names = FALSE, row.names = FALSE, quote = FALSE)
       write.table(vw_input.test, file=paste0(vw.path, "vw_input_test_", file.name, ci_char,"_BOW_hcf.vw"), sep="/n", col.names = FALSE, row.names = FALSE, quote = FALSE)
       },
       {
       write.table(vw_input.train, file=paste0(vw.path, "vw_input_train_", file.name, ci_char,"_hcf.vw"), sep="/n", col.names = FALSE, row.names = FALSE, quote = FALSE)
       write.table(vw_input.test, file=paste0(vw.path, "vw_input_test_", file.name, ci_char,"_hcf.vw"), sep="/n", col.names = FALSE, row.names = FALSE, quote = FALSE)
       },
       {
       write.table(vw_input.train, file=paste0(vw.path, "vw_input_train_", file.name, ci_char,"_POS_hcf.vw"), sep="/n", col.names = FALSE, row.names = FALSE, quote = F)
       write.table(vw_input.test, file=paste0(vw.path, "vw_input_test_", file.name, ci_char,"_POS_hcf.vw"), sep="/n", col.names = FALSE, row.names = FALSE, quote = F)
       })



### --- Archive --- ###

# # test if R output is equal to what is fed to VW
# all.equal(spam.label[data.split][permu.train], 
#           sapply(strsplit(vw_input.train, " "), function(x) as.numeric(unlist(x)[1])))

