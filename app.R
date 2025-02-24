# Sample app file sourcing main app functions


# Load conference configuration
source("app_config.R")

# Source the main app file from wherever it is
source("bluesky_conference_app.R")

shiny_conference_app(  conference_name = conference_name,
                       conference_name_no_spaces = conference_name_no_spaces,
                       file_with_data = file_with_data)


