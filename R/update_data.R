# Updating local data-cache of Huitfelt-Kaas 1918 digitalization

# NB all paths relative to project directory

source("./R/1_downoad_and_parse_data.R")
source("./R/2_normalize_data.R")
source("./R/3_visulize_occurrences.R")

# Push to github to sync eventID after updating
#system("git add .")
#system("git commit -m 'updating lokal data-cache'")
#system("git push origin master")

# Setup to automate pushing. From: https://stackoverflow.com/questions/8588768/how-do-i-avoid-the-specification-of-the-username-and-password-at-every-git-push

# sudo apt-get install libgnome-keyring-dev
# sudo make --directory=/usr/share/doc/git/contrib/credential/gnome-keyring
# git config --global credential.helper /usr/share/doc/git/contrib/credential/gnome-keyring/git-credential-gnome-keyring
# 
# git config --global credential.helper store

# https://git@github.com/username/reponame.git