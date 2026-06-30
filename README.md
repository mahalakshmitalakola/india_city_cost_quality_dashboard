# india_city_cost_quality_dashboard
An R Shiny dashboard which explores rent, food cost, safety, healthcare, and happiness metrics across Indian cities, with interactive distributions, scatter plots, and rankings.

# India City Quality & Cost Dashboard

An interactive R Shiny dashboard exploring the relationship between cost-of-living and quality-of-life metrics across major Indian cities.

## What it does

This dashboard lets you explore an India Cities Cost & Quality dataset through five tabs:

- **About** — overview of the dataset and the methods used.
- **Overview & Summary** — dataset-wide summary statistics and a Metro vs. Non-Metro comparison table.
- **Distributions** — histogram and boxplot for any selected variable, to inspect spread and outliers.
- **Bivariate Scatter Plots** — fully interactive scatter plot with selectable X/Y variables, optional Log10 transform on the X-axis, a linear trend line, and major metro cities highlighted in red.
- **Rankings & Correlation** — adjustable bar charts for top cities by rent and happiness (slider-controlled count), plus a full correlation heatmap of all numeric variables.

## Data

The app expects a CSV file named `india_cost_quality_dataset.csv` in the same directory as `app.R`, containing one row per city with the following columns:

| Column | Description |
|---|---|
| `City` | Name of the city |
| `Average Rent (INR/month)` | Average monthly rental cost |
| `Food Cost (INR/month)` | Average monthly food cost |
| `Internet Speed (Mbps)` | Average internet speed |
| `Healthcare Rating` | Healthcare quality rating |
| `Safety Score` | City safety score |
| `Happiness Index` | Composite happiness/quality-of-life index |

> Note: column names in the raw CSV are sanitized on load via `make.names()`, so spaces and special characters are converted to dots (e.g. `Average Rent (INR/month)` → `Average.Rent..INR.month.`).

## Running locally

1. Clone this repo.
2. Make sure `india_cost_quality_dataset.csv` is in the same folder as `app.R`.
3. Install the required packages (see below).
4. Open `app.R` in RStudio and click **Run App**, or run from the R console:

```r
shiny::runApp("app.R")
```

## Required packages

```r
install.packages(c(
  "shiny",
  "tidyverse",
  "ggplot2",
  "scales",
  "corrplot",
  "shinythemes"
))
```

## Project structure

```
.
├── app.R                              # Main Shiny application
├── india_cost_quality_dataset.csv     # Dataset (must sit alongside app.R)
├── README.md
└── .gitignore
```

## Notes

- The "Metro" classification used throughout the app includes: Mumbai, Delhi, Bengaluru, Hyderabad, Chennai, Kolkata, Pune, and Ahmedabad.
- The "Highlight" cities shown in red on the scatter plot are: Mumbai, Delhi, Bengaluru, Hyderabad, Chennai, and Kolkata.
