# Written with help of Shiny Assistant and Gemini. Refactored for any conference name
# Set in app_config, with examples:

# conference_name <- "posit::conf(2025)"
# conference_name_no_spaces <- "posit_conf_2025"
# file_with_data <- "www/table_posts.Rds"


# parent_directory/app.R

# Define the main Shiny app function, accepting config as an argument
shiny_conference_app <- function(conference_name, conference_name_no_spaces, file_with_data) {
  
  library(shiny)
  library(DT)
  library(bslib)
  library(dplyr)
  library(data.table)
  library(memoise)
  
  my_theme <- bslib::bs_theme( # Theme definition remains the same ...
    version = 5,
    preset = NULL,
    bg = "#f8f9fa",
    fg = "#333",
    primary = "#2980b9",
    base_font = font_google("Inter"),
    heading_font = font_google("Montserrat"),
    font_scale = 0.9
  ) |>
    bslib::bs_add_rules(
      "
      /* Card styling */
      .card {
        border: none;
        box-shadow: 0 2px 4px rgba(0,0,0,0.1);
        transition: box-shadow 0.3s ease;
      }
      .card:hover {
        box-shadow: 0 4px 8px rgba(0,0,0,0.15);
      }
      .card-header {
        background-color: white;
        border-bottom: 2px solid #e9ecef;
        font-family: 'Montserrat', sans-serif;
        font-weight: 600;
      }

      /* Table styling */
      .dataTables_wrapper {
        padding: 1rem;
      }
      .dataTable thead th {
        background-color: #f8f9fa;
        font-weight: 600;
      }
      .dataTable tbody tr:hover {
        background-color: #f1f5f9 !important;
      }

      /* Sidebar styling */
      .sidebar {
        background: linear-gradient(180deg, #ffffff 0%, #f8f9fa 100%);
        border-right: none;
        box-shadow: 2px 0 5px rgba(0,0,0,0.05);
      }

      /* Date range input styling */
      .input-group {
        box-shadow: 0 1px 3px rgba(0,0,0,0.1);
        border-radius: 6px;
      }

      /* Search and filter inputs styling */
      .dataTables_filter input,
      .filterrow input {
        border-radius: 4px !important;
        border: 1px solid #dee2e6 !important;
        padding: 0.375rem 0.75rem !important;
        transition: border-color 0.15s ease-in-out, box-shadow 0.15s ease-in-out;
      }
      .dataTables_filter input:focus,
      .filterrow input:focus {
        border-color: #2980b9 !important;
        box-shadow: 0 0 0 0.2rem rgba(41, 128, 185, 0.25) !important;
      }

  body {
    overflow-y: hidden;
  }.main-container {
    display: flex;
    min-height: 100vh;
  }.sidebar {
    height: 100vh;
    overflow-y: auto; /* Scroll for the entire sidebar */
  }
  #posts_table {
    flex-grow: 1;
    overflow-y: auto;
    display: block;
  }.card-body {
    flex-grow:0;
  }.page-content {
    padding: 20px;
    flex: 1;
    overflow-y: auto;
  }.sidebar-content {
    padding: 20px;
  }

  /*  Allow author list to expand */.author-checkbox-group {
    /* Remove max-height and overflow */
    padding-right: 10px;
    margin-top: 1rem;
  }

  hr {
    margin-top: 0.5rem;    /* Adjust the top margin as needed */
    margin-bottom: 0.5rem; /* Adjust the bottom margin as needed */
  }
      /* Metric card styling */
      .metric-card {
        flex: 1;
        padding: 1.5rem;
        background: linear-gradient(135deg, #3498db, #2980b9);
        border-radius: 0.75rem;
        text-align: center;
        color: white;
        transition: transform 0.2s ease, box-shadow 0.2s ease;
        box-shadow: 0 4px 6px rgba(0, 0, 0, 0.1);
      }
      .metric-card:hover {
        transform: translateY(-2px);
        box-shadow: 0 6px 8px rgba(0, 0, 0, 0.15);
      }
      .metric-title {
        margin: 0;
        color: rgba(255, 255, 255, 0.9);
        font-size: 1rem;
        font-weight: 500;
      }
      .metric-value {
        font-size: 2rem;
        font-weight: bold;
        margin-top: 0.5rem;
      }
      .metric-icon {
        font-size: 1.5rem;
        margin-bottom: 0.5rem;
        opacity: 0.9;
      }

        /* Processing Message Styling */
      .processing-message {
        text-align: center;
        padding: 20px;
        font-style: italic;
        color: #888;
      }
      "
    )
  
  
  # --- UI ---
  ui <- bslib::page_sidebar(
    theme = my_theme,
    window_title = paste(conference_name, "Bluesky posts"), 
    title = div(
      style = "display: flex; flex-direction: column; justify-content: center; align-items: center; width: 100%; gap: 0.5rem;",
      div(
        style = "display: flex; justify-content: center; align-items: center; gap: 1rem;",
        div(
          style = "font-size: 24px; font-family: 'Montserrat', sans-serif; font-weight: 600;",
          uiOutput("dynamic_title")
        ),
        div(
          style = "position: absolute; right: 1rem;",
          actionButton("show_faq", "FAQ",
                       icon = icon("question-circle"),
                       class = "btn-primary"
          )
        )
      ),
      div(
        style = "font-style: italic; font-size: 14px; color: #666; margin-bottom: 0.5rem;",
        textOutput("last_updated")
      )
    ),
    
    tags$head(
      tags$link(rel = "stylesheet", href = "https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0/css/all.min.css"),
      tags$style(HTML("
        body {
          overflow-y: hidden; /* Hide the body scrollbar */
        }
      .main-container {
          display: flex;
          min-height: 100vh;
        }
      .sidebar {
          height: 100vh;
          overflow-y: auto;
        }
        #posts_table {
          flex-grow: 1;
          overflow-y: auto;
          display: block;
        }
      .card-body {
          flex-grow:0;
        }
      .page-content {
          padding: 20px;
          flex: 1;
          overflow-y: auto;  /* Add scrollbar to the main content area */
        }
      .sidebar-content {
          padding: 20px;
        }
      "))
    ),
    
    sidebar = sidebar(
      class = "sidebar-content",
      dateRangeInput("date_range",
                     "Select Date Range",
                     start = NULL,
                     end = NULL,
                     format = "yyyy-mm-dd"
      ),
      
      checkboxInput("has_url",
                    "Show only posts with external URLs",
                    value = FALSE
      ),
      
      hr(),
      
      div(
        style = "display: flex; flex-wrap: wrap; justify-content: flex-start; align-items: flex-start; margin-bottom: 1rem;",
        h5("Filter by Authors", style = "margin: 0 0 0.5rem 0; width: 100%;"),
        div(
          style = "display: flex; gap: 0.5rem; justify-content: flex-end;",
          actionButton("select_all", "Select All", class = "btn-sm"),
          actionButton("clear_all", "Clear All", class = "btn-sm")
        )
      ),
      
      div(
        class = "author-checkbox-group",
        checkboxGroupInput("selected_authors",
                           label = NULL,
                           choices = NULL,
                           selected = NULL
        )
      ),
      
      downloadButton("download_data", "Download Current Data",
                     class = "btn-primary w-100"
      ),
      
      br(),
      br(),
      tags$small(
        style = "color: #666; font-style: italic;",
        "Use the filters above to narrow down the posts shown in the table."
      )
    ),
    
    div(class = "main-container",
        div(class = "page-content",
            div(
              style = "display: flex; gap: 1.5rem; margin-bottom: 1.5rem;",
              # --- Total Posts Card ---
              div(
                class = "metric-card",
                style = "background: linear-gradient(135deg, #3498db, #2980b9);",
                tags$i(class = "fas fa-newspaper metric-icon"),
                h6("Total Posts", class = "metric-title"),
                div(class = "metric-value", textOutput("total_posts"))
              ),
              # --- Unique Authors Card ---
              div(
                class = "metric-card",
                style = "background: linear-gradient(135deg, #2ecc71, #27ae60);",
                tags$i(class = "fas fa-users metric-icon"),
                h6("Unique Authors", class = "metric-title"),
                div(class = "metric-value", textOutput("unique_authors"))
              ),
              # --- Total Likes Card ---
              div(
                class = "metric-card",
                style = "background: linear-gradient(135deg, #9b59b6, #8e44ad);",
                tags$i(class = "fas fa-heart metric-icon"),
                h6("Total Likes", class = "metric-title"),
                div(class = "metric-value", textOutput("total_likes"))
              )
            ),
            
            card(
              card_header("Browse and search posts (regular expressions work). Click >> at end of text to view original post on Bluesky."),
              uiOutput("table_ui")
            )
        )
    )
  )
  
  # --- Server ---
  server <- function(input, output, session) {
    
    # --- Memoized Data Loading ---
    load_data <- memoise::memoise(function(file_path) {
      message("Loading data from disk...")  # For debugging
      readRDS(file_path)
    })
    
    table_posts <- shiny::reactiveFileReader(
      intervalMillis = 900000,
      session = session,
      filePath = file_with_data, 
      readFunc = load_data
    )
    
    # --- Author Checkbox Updates ---
    last_authors <- shiny::reactiveVal(NULL)
    
    shiny::observe({
      df <- data.table::data.table(table_posts())
      req(nrow(df) > 0)
      
      if (!is.null(input$date_range[1])) {
        df <- df[CreatedDate >= input$date_range[1] & CreatedDate <= input$date_range[2]]
      }
      
      authors <- sort(unique(df$Author))
      
      if (!identical(authors, last_authors())) {
        last_authors(authors)
        if (is.null(input$selected_authors)) {
          shiny::updateCheckboxGroupInput(session, "selected_authors",
                                   choices = authors,
                                   selected = authors
          )
        } else {
          shiny::updateCheckboxGroupInput(session, "selected_authors",
                                   choices = authors
          )
        }
      }
    })
    
    shiny::observeEvent(input$select_all, {
      df <- data.table(table_posts())
      authors <- df[, sort(unique(Author))]
      shiny::updateCheckboxGroupInput(session, "selected_authors",
                               selected = authors
      )
    })
    
    shiny::observeEvent(input$clear_all, {
      updateCheckboxGroupInput(session, "selected_authors",
                               selected = character(0)
      )
    })
    
    # --- Date Range Update ---
    shiny::observe({
      df <- data.table(table_posts())
      updateDateRangeInput(session, "date_range",
                           start = min(df$CreatedAt),
                           end = max(df$CreatedAt)
      )
    })
    
    # --- Dynamic Title ---
    output$dynamic_title <- shiny::renderUI({
      start_date <- format(input$date_range[1], "%b. %d")
      end_date <- format(input$date_range[2], "%b. %d")
      sprintf(paste(conference_name, "Posts on Bluesky from %s to %s"), start_date, end_date) 
    })
    
    # --- Filtered Data (with isolation and req) ---
    filtered_data <- shiny::reactive({
      req(table_posts())
      df <- data.table(isolate(table_posts()))
      
      df <- df[CreatedDate >= input$date_range[1] & CreatedDate <= input$date_range[2]]
      
      if (input$has_url) {
        df <- df[HasExternalURLs == TRUE]
      }
      
      if (!is.null(input$selected_authors) && length(input$selected_authors) > 0) {
        df <- df[Author %in% input$selected_authors]
      }
      
      return(df)
    })
    
    # --- Total Posts (using renderText) ---
    output$total_posts <- renderText({
      nrow(filtered_data())
    })
    
    # --- Unique Authors (using renderText) ---
    output$unique_authors <- renderText({
      uniqueN(filtered_data()$Author)
    })
    
    # --- Data Table UI (Conditional Rendering) ---
    output$table_ui <- renderUI({
      if (is.null(table_posts())) {
        # Display the "Processing..." message
        p("Processing . . . .", class = "processing-message")
      } else {
        # Render the DataTable output
        DT::dataTableOutput("posts_table")
      }
    })
    
    # --- Data Table (server-side) ---
    output$posts_table <- DT::renderDataTable({
      req(filtered_data())
      
      hide_cols <- which(names(filtered_data()) %in% c("AllTags", "HasExternalURLs", "CreatedDate")) - 1
      created_at_col <- which(names(filtered_data()) == "CreatedAt") - 1
      
      DT::datatable(
        filtered_data(),
        rownames = FALSE,
        escape = FALSE,
        filter = 'top',
        options = list(
          pageLength = 25, #Or another suitable page length
          autoWidth = TRUE,  # Important for responsive width
          search = list(regex = TRUE),
          searchHighlight = TRUE,
          lengthMenu = c(25, 50, 75, 100, 250),
          order = list(list(created_at_col, 'desc')),
          columnDefs = list(
            list(targets = hide_cols, visible = FALSE),
            list(
              targets = 3,  # zero-indexed column number; change as needed
              orderSequence = c("desc", "asc")
            ),
            list(
              targets = 4,  # zero-indexed column number; change as needed
              orderSequence = c("desc", "asc")
            ),
            list(
              targets = 5,  # zero-indexed column number; change as needed
              orderSequence = c("desc", "asc")
            )
          ),
          dom = 'lfrtip', # Include pagination controls
          deferRender = TRUE
          # Removed scrollY and scroller
        )
      )
    }, server = TRUE)
    
    # --- Download Handler ---
    output$download_data <- downloadHandler(
      filename = function() {
        paste0(conference_name_no_spaces, "_posts_", format(Sys.Date(), "%Y%m%d"), ".csv") 
      },
      content = function(file) {
        df <- filtered_data()
        cols_to_keep <- setdiff(names(df), c("AllTags", "HasExternalURLs", "CreatedDate"))
        df_to_save <- df[, ..cols_to_keep]
        fwrite(df_to_save, file)
      }
    )
    
    # --- FAQ Modal ---
    shiny::observeEvent(input$show_faq, {
      shiny::showModal(modalDialog(
        title = "Frequently Asked Questions",
        div(
          h4("About this App", class = "faq-question"),
          about_text,
          
          h4("How often is the data updated?", class = "faq-question"),
          how_often_updated_text,
          
          h4("Can I download the data?", class = "faq-question"),
          p(
            "Yes! You can download the currently filtered data using the download button in the sidebar.",
            class = "faq-answer"
          )
        ),
        size = "l",
        easyClose = TRUE,
        footer = modalButton("Close")
      ))
    })
    
    
    # --- Total Likes (using renderText) ---
    output$total_likes <- shiny::renderText({
      sum(filtered_data()$Likes, na.rm = TRUE)
    })
    
    # --- Last Updated ---
    output$last_updated <- shiny::renderText({
      file_info <- file.info(file_with_data) 
      paste("Last updated", format(file_info$mtime, "%b. %d, %Y %H:%M UTC"))
    })
  }
  
  shinyApp(ui, server) # No change here as ui and server are defined within the function
}