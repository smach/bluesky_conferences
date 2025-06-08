accounts_to_remove <- c("djnavarro.net")

conference_name <- "posit::conf(2025)"
conference_name_no_spaces <- "posit_conf_2025"
file_with_data <- "data/table_posts.Rds" 
num_posts <- 300

about_text <- shiny::tags$p(
  "This app displays posts on Bluesky with tags related to the ", conference_name, " conference. You can browse or search posts. Table search filters accept regular expressions. It was built in R by Sharon Machlis and Posit's ", 
  shiny::tags$a(href = "https://gallery.shinyapps.io/assistant/", "Shiny Assistant", target = "_blank"),
  " using the shiny, DT, and data.table packages",
  class = "faq-answer"
)

how_often_updated_text <- shiny::tags$p(
  "The data is re-pulled every 20 to 60 minutes or so just before and during the conference. It's refreshed a few times a day in the weeks and months before.",
  class = "faq-answer"
)
