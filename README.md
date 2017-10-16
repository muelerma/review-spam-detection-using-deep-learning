*Review Spam Detection Using Deep Learning* (Master\`s Thesis)
================

Abstract
--------

Since the early years of the internet, spam has always been a side-effect of this global and public platform. Most people probably associate the word spam with annoying e-mails, but other forms of spam do exist. Review spam is a phenomenon encountered at online platforms where participants can rate and express their opinion on a particular product or service. Spammers leave untruthful reviews in order to promote their own or denigrate competitors’ offerings. This type of spam has not achieved much attention in the academic literature so far. In this work, we take a closer look at the state of academic research on this topic with the objective of filling some of the gaps identified. There are several obstacles to overcome when doing research on review spam. Firstly, real-world data is mostly unlabelled, i.e. the use of either ex post labelling techniques or unsupervised learning is necessary. Our analysis is based on two real-world data sets from Amazon and Yelp, where we identify untruthful reviews using a labelling technique based on reviews’ Jaccard similarity. As far as we know, with about 50.000 and 10.000 fake reviews detected in each data set, respectively, this is the largest set of review spam used in academic research so far. Existing studies take into consideration different features, models or data, which limits the comparability of their results. We employ a wide range of features, pre-processing techniques and models in order to find promising techniques to successfully detect review spam. This includes sophisticated deep-learning models that recently produced state-of-the-art benchmarks on related text classification tasks. In addition, we make use of the large amount of unlabelled data and train continuous word representations from scratch using a word2vec algorithm. These highly problem-specific word vectors improve the performance of our deep- learning model, but eventually we find that a simple linear classifier based on 2-gram bag-of- word input features outperforms most other approaches, including our deep-learning models. In the following chapter, we first summarize existing literature on the topic of review spam, in order to quantify the scope of this phenomenon and identify promising detection techniques. Subsequently, we introduce the data our analysis is based on and elaborate on the methodology to identify spam in the formerly unlabelled data, which is a necessary condition for using supervised machine learning approaches. In the fourth chapter we will discuss recent developments in the area of deep-learning, which are relevant to review spam detection, followed by the final section that describes our experiments.

Code Execution
--------------

All code needed to reproduce the results obtained during the experiments is included in this repository.

Software requirements:

-   Vowpal Wabbit
-   R (3.2.1)
-   Python (2.7.10)
-   Theano (0.8.2)

The following steps have to be undertaken in order to reproduce results:

### 1. Prepare Data

Use clean\_json\_amazon.py to convert reviews\_Electronics.json.gz to strict json to be able to work with it in R.

### 2. Identify near-duplicates

Use find\_duplicates.R to generate candidate pairs of near-duplicate reviews.

Use create\_finale\_dataset.R to filter based on similarity threshold and word length.

### 3. Feature Engineering

Use feature\_extraction.R to create features and select reviews using index files created previously

This step produces:

-   reviews\_final\_features\_Electronics\_full.RData
-   reviews\_final\_feature\_0.9\_Electronics.RData
-   reviews\_final\_yelp.RData

POS annotation can be performed using POS-script.R.

### 4. Linear Models

Use vowpal\_input.R to transform data to a format suitable for Vowpal Wabbit

This produces files in the form of:

-   vw\_input\_train\_\[...\].vw
-   vw\_input\_test\_\[...\].vw

Apply the following commands at the VW command line to achieve best performance:

Training:
vw -d \[path/to/train/data.vw\] -c -k -b 28 --ngram 2 --loss\_function logistic --passes 300 -f \[path/to/model.vw\]

Testing:
vw -d \[path/to/train/data.vw\] -t -i \[path/to/model.vw\] --link logistic -p \[path/to/predictions.txt\]

To assess model performance outside the VW tool, use vowpal\_output.R.

### 5. CNN

Use theano\_input.R to produce input data for CNN model training (truncated length and downsampled)

Use word2vec.ipynb to produce word embeddings based on reviews (use data as produced by theano\_input.R; pre-trained Google News vectors can be downlaoded from <https://github.com/mmihaltz/word2vec-GoogleNews-vectors>)

This produces files in the form of:

-   spam\_... / ham\_... / test\_... / test\_results\_...

And data in VW format to compare results based on same data:

-   vw\_input\_train\_... / vw\_input\_test\_...

To train a CNN use trainGraph.ipynb.
