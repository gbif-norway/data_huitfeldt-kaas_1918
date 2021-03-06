# Updating local data-cache of Huitfelt-Kaas 1918 digitalization
# NB all paths relative to project directory (run from root of project folder)


#---------------
# update data
#-------------
source("./R/1_downoad_and_parse_data.R")
source("./R/2_normalize_data.R")
source("./R/3_visulize_occurrences.R")

#----------------
# push chances - work in progress... update github repro manually for now
#--------------------

# Push to github to sync eventID after updating
# Assumes installed and linked to correct repro 
# Remember, set ssh key first: see https://happygitwithr.com/ssh-keys.html#ssh-keys
# system("git add .")
# system("git commit -m 'updating lokal data-cache'")
# system("git push origin master")
