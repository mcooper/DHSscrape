library(tidyverse)
library(rdhs)

#set_rdhs_config(email = 'mattcoop@terpmail.umd.edu',
#                project = 'Scenarios Under 5 Mortality in the 21st Century')

fs <- list.files('~/mortalityblob/dhszip')

datasets  <- dhs_datasets()

datasets <- datasets %>%
  filter(FileFormat == 'Stata dataset (.dta)' | 
         (FileFormat == 'Flat ASCII data (.dat)' & DatasetType == 'GPS Datasets'),
         !FileName %in% fs)

get_datasets(datasets$FileName, download_option = 'zip', output_dir_root='~/mortalityblob/dhszip')

#unzip \*.zip -d ../dhsraw
