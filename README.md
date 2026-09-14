# Project to create a Shiny app displaying up-to-date posts with conference hashtags

This repo has files to download and wrangle Bluesky posts with one or more hashtag(s), and then display them in a searchable Shiny app. This is very similar to the code that was running my [posit::conf(2025) Posts on Bluesky Shiny app](https://apps.machlis.com/shiny/positconf2025/). (I do have an updated app running somewhat different code for [posit::conf(2026)](https://apps.machlis.com/shiny/positconf2026/).

## Configuration files you need to update with your project's info

`sample_update_conf_posts.R` shows a sample configuration file for retrieving and wrangling posts by hashtag. Change values as appropriate for your conference, directory structure, and file names. It sources `bluesky_conference_update_posts.R`, with most of the R code for this task.

The configuration variables include `accts_to_remove_manually` for anyone you know wouldn't want to be included, as well as `accts_to_remove_regexp` if you know you want to block a domain such as the bridge from Mastodon to Bluesky. The update code automatically checks for users who have `#nobot` or `#nobots` in their profiles, as well as a label for requiring Bluesky log-in to view their posts and should exclude all such users.

This project uses the atrrr package to interface with Bluesky in R. **You need to authenticate with a Bluesky app user name and password in atrrr -- which is not the same as your Bluesky account user name and password -- and store an authentication token**. Please see [https://jbgruber.github.io/atrrr/articles/Basic_Usage.html#authentication](https://jbgruber.github.io/atrrr/articles/Basic_Usage.html#authentication) if you need help with this. The update script reads your app user name and app password from the `BLUESKY_APP_USER` and `BLUESKY_APP_PASS` environment variables, for example in your `.Renviron` file.

This code was last tested in September 2026 with atrrr 0.2.0 (the current CRAN release) and httr2 1.3.0.

The update script also uses dplyr, purrr, tidyr, stringr, glue, and data.table. The Shiny app uses shiny, DT, bslib, bsicons, memoise, dplyr, and data.table. To install everything:

```r
install.packages(c("atrrr", "dplyr", "purrr", "tidyr", "stringr", "glue", "data.table",
                   "shiny", "DT", "bslib", "bsicons", "memoise"))
```

The update script saves the results of its account checks in `test_df.Rds` in your working directory, so each account is only looked up once. Older versions of this code also wrote an `existing_posting_accounts.Rds` file. It's no longer used, and you can delete it.

`app_config.R` -- You'll need to set five variables: `conference_name` (for the app title and a few other things), `conference_name_no_spaces` (for use in download file name), `file_with_data` (where the data wrangled for the app table is stored.), `about_text` for the "About this app" text in the FAQ, and `how_often_updated_text` for the FAQ info about how often the data is updated.

## Files you need a copy of in each directory with a conference app

`app.R` -- You need one copy of this in each directory where you want a Shiny app, even though you don't need to configure anything here. 

## Files with the main project code

You shouldn't have to touch either of these, unless you want to customize how they work. You only need one copy of each, regardless of how many different projects/conferences/apps you want to use.

`bluesky_conference_update_posts.R` is the file with a function and other R code for retrieving and wrangling the posts. If I was serious about this, I would have made this a function in an R package . . . and maybe I will if I ever have more time and patience to devote to this. You only need one copy of this for multiple conferences; `sample_update_conf_posts.R` (or whatever you name each one) in each project directory will pull main code from here.

`bluesky_conference_app.R` -- this is the main code for the Shiny app, including ui, server, and bslib theme.







