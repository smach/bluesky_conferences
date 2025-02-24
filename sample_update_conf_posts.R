# Sample file for updating conference hashtags

# Important to set directory if running in a cron job
# working_directory <- "/srv/shiny-server/bluesky_conferences"
# setwd(working_directory)

conference_hashtags <- c("#PositConf2025", "#PositConf", "#PositConf25")

# Number of posts you want to pull each update
num_posts <- 250

# Where you want to store prior results
stored_post_file <- "data/previous_retrieved_posts.Rds"

min_date <- as.Date("2025-01-01") # So you don't get last year's conference posts



# Where to save wrangled-for-app data
conference_file_path <- "data/table_posts.Rds" 

# Adjust path accordingly
source("bluesky_conference_update_posts.R")