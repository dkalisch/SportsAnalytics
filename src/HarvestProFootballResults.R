###
### Project:  NFL Sports Analytics
###
### Url:      http://www.kalisch.biz
###
### File:     HarvestProFootballResults.R
###
### Author:   Dominik P.H. Kalisch (dkalisch@trinty.edu)
###
### Desc.:    This script scrapes the data from pro-football-reference.com
###           and saves the results in a postgres database.
###           Currently only the game results are scraped and saved.
###
###
### Modification history
### ----------------------------------------------------------------------------
###
### Date        Version   Who                 Description
### 2015-12-03  0.1       Dominik Kalisch     initial build
###
### Needed R packages:  XML
###                     dplyr
###
### Needed R files: connectDB.R
###

# Initial settings
initialSetup <- FALSE # Change to TRUE to load the PostgresSQL database nfl
startYear <- 1966
currentYear <- as.numeric(format(Sys.Date(), "%Y"))

# Load needded libraries
library(XML) # For scraping the HTML tables
library(dplyr) # Data manipulation library
library(RPostgreSQL) # Driver for PostgreSQL
library(stringi) # Provides a host of string opperations

# Load DB connector if not there
if(!exists("nfl.db")){
  source("src/connectDB.R")
} else if (!isPostgresqlIdCurrent(nfl.db)) { # Check for stale connection
  source("src/connectDB.R")
}

# Build vector of years to parse
if (initialSetup == TRUE){
  years <- c(startYear:currentYear)
} else {
  years <- c(currentYear)
}

# Harvest data
for (i in 1:length(years)){
  ## Define the link to the data
  url.pro.football <- stri_c("http://www.pro-football-reference.com/years/",
                             years[i], "/games.htm")

  ## Get the raw HTML data
  tables <- readHTMLTable(url.pro.football, header = TRUE, 
                          stringsAsFactors = FALSE)
  df.games <- tables[["games"]]
  if (is.null(df.games)) # Sometimes a year (for example, current year)
    next                 # is empty
  df.games_left <- tables[["games_left"]]

  print("Clean up data...")

  ## Clean up data
  ### Remove additional headlines, playoff games, by week, and blank lines
  df.games <- suppressWarnings(df.games[
    !is.na(as.numeric(as.character(df.games$Week))), ])
  df.games <- df.games[df.games[,4] != "", ]

  ### Add missing header names
  names(df.games) <- c("Week", "Day", "Date", "Col4", "Winner/tie", "Col6", "Loser/tie",
                       "PtsW", "PtsL", "YdsW", "TOW", "YdsL", "TOL")

  ### Set correct variable types
  df.games$Week <- as.numeric(df.games$Week)
  df.games$PtsW <- as.numeric(df.games$PtsW)
  df.games$PtsL <- as.numeric(df.games$PtsL)
  df.games$YdsW <- as.numeric(df.games$YdsW)
  df.games$TOW <- as.numeric(df.games$TOW)
  df.games$YdsL <- as.numeric(df.games$YdsL)
  df.games$TOL <- as.numeric(df.games$TOL)
  df.games$Date <- as.Date(paste(df.games$Date, years[i], sep = ", "), "%B %d, %Y")
  df.games$`Winner/tie` <- as.character(df.games$`Winner/tie`)
  df.games$`Loser/tie` <- as.character(df.games$`Loser/tie`)

  print("Recode data...")

  ## Recode data
  ### Add new variables to code away vs. home
  df.games$Home <- NA
  df.games$Away <- NA
  df.games$PtsH <- NA
  df.games$PtsA <- NA
  df.games$YdsH <- NA
  df.games$TOH  <- NA
  df.games$YdsA <- NA
  df.games$TOA  <- NA

  ### Switch team names and results according to game location
    df.games$Home[asterisk] <- df.games$`Loser/tie`[asterisk]
    df.games$PtsH[asterisk] <- df.games$PtsL[asterisk]
    df.games$Away[asterisk] <- df.games$`Winner/tie`[asterisk]
    df.games$PtsA[asterisk] <- df.games$PtsW[asterisk]
    df.games$YdsH[asterisk] <- df.games$YdsL[asterisk]
    df.games$TOH[asterisk] <- df.games$TOL[asterisk]
    df.games$YdsA[asterisk] <- df.games$YdsW[asterisk]
    df.games$TOA[asterisk] <- df.games$TOW[asterisk]

    df.games$Home[!asterisk] <- df.games$`Winner/tie`[!asterisk]
    df.games$PtsH[!asterisk] <- df.games$PtsW[!asterisk]
    df.games$Away[!asterisk] <- df.games$`Loser/tie`[!asterisk]
    df.games$PtsA[!asterisk] <- df.games$PtsL[!asterisk]
    df.games$YdsH[!asterisk] <- df.games$YdsW[!asterisk]
    df.games$TOH[!asterisk] <- df.games$TOW[!asterisk]
    df.games$YdsA[!asterisk] <- df.games$YdsL[!asterisk]
    df.games$TOA[!asterisk] <- df.games$TOL[!asterisk]

  ### Remove unessesary columns
  df.games$Col4 <- NULL
  df.games$Col6 <- NULL
  df.games$Day <- NULL
  df.games$`Winner/tie` <- NULL
  df.games$`Loser/tie` <- NULL
  df.games$PtsW <- NULL
  df.games$PtsL <- NULL
  df.games$YdsW <- NULL
  df.games$YdsL <- NULL
  df.games$TOW <- NULL
  df.games$TOL <- NULL

  ## If run in update mode, get the last db entry and only add new data
  if (initialSetup == FALSE){
    sql <- "select \"Date\", \"Home\" from scores WHERE \"Date\" = (select max(\"Date\") from scores);"
    last.results <- fetch(dbSendQuery(nfl.db, sql))
    df.games <- df.games %>%
      filter(Date > max(last.results$Date))
  }

  ## Write data to db
  print("Write data to DB...")
  dbWriteTable(nfl.db, name = "scores", df.games, append = TRUE, row.names = FALSE)

}

# Disconnect from db
dbDisconnect(nfl.db)
