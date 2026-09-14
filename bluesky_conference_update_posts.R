

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
  # No auth() here: the one call at the top of this script is enough, and
  # Bluesky rate-limits log-ins (createSession) per account

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


### Check to make sure authors don't have #nobot #nobots or require sign-in to view posts

all_posting_accounts <- sort(unique(all_recent_posts$By))


check_account <- function(acct) {
  user_info <- tryCatch({
    atrrr::get_user_info(acct)
  }, error = function(e) {
    NULL
  })

  bio <- tolower(user_info$actor_description)
  no_bots <- grepl("#nobots?\\b", bio)

  bsky_labels <- user_info$labels

  if(length(bsky_labels[[1]]) > 0  ) {
    # atrrr returns a single label as one record but 2+ labels as a list of
    # records, so flatten them all and look for the label value anywhere
    vals <- unlist(bsky_labels)

    protected <- any(!is.na(vals) & vals %in% c("!no-unauthenticated", "no-unauthenticated"))
  } else {
    protected <- FALSE
  }


  results <- dplyr::tibble(Account = acct, NoBots = no_bots, Protected = protected)
  return(results)

}

if(file.exists(file.path(working_directory, "test_df.Rds"))) {
  test_df <- readRDS(file.path(working_directory, "test_df.Rds"))
} else {
  # Empty table instead of NULL so a first run with no posts yet doesn't crash
  test_df <- dplyr::tibble(Account = character(), NoBots = logical(), Protected = logical())
}

# Only look up accounts that haven't been checked before. An account whose
# lookup failed isn't in test_df, so it gets retried on the next run.
new_posting_accounts <- setdiff(all_posting_accounts, test_df$Account)

if(length(new_posting_accounts) > 0) {
  new_test_df <- purrr::map(new_posting_accounts, check_account) |>
    bind_rows()
  # distinct() also clears out duplicate rows piled up by earlier versions of this script
  test_df <- bind_rows(new_test_df, test_df) |>
    distinct(Account, .keep_all = TRUE)
  saveRDS(test_df, file.path(working_directory, "test_df.Rds"))
}

accounts_to_remove <- test_df |>
  filter(NoBots | Protected) |>
  unique() |>
  pluck("Account")

accounts_to_remove <- c(accts_to_remove_manually, accounts_to_remove)

### End check




deduped_recent_posts <- all_recent_posts |>
  dplyr::distinct(URI, .keep_all = TRUE) |>
  dplyr::filter(!(By %in% accounts_to_remove))

# Combine accts_to_remove_regexp into one pattern, so c("a", "b") drops
# accounts matching either one. An empty "" skips this filter.
remove_pattern <- paste(accts_to_remove_regexp[nzchar(accts_to_remove_regexp)], collapse = "|")
if (nzchar(remove_pattern)) {
  deduped_recent_posts <- deduped_recent_posts |>
    dplyr::filter(!stringr::str_detect(By, remove_pattern))
}



# Check with previous retrieved deduped posts and use newest versions

# If file exists
if (file.exists(file.path(working_directory, stored_post_file)) ) {
  previous_retrieved_posts <- readRDS(file.path(working_directory, stored_post_file) )
  combined_recent_posts <- rbind(previous_retrieved_posts, deduped_recent_posts) |>
    dplyr::group_by(URI) |>
    dplyr::arrange(desc(TimePulled)) |>
    dplyr::slice(1) |>
    dplyr::ungroup() |>
    dplyr::arrange(desc(CreatedAt))
  saveRDS(combined_recent_posts, file.path(working_directory, stored_post_file) )
  
} else {
  saveRDS(deduped_recent_posts, file.path(working_directory, stored_post_file) )
}









# Create a table of the deduped posts with the DT R package.
table_posts <- readRDS(file.path(working_directory, stored_post_file) ) |>
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

data.table::setDT(table_posts)
table_posts[, CreatedDate := as.Date(table_posts$CreatedAt)]
setindex(table_posts, CreatedDate)
setindex(table_posts, Author)
saveRDS(table_posts, file.path(working_directory, conference_file_path) )










