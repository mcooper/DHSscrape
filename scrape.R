library(rvest)
library(tidyverse)

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

comb <- mapply(FUN=function(t, c){t$country <-c; t},
			 t=tables,
			 c=countries, SIMPLIFY=F) %>%
	bind_rows() %>%
	mutate(Survey = gsub("\\n.*$", "", Survey), 
				 StartYear = as.numeric(str_extract(Survey, '\\d{4}')),
				 EndYear = as.numeric(str_extract(Survey, '\\d{2}$')),
				 EndYear = ifelse(EndYear > 50, 1900 + EndYear, 2000 + EndYear)) %>%
	data.frame

#Determine countries with small gaps between surveys
dat <- comb %>%
	filter(GPS.Datasets == 'Data Available',
				 Type %in% c('Continuous DHS', 'Standard DHS', 'Interim DHS',
										 'MIS', 'AIS', 'MICS', 'Special DHS')) %>%
	arrange(country, EndYear) %>%
	filter(EndYear > 2000) %>%
	group_by(country) %>%
	mutate(Range=c(min(EndYear)-2000, diff(EndYear))) %>%
	select(country, EndYear, Range) %>%
	filter(all(Range < 8)) %>%
	summarize(EndYear=max(EndYear),
						MaxGap=max(Range),
						n()) %>%
	arrange(EndYear) %>%
	data.frame()
