# local
setwd("C:/Users/martin.m/Documents/3.SemMaster/MA/spam_data")

source("functions.R")

### --- read VW predictions and calculate metrics --- ###

test.file <- "vw_input_test_theano100_full.vw"
pred.file <- "preds_theano100_full.txt"

cutoff <- 0.5

preds <- read.table(paste0("C:/Users/martin.m/vw/", pred.file), header=FALSE, sep=" ")
preds <- preds$V1

# labels <- load("C:/Users/martin.m/vw/labels.RData")
test.data <- readLines(paste0("c:/Users/martin.m/vw/data/", test.file))
labels <- sapply(test.data, FUN = function(x) as.integer(unlist(strsplit(x, split = " "))[1]), USE.NAMES = FALSE)

if(any(labels == -1)) labels <- ifelse(labels == -1, 0, 1)

# ## for cut-off tuning: divide test set
# half.index <- sample(length(labels), 0.5*length(labels))
# 
# labels.all <- labels
# labels <- labels.all[half.index]
# labels2 <- labels.all[-half.index]
# preds.all <- preds
# preds <- preds.all[half.index]
# preds2 <- preds.all[-half.index]


preds.labels <- ifelse(preds > cutoff, 1, 0)

## AUC
library(pROC)
aucurve <- auc(labels, preds)
roc.obj <- roc(labels, preds)

## Accuracy
## TP + TN / all
accuracy <- mean(labels == preds.labels)

## F1-score
f1s <- f1_score(preds.labels, labels)

sensitivity(as.factor(preds.labels), as.factor(labels), positive = "1")
specificity(as.factor(preds.labels), as.factor(labels), negative = "0")
posPredValue(as.factor(preds.labels), as.factor(labels), positive = "1")

print(paste("AUC:", aucurve))
paste("Accuracy:", accuracy)
print(paste("F1-score:", f1s))

plot.roc(roc.obj, print.thres = c(0.5))

confusionMatrix(preds.labels, labels)

co.new <- coords(roc.obj, x = "best", best.method = "youden")

## using new cut-off
# preds.labels.new <- ifelse(preds > co.new["threshold"] , 1, 0)
# 
# accuracy.new <- mean(labels == preds.labels.new)
# 
# sensitivity(as.factor(preds.labels.new), as.factor(labels), positive = "1")
# specificity(as.factor(preds.labels.new), as.factor(labels), negative = "0")
# 
# f1s.new <- f1_score(preds.labels.new, labels)


## use 2nd set to validate new cut-off
preds.labels.new2 <- ifelse(preds2 > co.new["threshold"] , 1, 0)

mean(labels2 == preds.labels.new2)

sensitivity(as.factor(preds.labels.new2), as.factor(labels2), positive = "1")
specificity(as.factor(preds.labels.new2), as.factor(labels2), negative = "0")
posPredValue(as.factor(preds.labels.new2), as.factor(labels2), positive = "1")

f1_score(preds.labels.new2, labels2)

plot.roc(roc.obj, print.thres = c(0.5, co.new["threshold"]))

confusionMatrix(preds.labels.new2, labels2)


