

# set working directory in cron job if necessary

library(atrrr)
library(tidyr)
library(purrr)
library(dplyr)
library(data.table)

readRenviron(file.path(Sys.getenv("HOME"), ".Renviron"))

#Set token if you use multiple accounts, use your token name
Sys.setenv(BSKY_TOKEN = "token.rds")

# Authentication requires a Bluesky app user name and password in an .Renviron file.
# Or, set/get another way of your choice
atrrr::auth(user = Sys.getenv("BLUESKY_APP_USER"),
            password = Sys.getenv("BLUESKY_APP_PASS"),
            overwrite = TRUE)



#' get_one_hashtag
#' Function to retrieve and wrangle Bluesky posts for one hashtag 
#' 
#' @param the_hashtag character string with a hashtag in format '#positconf2025'
#' @param the_limit integer with desired number of posts to retrieve
#'
#' @returns data frame with columns Post, By, Name, CreatedAt, Likes, Reposts, Quoted, URI, ExternalURLs, Tags, PostID, URL, Text, TimePulled
#' @export

get_one_hashtag <- function(the_hashtag, the_limit = 250) {
  atrrr::auth(user = Sys.getenv("BLUESKY_APP_USER"),
              password = Sys.getenv("BLUESKY_APP_PASS"),
              overwrite = TRUE)
  
  
  the_hashtag2 <- gsub("#", "", the_hashtag, fixed = TRUE)
  mydata <- atrrr::search_post(q = the_hashtag, limit = the_limit)
  
  # Claude solution
  # external_url_vector <- mydata$embed_data %>%
  #  map_chr(~ pluck(.x, "external", "uri", .default = NA_character_))
  
  # ChatGPT 3o-mini-high solution
  mydata_wrangled <- mydata %>%
    dplyr::mutate(external_urls = purrr::map_chr(embed_data, ~ {
      # Safely extract the URI; if it doesn't exist, use NA_character_
      uri_val <- purrr::pluck(.x, "external", "uri", .default = NA_character_)
      # If the value is NULL (or all NA), return NA, otherwise collapse multiple values
      if (is.null(uri_val)) {
        NA_character_
      } else {
        paste(uri_val, collapse = ", ")
      }
    })
    ) |>
    dplyr::select(Post = text, By = author_handle, Name = author_name, CreatedAt = indexed_at, Likes = like_count, Reposts = repost_count, Replies = reply_count, URI = uri, ExternalURLs = external_urls, Tags = tags) |>
    dplyr::mutate(
      PostID = stringr::str_replace(URI, "at.*?post\\/(.*?)$", "\\1"),
      URL = glue::glue("https://bsky.app/profile/{By}/post/{PostID}"),
      Text = paste0(Post, " <a target='_blank' href='", URL, "'> <strong> >> </strong></a>"),
      TimePulled = Sys.time()
    )
  
  mydata_wrangled$Tags_String <- purrr::map_chr(mydata_wrangled$Tags, ~ {
    if (length(.x) == 0) {
      NA_character_
    } else {
      paste(.x, collapse = ", ")
    }
  }
  )
  
  return(mydata_wrangled)
  
  
  
}  

# Get deduped posts for the conference hashtags
all_recent_posts <- purrr::map_dfr(conference_hashtags, ~ get_one_hashtag(the_hashtag = .x, the_limit = num_posts))

deduped_recent_posts <- all_recent_posts |>
  dplyr::distinct(URI, .keep_all = TRUE) |>
  dplyr::filter(!(By %in% accounts_to_remove))



# Check with previous retrieved deduped posts and use newest versions

# If file exists
if (file.exists(stored_post_file)) {
  previous_retrieved_posts <- readRDS(stored_post_file)
  combined_recent_posts <- rbind(previous_retrieved_posts, deduped_recent_posts) |>
    dplyr::group_by(URI) |>
    dplyr::arrange(desc(TimePulled)) |>
    dplyr::slice(1) |>
    dplyr::ungroup() |>
    dplyr::arrange(desc(CreatedAt))
  saveRDS(combined_recent_posts, stored_post_file)
  
} else {
  saveRDS(deduped_recent_posts, stored_post_file)
}


# Create a table of the deduped posts with the DT R package.
table_posts <- readRDS(stored_post_file) |>
  dplyr::filter(as.Date(CreatedAt) >= min_date) |>
  dplyr::mutate(
    HasExternalURLs = if_else(ExternalURLs == "NA", FALSE, TRUE),
    CreatedAt = format(CreatedAt, "%Y-%m-%d %H:%MZ")
  ) |>
  select(CreatedAt, Text, Author = Name, Likes, Reposts, Replies, AllTags = Tags, HasExternalURLs)

table_posts$Tags <- sapply(table_posts$AllTags, function(tag_list) {
  if (length(tag_list) == 1 && is.na(tag_list)) return(NA)
  
  links <- sapply(tag_list, function(tag) {
    sprintf("<a href='https://bsky.app/hashtag/%s' target='_blank'>%s</a>", tag, tag)
  })
  
  # Join multiple tags with commas and spaces
  paste(links, collapse=", ")
})

# table_posts <- table_posts |>
#  select(-AllTags)

data.table::setDT(table_posts)
table_posts[, CreatedDate := as.Date(table_posts$CreatedAt)]
setindex(table_posts, CreatedDate)
setindex(table_posts, Author)
saveRDS(table_posts, conference_file_path)













