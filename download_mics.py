from selenium import webdriver
import time
import os

################################
#Download data
################################

os.chdir('/home/mattcoop/gd/data/MICSnew')

driver = webdriver.Chrome()

driver.get('https://mics.unicef.org/surveys')

#Now click on one of the surveys that say "Available" under "Datasets" in order to prompt a login

pages = ["1", "2", "3", "4", "5", "..."]  #As of 10/26/2019, there are six pages, and the way to get to the sixth is to click "..."

def clickpage(page):    
    pagebutton = driver.find_element_by_link_text(page)
    
    pagebutton.click()
    
    time.sleep(2)

def downloadDatasets():
    elements = driver.find_elements_by_partial_link_text('Available')
    
    for elem in elements:
        elem.click()
        time.sleep(1)

for page in pages:
    clickpage(page)
    downloadDatasets()

