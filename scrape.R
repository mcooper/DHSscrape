library(rdhs)
library(rvest)
library(tidyverse)
library(countrycode)

#################################
# Scrape Data from DHS Website
# (Needed to Get DHS Number (1-8)

url <- 'https://dhsprogram.com/data/available-datasets.cfm'

#Download URL, since it is timing out in Linux
download.file(url, destfile = "scrapedpage.html", quiet=TRUE)

#Reading the HTML code from the website
webpage <- read_html('scrapedpage.html') %>%
	html_node(xpath='//*[@id="CS_CCF_8012_8019"]')

countries <- webpage %>%
	html_nodes("div.datasets__title") %>% 
	html_text()

tables <- webpage %>%
	html_nodes("table") %>%
	html_table()

scrape <- mapply(FUN=function(t, c){t$country <-c; t},
			 t=tables,
			 c=countries, SIMPLIFY=F) %>%
	bind_rows() %>%
	mutate(Survey = gsub("\\n.*$", "", Survey), 
				 StartYear = as.numeric(str_extract(Survey, '\\d{4}')),
				 EndYear = as.numeric(str_extract(Survey, '\\d{2}$')),
				 EndYear = ifelse(EndYear > 50, 1900 + EndYear, 2000 + EndYear),
         cc = countrycode(country, 'country.name', 'dhs'),
         num = as.numeric(as.roman(gsub('DHS-', '', ifelse(Phase != 'Other', Phase, NA)))),
         num = ifelse(num == 0, 1, num)) %>%
  group_by(cc, num) %>%
  mutate(subversion = n():1) %>%
  ungroup %>%
  mutate(survey_code = paste0(cc, '-', num, '-', subversion)) %>%
  data.frame

#################################
# Get DHS API data
# (Has survey release date)

surveys <- dhs_surveys() %>%
  mutate(Survey = paste(CountryName, SurveyYearLabel)) %>%
  select(Survey, ReleaseDate)

#Get all that I have
# rclone ls az:mortalityblob/dhsraw > ~/DHSscrape/dhsraw
have <- read.csv('~/DHSscrape/dhsraw', header=F, stringsAsFactors=F) %>%
  mutate(V1 = tolower(substr(V1, 11, 18)),
         cc = toupper(substr(V1, 1, 2)),
         num = substr(V1, 5, 5),
         subversion=ifelse(toupper(substr(V1, 6, 6)) %in% as.character(seq(0, 9)), 1,
                     ifelse(toupper(substr(V1, 6, 6)) %in% LETTERS[1:8], 2, 
                            ifelse(toupper(substr(V1, 6, 6)) %in% LETTERS[9:17], 3, 
                                   ifelse(toupper(substr(V1, 6, 6)) %in% LETTERS[18:26],
                                          4, '')))),
         survey_code = paste0(cc, '-', num, '-', subversion)) %>%
  select(cc, num, subversion) %>%
  unique %>%
  mutate(num = ifelse(num == "0", 1, num),
         survey_code = paste0(cc, '-', num, '-', subversion))

need <- comb %>%
  filter(!survey_code %in% have$survey_code,
         Survey.Datasets == 'Data Available',
         GPS.Datasets == 'Data Available')

#There are a number of surveys with different match and 

##############################################################
# Honestly the easiest thing is to just record the last date
# and check later to see what has been published since then

library(rdhs)
library(lubridate)
library(tidyverse)

LAST_DOWNLOAD_DATE <- '2021-01-12'

surveys <- dhs_surveys()

surveys <- surveys %>%
  filter(ymd(ReleaseDate) > ymd(LAST_DOWNLOAD_DATE))
