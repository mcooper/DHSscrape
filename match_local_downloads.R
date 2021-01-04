library(tidyverse)
library(stringr)

down <- read.csv('~/downloads', header=F) %>%
  mutate(V2 = tolower(str_extract(V1, '.{9}(?:zip)')),
         V2 = substr(V2, 1, 8))
have <- read.csv('~/dhsraw', header=F, stringsAsFactors=F) %>%
  mutate(V1 = tolower(substr(V1, 11, 18))) %>%
  unique %>%
  filter(grepl('pr|ge', V1))

cat(as.character(down$V1)[!down$V2 %in% have$V1], file='~/new_downloads', sep='\n')

