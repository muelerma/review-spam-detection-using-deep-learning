## convert provided Amazon reviews to strict json to be able to work with it in R
## see http://jmcauley.ucsd.edu/data/amazon/

import json
import gzip

def parse(path):
  g = gzip.open(path, 'r')
  for l in g:
    yield json.dumps(eval(l))


f = open("C:/Users/martin.m/Documents/3.SemMaster/MA/spam_data/amazon/cleaned/reviews_Electronics_CLEAN.json", 'w')

for l in parse("C:/Users/martin.m/Documents/3.SemMaster/MA/spam_data/amazon/raw_reviews/reviews_Electronics.json.gz"):
  f.write(l + '\n')
