# local
setwd("C:/Users/martin.m/Documents/3.SemMaster/MA/spam_data")

source("functions.R")

### --- create Theano input file --- ###

## sample sentence from sentiment sentence classification:
## a tour de force of modern cinema . 
## -> decapitalized, but punctuation not removed (seperated with space instead)

sentence_length <- 100
data_size <- 12000 # max is 108754
# cases always balanced

### set file names 
out.spam <- "spam_100_12k_v2.1.txt"
out.ham <- "ham_100_12k_v2.1.txt"
out.test <- "test_100_12k_v2.1.txt"
out.test.results <- "test_results_100_12k_v2.1.txt"

out.vw.trainfile <- "100_12k_v21.vw"
out.vw.testfile <- "100_12k_v21.vw"

file.name <- "Electronics"

reviews <- get(load(paste0("reviews_final_features_", file.name,".RData")))

## clean
reviews$textTheano <- sapply(reviews$reviewText, FUN = function(x){
  x <- gsub("&#34;", "",x)
  x <- gsub("([[:punct:]])", " \\1 ", x)
  x <- gsub("[[:space:]][[:space:]]+", " ", x)
}, USE.NAMES = FALSE)

reviews$wordsTheano <- sapply(reviews$textTheano, function(x){
  length(unlist(strsplit(x, " ")))
}, USE.NAMES = FALSE)


## with word length < sentence_length only
reduced_length <- reviews[reviews$wordsTheano <= sentence_length, c("textTheano", "spam")]

## downsample to balanced classes
minority_size <- min(table(reduced_length$spam))
minority <- as.integer(names(table(reduced_length$spam)[table(reduced_length$spam) == minority_size]))
if(minority == 1) majority = 0 else majority = 1

## reduce majority group
select <- c(sample(which(reduced_length$spam == majority), minority_size), which(reduced_length$spam == minority))
reduced_length_balanced <- reduced_length[select,]

# # reshuffle
# set.seed(1234)
# reduced_length_balanced <- reduced_length_balanced[sample(nrow(reduced_length_balanced), nrow(reduced_length_balanced)),]

table(reduced_length_balanced$spam)
head(reduced_length_balanced$spam, n=30)

library(caret)
set.seed(1235)
# downsample?
if(data_size/nrow(reduced_length_balanced) < 1){
  
  downsamp <- createDataPartition(reduced_length_balanced$spam, p = min(1, data_size/nrow(reduced_length_balanced)), list = FALSE)
  reduced_length_balanced <- reduced_length_balanced[downsamp,]
  
}

table(reduced_length_balanced$spam)

## lowercase
# reduced_length_balanced$textTheano <- tolower(reduced_length_balanced$textTheano)

## create stratified train- and testset
split.index <- createDataPartition(reduced_length_balanced$spam, p=0.8, list = FALSE)
# load("./theano/train_idx_full_0.8.RData")

trainset <- reduced_length_balanced[split.index,]
testset <- reduced_length_balanced[-split.index,]

# final shuffle
trainset <- trainset[sample(nrow(trainset), nrow(trainset)),]
testset <- testset[sample(nrow(testset), nrow(testset)),]

# extract text per class
spam <- trainset$textTheano[trainset$spam == 1]
ham <- trainset$textTheano[trainset$spam == 0]

test.text <- testset$textTheano
test.results <- testset$spam

head(test.results, n=30)

write.table(spam, file = paste0(getwd(),"/theano/", out.spam), sep = "\n", row.names = F, col.names = F, quote = FALSE)
write.table(ham, file = paste0(getwd(),"/theano/", out.ham), sep = "\n", row.names = F, col.names = F, quote = FALSE)
write.table(test.text, file = paste0(getwd(),"/theano/", out.test), sep = "\n", row.names = F, col.names = F, quote = FALSE)
write.table(test.results, file = paste0(getwd(),"/theano/", out.test.results), row.names = F, col.names = F, quote = FALSE)


### --- create equivalent VW input --- ###
vw.path <- "C:/Users/martin.m/vw/data/"

# transfer trainset to VW format
tag <- row.names(trainset)
spam.label <- trainset$spam
textFeatures <- "|txt"
txt <- clean_text_VW(trainset$textTheano)

vw_input <- paste0(spam.label, " '", tag, " ", textFeatures, " ", txt)

## export
write.table(vw_input, file=paste0(vw.path, "vw_input_train_", out.vw.trainfile), sep="/n", col.names = FALSE, row.names = FALSE, quote = FALSE)

## test set separately
tag.test <- row.names(testset)
spam.label.test <- testset$spam
textFeatures.test <- "|txt"
txt.test <- clean_text_VW(testset$text)

vw_input.test <- paste0(spam.label.test, " '", tag.test, " ", textFeatures.test, " ", txt.test)

## export
write.table(vw_input.test, file=paste0(vw.path, "vw_input_test_", out.vw.testfile), sep="/n", col.names = FALSE, row.names = FALSE, quote = FALSE)


