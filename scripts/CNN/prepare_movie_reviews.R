### compare word lengths of movie and Amazon reviews --- ###

default <- readLines(con = file("https://raw.githubusercontent.com/yoonkim/CNN_sentence/master/rt-polarity.neg"))

# is actually utf8!
head(default, n=50)

default2 <- readLines(con = file("https://raw.githubusercontent.com/yoonkim/CNN_sentence/master/rt-polarity.pos"))

head(default2)

cnn <- c(default, default2)

length(cnn)

words <- sapply(cnn, function(x){
  length(unlist(strsplit(x, " ")))
}, USE.NAMES = FALSE)

# distr in review data?

rev <- readLines("./theano/spam_100_small.txt")
rev2 <- readLines("./theano/ham_100_small.txt")

reviews <- c(rev, rev2)

length(reviews)

words.rev2 <- sapply(rev2, function(x){
  length(unlist(strsplit(x, " ")))
}, USE.NAMES = FALSE)

hist(words.rev2, breaks=500)

## conclusion: distribution not as normal as in yoonkim, but less zero padding (higher mean and median)
median(words)
median(words.revs)


### --- produce data for VW from movie reviews --- ###

default <- readLines(con = file("https://raw.githubusercontent.com/yoonkim/CNN_sentence/master/rt-polarity.neg"))
default2 <- readLines(con = file("https://raw.githubusercontent.com/yoonkim/CNN_sentence/master/rt-polarity.pos"))

closeAllConnections()

rt.pos <- data.frame(text=default2, spam=1)
rt.neg <- data.frame(text=default, spam=-1)

rt <- rbind(rt.neg, rt.pos)

tag <- row.names(rt)
spam.label <- rt$spam
textFeatures <- "|txt"
txt <- clean_text_VW(rt$text)

vw_input <- paste0(spam.label, " '", tag, " ", textFeatures, " ", txt)

permu.train <- sample(length(vw_input), length(vw_input))
vw_input <- vw_input[permu.train]

library(caret)
set.seed(1234)
data.split <- createDataPartition(rt$spam, p = 0.8, list = FALSE)

vw_input.train <- vw_input[data.split]
vw_input.test <- vw_input[-data.split]

vw.path <- "C:/Users/martin.m/vw/data/"
write.table(vw_input.train, file=paste0(vw.path, "vw_input_train_", "movies",".vw"), sep="/n", col.names = FALSE, row.names = FALSE, quote = FALSE)
write.table(vw_input.test, file=paste0(vw.path, "vw_input_test_", "movies",".vw"), sep="/n", col.names = FALSE, row.names = FALSE, quote = FALSE)

