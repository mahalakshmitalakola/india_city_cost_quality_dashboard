# ============================================================================
# India Cities Cost & Quality Dashboard (R Shiny App)
# ============================================================================

library(shiny)
library(tidyverse)
library(ggplot2)
library(scales)
library(corrplot)
library(shinythemes)

# --- GLOBAL DATA LOADING AND PREPROCESSING ---
# NOTE: Place your CSV in the same folder as this app.R file.
# If running from a different location, update the path below accordingly.
df <- read.csv("india_cost_quality_dataset.csv")


# 1. Standardize column names for easier use in Shiny
# FIX: Removed 'allow_dots = TRUE' argument for wider R compatibility
names(df) <- make.names(names(df))

# 2. Define numeric columns
numeric_cols <- df %>% select(-City) %>% colnames()

# 2b. Human-readable label lookup for plot titles and axis labels
clean_labels <- c(
  "Average.Rent..INR.month."  = "Average Rent (INR/month)",
  "Food.Cost..INR.month."     = "Food Cost (INR/month)",
  "Internet.Speed..Mbps."     = "Internet Speed (Mbps)",
  "Healthcare.Rating"         = "Healthcare Rating",
  "Safety.Score"              = "Safety Score",
  "Happiness.Index"           = "Happiness Index"
)

# 3. Define highlight cities for Bivariate Plot (Metro/Major Cities)
highlight_cities <- c("Mumbai", "Delhi", "Bengaluru", "Hyderabad", "Chennai", "Kolkata")

# 4. Create Rent Category for Categorical Analysis (Synchronized with new EDA, made robust with Inf)
df$Rent_Category <- cut(df$Average.Rent..INR.month.,
                        breaks = c(0, 10000, 20000, 35000, Inf),
                        labels = c("Low", "Medium", "High", "Very High"),
                        right = FALSE)

# 5. Define Metro vs Non-Metro
metro_cities <- c("Mumbai", "Delhi", "Bengaluru", "Hyderabad", 
                  "Chennai", "Kolkata", "Pune", "Ahmedabad")
df$City_Type <- ifelse(df$City %in% metro_cities, "Metro", "Non-Metro")

# 6. Calculate correlation matrix globally for faster rendering
# Using where(is.numeric) to be safe against accidental non-numeric columns
cor_matrix <- cor(df %>% select(where(is.numeric)))

# 7. Calculate Metro vs Non-Metro comparison table (wide format for clean display)
comparison_df <- df %>%
  group_by(City_Type) %>%
  summarise(
    `Avg Rent`       = round(mean(Average.Rent..INR.month.), 0),
    `Avg Food`       = round(mean(Food.Cost..INR.month.), 0),
    `Avg Internet`   = round(mean(Internet.Speed..Mbps.), 1),
    `Avg Healthcare` = round(mean(Healthcare.Rating), 2),
    `Avg Safety`     = round(mean(Safety.Score), 2),
    `Avg Happiness`  = round(mean(Happiness.Index), 2),
    .groups = 'drop'
  ) %>%
  rename(`City Type` = City_Type)


# --- UI DEFINITION ---
ui <- navbarPage(
  title = "India City Quality & Cost Dashboard",
  theme = shinytheme("flatly"), # Clean theme
  
  # 0. NEW ABOUT TAB
  tabPanel("About",
           fluidRow(
             column(12, 
                    h3("About This Dashboard"),
                    p("This interactive dashboard is built using R Shiny to conduct an Exploratory Data Analysis (EDA) on the 'India Cities Cost & Quality Dataset'. The goal is to visualize key relationships between cost-of-living metrics and quality-of-life metrics across major Indian cities."),
                    hr(),
                    
                    h4("Data & Metrics"),
                    tags$ul(
                      tags$li(strong("Cost Metrics:"), "Average Rent (INR/month) and Food Cost (INR/month)."),
                      tags$li(strong("Quality Metrics:"), "Happiness Index, Safety Score, Healthcare Rating, and Internet Speed (Mbps).")
                    ),
                    
                    h4("Methods & Features"),
                    p("The analysis incorporates several statistical and visualization techniques:"),
                    tags$ul(
                      tags$li(strong("Univariate Analysis:"), "Histograms and Boxplots allow you to analyze the distribution and detect outliers for any single variable."),
                      tags$li(strong("Correlation Analysis:"), "A heatmap shows the strength and direction of linear relationships between all numeric variables."),
                      tags$li(strong("Bivariate Analysis:"), "The Custom Scatter Plot is highly interactive. You can select the X and Y variables, apply a ", strong("Log10 transformation"), " to the X-axis, and see the linear trend. Major metropolitan areas are highlighted in red for visual emphasis.")
                    )
             )
           )
  ),
  
  # 1. HOME/OVERVIEW TAB
  tabPanel("Overview & Summary",
           fluidRow(
             column(12, 
                    h3("Dataset Structure and Key Statistics"),
                    p("This tab provides the foundational data overview and statistics."),
                    hr()
             )
           ),
           fluidRow(
             column(6, 
                    h4("Summary Statistics"),
                    verbatimTextOutput("summary_stats")
             ),
             column(6, 
                    h4("Metro vs Non-Metro Comparison"),
                    tableOutput("metro_comparison")
             )
           )
  ),
  
  # 2. UNIVARIATE ANALYSIS TAB
  tabPanel("Distributions",
           sidebarLayout(
             sidebarPanel(
               h4("Univariate Analysis"),
               # Interactive Control 1
               selectInput(inputId = "uni_var",
                           label = "Select Variable to Analyze:",
                           choices = setNames(names(clean_labels), clean_labels),
                           selected = "Happiness.Index"),
               width = 3
             ),
             mainPanel(
               fluidRow(
                 column(6, plotOutput("histogram_plot")),
                 column(6, plotOutput("boxplot_plot"))
               ),
               width = 9
             )
           )
  ),
  
  # 3. BIVARIATE SCATTER PLOT TAB
  tabPanel("Bivariate Scatter Plots",
           sidebarLayout(
             sidebarPanel(
               h4("Custom Scatter Plot Controls"),
               # Interactive Control 2
               selectInput(inputId = "x_var",
                           label = "Select X-Axis Variable:",
                           choices = setNames(names(clean_labels), clean_labels),
                           selected = "Average.Rent..INR.month."),
               # Interactive Control 3
               selectInput(inputId = "y_var",
                           label = "Select Y-Axis Variable:",
                           choices = setNames(names(clean_labels), clean_labels),
                           selected = "Happiness.Index"),
               # Interactive Control 4
               checkboxInput(inputId = "log_x", 
                             label = "Apply Log10 to X-Axis (Recommended for Rent/Cost)", 
                             value = TRUE),
               width = 3
             ),
             mainPanel(
               plotOutput("bivariate_scatter", height = "550px"),
               width = 9
             )
           )
  ),
  
  # 4. RANKINGS AND CORRELATION TAB (New sidebarLayout applied here)
  tabPanel("Rankings & Correlation",
           sidebarLayout(
             sidebarPanel(
               h4("Ranking Controls"),
               # New interactive control (Slider)
               sliderInput(inputId = "top_n", 
                           label = "Number of Top Cities to Display:",
                           min = 5, max = min(20, nrow(df)), value = 10, step = 1),
               width = 3
             ),
             mainPanel(
               fluidRow(
                 column(6, h4("Top Cities by Rent"), plotOutput("top_rent_plot")),
                 column(6, h4("Top Happiest Cities"), plotOutput("top_happy_plot"))
               ),
               fluidRow(
                 column(12, h4("Variable Correlation Heatmap"), plotOutput("corr_heatmap", height = "550px"))
               ),
               width = 9
             )
           )
  )
)


# --- SERVER LOGIC ---
server <- function(input, output) {
  
  # Tab 1: Overview & Summary Outputs
  output$summary_stats <- renderPrint({
    summary(df)
  })
  
  output$metro_comparison <- renderTable({
    comparison_df
  }, striped = TRUE, bordered = TRUE, digits = 2)
  
  
  # Tab 2: Univariate Analysis Outputs
  output$histogram_plot <- renderPlot({
    req(input$uni_var)
    ggplot(df, aes(x = .data[[input$uni_var]])) +
      geom_histogram(bins = 20, fill = "steelblue", color = "white") +
      labs(title = paste("Distribution of", clean_labels[input$uni_var]), x = clean_labels[input$uni_var]) +
      theme_minimal()
  })
  
  output$boxplot_plot <- renderPlot({
    req(input$uni_var)
    ggplot(df, aes(y = .data[[input$uni_var]], x = 1)) +
      geom_boxplot(fill = "lightgreen", color = "darkgreen") +
      labs(title = paste("Boxplot of", clean_labels[input$uni_var]), x = "", y = clean_labels[input$uni_var]) +
      coord_flip() +
      theme_minimal() +
      theme(axis.text.y = element_blank())
  })
  
  
  # Tab 3: Bivariate Scatter Plot Output (Stylized)
  output$bivariate_scatter <- renderPlot({
    req(input$x_var, input$y_var)
    
    # Fix 9: Guard against same variable selected for both axes
    validate(
      need(input$x_var != input$y_var, "Please select different variables for the X and Y axes.")
    )
    
    # Calculate correlation for subtitle
    corr_val <- round(cor(df[[input$x_var]], df[[input$y_var]]), 3)
    
    # Fix 7: Use clean human-readable labels for axis titles and plot title
    x_label <- clean_labels[input$x_var]
    y_label <- clean_labels[input$y_var]
    
    # Base Plot — Fix 1: use .data[[]] instead of aes_string()
    p <- ggplot(df, aes(x = .data[[input$x_var]], y = .data[[input$y_var]])) +
      geom_point(aes(size = Safety.Score,
                     color = ifelse(City %in% highlight_cities, "Metro", "Other")),
                 alpha = 0.7) +
      # Fix 8: Consistent color for non-highlighted points (no fragile column-name logic)
      scale_color_manual(
        values = c("Metro" = "red", "Other" = "steelblue"),
        name = "City Type",
        guide = "none"
      ) +
      geom_smooth(method = "lm", color = "purple", se = FALSE, linetype = "solid") +
      labs(
        title    = paste(x_label, "vs.", y_label),
        subtitle = paste("Pearson Correlation:", corr_val),
        x        = x_label,
        y        = y_label,
        size     = "Safety Score"
      ) +
      theme_bw(base_size = 14) +
      theme(
        plot.title    = element_text(face = "bold", hjust = 0.5),
        plot.subtitle = element_text(hjust = 0.5, color = "darkgrey"),
        legend.position = "right"
      )
    
    # Apply Log Scale if checked
    if (input$log_x) {
      if (min(df[[input$x_var]]) > 0) {
        p <- p + scale_x_log10(labels = scales::comma) +
          labs(x = paste(x_label, "(Log10 Scale)"))
      } else {
        p <- p + labs(caption = "Note: Log scale not applied — data contains zero or negative values.")
      }
    }
    
    p
  })
  
  
  # Tab 4: Rankings and Correlation Outputs
  output$top_rent_plot <- renderPlot({
    # Use input$top_n to dynamically determine how many cities to show
    req(input$top_n)
    top_rent <- df %>% arrange(desc(Average.Rent..INR.month.)) %>% head(input$top_n)
    ggplot(top_rent, aes(x = reorder(City, Average.Rent..INR.month.), 
                         y = Average.Rent..INR.month.)) +
      geom_bar(stat = "identity", fill = "coral") +
      coord_flip() +
      labs(title = paste("Top", input$top_n, "Cities by Average Rent"),
           x = "City", y = "Average Rent (INR/month)") +
      theme_minimal()
  })
  
  output$top_happy_plot <- renderPlot({
    # Use input$top_n to dynamically determine how many cities to show
    req(input$top_n)
    top_happy <- df %>% arrange(desc(Happiness.Index)) %>% head(input$top_n)
    ggplot(top_happy, aes(x = reorder(City, Happiness.Index), 
                          y = Happiness.Index)) +
      geom_bar(stat = "identity", fill = "gold") +
      coord_flip() +
      labs(title = paste("Top", input$top_n, "Happiest Cities"),
           x = "City", y = "Happiness Index") +
      theme_minimal()
  })
  
  output$corr_heatmap <- renderPlot({
    corrplot(cor_matrix, 
             method = "color", 
             type = "upper",
             addCoef.col = "black",
             number.cex = 0.7,
             tl.col = "black",
             tl.srt = 45,
             title = "Correlation Heatmap of Variables",
             mar = c(0, 0, 2, 0))
  })
}

# Run the application
shinyApp(ui = ui, server = server)
