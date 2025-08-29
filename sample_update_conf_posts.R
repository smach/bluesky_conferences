# Sample file for updating conference hashtags

# Important to set directory if running in a cron job, so this is required
working_directory <- "/srv/shiny-server/bluesky_conferences"
setwd(working_directory)

conference_hashtags <- c("#PositConf2025", "#PositConf", "#PositConf25")

# Number of posts you want to pull each update, change as you wish
num_posts <- 250

# Where you want to store prior results
stored_post_file <- "data/previous_retrieved_posts.Rds"

min_date <- as.Date("2025-01-01") # So you don't get last year's conference posts, change as needed



# Where to save wrangled-for-app data
conference_file_path <- "data/table_posts.Rds" 

# If there are any accounts you want to remove manually, such as people who asked
# not to be included. The app looks for people with #nobot #nobots in their profile
# and labels requiring log-in to see their posts. 
# This default regexp removes any accounts from the Mastodon-to-Bluesky bridge.

accts_to_remove_manually <- ""
accts_to_remove_regexp <- c(".ap.brid.gy")

# Adjust path as needed
source("bluesky_conference_update_posts.R")