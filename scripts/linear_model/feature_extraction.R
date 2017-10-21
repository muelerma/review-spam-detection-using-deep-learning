## extract features from reviews
# setwd("C:/Users/martin.m/Documents/3.SemMaster/MA/spam_data/amazon")


load("../reviews_final_Electronics.RData")
reviews <- reviews.final
rm(reviews.final)

# rev.txt <- reviews$reviewText

### --- Preprocessing --- ###
# unlist $helpful
reviews$helpfulRated <- sapply(reviews$helpful,function(x){
  unlist(x)[1]
})

reviews$helpfulVoted <- sapply(reviews$helpful,function(x){
  unlist(x)[2]
})

reviews$helpfulness <- mapply(function(x, y){
  if(y == 0){ return(0) } else { return(x/y) }
}, reviews$helpfulRated, reviews$helpfulVoted)

# reviewTime transformed to as.Date
reviews$reviewDate <- as.Date(reviews$reviewTime,format="%m %d, %Y")


### --- review meta-characteristics --- ###

# dummy first, dummy only
# word length
# summary length
# rank for product by time
# overall, overall sd
# Nr voted
# Nr helpful
# helpfulness
# opposite 2nd review



## by asin: find smallest review time
# ONLY WORKS WITH COMPLETE REVIEW SET, NOT SUBSAMPLE!
minUnix <- aggregate(unixReviewTime ~ asin, reviews, FUN = min)
minUnix$firstReview <- 1
reviews <- merge(minUnix, reviews, by=c("asin","unixReviewTime"), all.y = TRUE)
reviews$firstReview[is.na(reviews$firstReview)] <- 0

  
## by asin: only review
# ONLY WORKS WITH COMPLETE REVIEW SET, NOT SUBSAMPLE!
reviews$onlyReview <- 0

onlyRevIndex <- !(duplicated(reviews$asin) & duplicated(reviews$asin, fromLast = TRUE))
reviews$onlyReview[ onlyRevIndex ] <- 1

# word length
# already exists from descriptive stats

# summary length
reviews$ncharSummary <- nchar(reviews$summary)

# rank for product by time
# ONLY WORKS WITH COMPLETE REVIEW SET, NOT SUBSAMPLE!
# from http://stackoverflow.com/questions/15170777/add-a-rank-column-to-a-data-frame
reviews$reviewRank <- ave(reviews$unixReviewTime, reviews$asin, FUN = function(x) rank(-x, ties.method = "first"))

# std dev of review from average product review
reviews$overallAvg <- ave(reviews$overall, reviews$asin)
reviews$overallSD <- sqrt((reviews$overall - reviews$overallAvg)^2)

# voted & helpful already in the data

# helpfulness 
# see preprocessing

# opposite 2nd review
reviews$opp2nd <- 0
reviews <- reviews[with(reviews, order(asin, reviewRank)),]
test <- ave(x = reviews$overall, reviews$asin, FUN = function(x) c(NA, diff(x)))
reviews$opp2nd[abs(test) > 1 & reviews$reviewRank==2] <- 1

### --- reviewER meta-characteristics --- ###
# AGAIN, complete data set is needed (actually, ALL reviews... not possible so category only)

# #reviews
reviewerCount <- tapply(rep(1,length(reviews$reviewerID)), reviews$reviewerID, FUN = sum)
# table(reviewerCount)

reviewer <- as.data.frame(reviewerCount)
reviewer$reviewerID <- row.names(reviewer)

# avg overall per reviewer
reviewerAvg <- tapply(reviews$overall, reviews$reviewerID, FUN = mean)
reviewer <- cbind(reviewer, reviewerAvg)

# reviewer sd
reviewerSD <- aggregate(reviews$overall, list(reviews$reviewerID), FUN = function(x) ifelse(is.na(sd(x)), 0, sd(x)))
colnames(reviewerSD)[1] <- "reviewerID"
colnames(reviewerSD)[2] <- "reviewerSD"
reviewer <- merge(reviewer, reviewerSD, by = "reviewerID")

## reviewer lifetime
# date first review
reviewerFirst <- aggregate(reviews$reviewDate, list(reviews$reviewerID), FUN = min, simplify = TRUE)
colnames(reviewerFirst)[1] <- "reviewerID"
colnames(reviewerFirst)[2] <- "firstReview"
reviewer <- merge(reviewer, reviewerFirst)

# date last review
reviewerLast <- aggregate(reviews$reviewDate, list(reviews$reviewerID), FUN = max, simplify = TRUE)
colnames(reviewerLast)[1] <- "reviewerID"
colnames(reviewerLast)[2] <- "lastReview"
reviewer <- merge(reviewer, reviewerLast)

reviewer$reviewerLife <- reviewer$lastReview - reviewer$firstReview


# ratio of first reviews
reviewerFirsts <- aggregate(reviews$reviewRank, list(reviews$reviewerID), FUN = function(x) sum(x == 1))
colnames(reviewerFirsts)[1] <- "reviewerID"
colnames(reviewerFirsts)[2] <- "reviewerFirsts"
reviewer <- merge(reviewer, reviewerFirsts)

reviewer$reviewerFirstsRatio <- as.numeric(reviewer$reviewerFirsts / reviewer$reviewerCount) 

# ratio of only reviews
reviewerOnly <- aggregate(reviews$onlyReview, list(reviews$reviewerID), FUN = sum)
colnames(reviewerOnly)[1] <- "reviewerID"
colnames(reviewerOnly)[2] <- "reviewerOnly"
reviewer <- merge(reviewer, reviewerOnly)

reviewer$reviewerOnlyRatio <- as.numeric(reviewer$reviewerOnly / reviewer$reviewerCount)

# always good, bad or average
reviewerCountGood <- aggregate(reviews$overall, list(reviews$reviewerID), FUN = function(x) sum(x >= 4))
reviewerCountBad <- aggregate(reviews$overall, list(reviews$reviewerID), FUN = function(x) sum(x <= 2))
reviewerCountAverage <- aggregate(reviews$overall, list(reviews$reviewerID), FUN = function(x) sum(x == 3))

reviewer$alwaysSame <- "mixed"
reviewer$alwaysSame[reviewerCountGood$x == reviewerCount] <- "good"
reviewer$alwaysSame[reviewerCountBad$x == reviewerCount] <- "bad"
reviewer$alwaysSame[reviewerCountAverage$x == reviewerCount] <- "average"

# dummies for types of mixed ratings
reviewer$onlyGoodBad <- 0
reviewer$onlyGoodBad[reviewerCountBad$x > 0 & reviewerCountGood$x > 0 & reviewerCountAverage$x == 0] <- 1

reviewer$onlyBadAverage <- 0
reviewer$onlyBadAverage[reviewerCountBad$x > 0 & reviewerCountAverage$x > 0 & reviewerCountGood$x == 0] <- 1

reviewer$onlyGoodAverage <- 0
reviewer$onlyGoodAverage[reviewerCountAverage$x > 0 & reviewerCountGood$x > 0 & reviewerCountBad$x == 0] <- 1

reviewer$onlyMixed <- 0
reviewer$onlyMixed[reviewerCountAverage$x > 0 & reviewerCountGood$x > 0 & reviewerCountBad$x > 0] <- 1

# ratio opposite 2nd review
reviewerOpp2nd <- aggregate(reviews$opp2nd, list(reviews$reviewerID), FUN = sum)
colnames(reviewerOpp2nd)[1] <- "reviewerID"
colnames(reviewerOpp2nd)[2] <- "reviewerOpp2nd"
reviewer <- merge(reviewer, reviewerOpp2nd)

reviewer$reviewerOpp2ndRatio <- as.numeric(reviewer$reviewerOpp2nd / reviewer$reviewerCount)



### --- Product meta --- ### 
# ONLY WORKS WITH COMPLETE REVIEW SET, NOT SUBSAMPLE!

# avg product rating
productRatingAvg <- tapply(reviews$overall, reviews$asin, mean)

# sd product rating
productRatingSD <- tapply(reviews$overall, reviews$asin, FUN = function(x) ifelse(is.na(sd(x)), 0, sd(x)))

# #reviews
productReviewCount <- tapply(rep(1,length(reviews$asin)), reviews$asin, FUN = sum)

# combine
products <- as.data.frame(cbind(productReviewCount, productRatingSD, productRatingAvg))
products$asin <- row.names(products)


## stream in product metadata to obtain price, salesRank etc. 
## (needs to be prepared with clean_json_amazon.py)
library(jsonlite)
electro_products <- stream_in(con = file("metadata_Electronics.json"), pagesize = 5000)

# collapse sales rank columns into one (using higherst sales rank for each product)
electro_products$topSalesRank <- apply(electro_products$salesRank, 1, function(x){
  if(all(is.na(x))){
    return(NA)
  }else{
    return(x[which.min(x)])
  }
})

# merge products and relevant metadata column
products.meta <- merge(products, electro_products[,c("asin","title", "price", "topSalesRank", "brand", "description")],
                       by = "asin", all.x = TRUE)


### --- merge reviews with reviewer and product data --- ###

reviews.mergedReviewer <- merge(reviews, reviewer.meta, by = "reviewerID", all.x = TRUE)

reviews.complete <- merge(reviews.mergedReviewer, products.meta, by = "asin", all.x = TRUE)


save(reviews.complete, file = "reviews_non-text_features.RData")

## turn into valid VW input using vowpal.R

## optionally: POS annotate using POS-script.R


