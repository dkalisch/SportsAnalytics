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
### Needed R packages:  XLConnect
###                     dplyr
###
### Needed R files: connectDB.R
###                 lubridate
###

# Load DB connector if not there
if(!exists("nfl.db")){
  source("src/connectDB.R")
}

# Load required libraries
options(java.parameters = "-Xmx4g" )
library(XLConnect) # For reading in Excel files
library(lubridate) # For manipulating dates

# Set up years to read in
years <- as.character(c(1966:2014))

# Read data from xlsx file
for(i in years){
  print(i)
  print("Read file...")
  nfl <- readWorksheetFromFile(file = "data/NFL_Reference.xlsx", sheet = i) # Read file
  
  print("Clean up data...")
  
  ## Clean up data
  ### Remove additional headlines
  nfl <- nfl[- grep("Date", nfl$Date), ]
  if(!is.null(grep("Playoffs", nfl$Date))){
    nfl <- nfl[- grep("Playoffs", nfl$Date), ]
  }
  
  ### Set correct variable types
  nfl$Week <- as.numeric(nfl$Week)
  
  nfl$PtsW <- as.numeric(nfl$PtsW)
  nfl$PtsL <- as.numeric(nfl$PtsL)
  nfl$YdsW <- as.numeric(nfl$YdsW)
  nfl$TOW <- as.numeric(nfl$TOW)
  nfl$YdsL <- as.numeric(nfl$YdsL)
  nfl$TOL <- as.numeric(nfl$TOL)
  nfl$Date <- as.Date(nfl$Date)
  year(nfl$Date) <- as.numeric(i)
  
  print("Recode data...")
  
  ## Recode data
  ### Add new variables to code away vs. home
  nfl$Home <- NA
  nfl$Away <- NA
  nfl$PtsH <- NA
  nfl$PtsA <- NA
  nfl$YdsH <- NA
  nfl$TOH  <- NA
  nfl$YdsA <- NA
  nfl$TOA  <- NA
  
  ### Switch team names and results according to game location
  for(j in 1:nrow(nfl)){
    if(!is.na(nfl$Col6[j])){
      nfl$Home[j] <- nfl$Loser.tie[j]
      nfl$PtsH[j] <- nfl$PtsL[j]
      nfl$Away[j] <- nfl$Winner.tie[j]
      nfl$PtsA[j] <- nfl$PtsW[j]
      nfl$YdsH[j] <- nfl$YdsL[j]
      nfl$TOH[j] <- nfl$TOL[j]
      nfl$YdsA[j] <- nfl$YdsW[j]
      nfl$TOA[j] <- nfl$TOW[j]
    } else {
      nfl$Home[j] <- nfl$Winner.tie[j]
      nfl$PtsH[j] <- nfl$PtsW[j]
      nfl$Away[j] <- nfl$Loser.tie[j]
      nfl$PtsA[j] <- nfl$PtsL[j]
      nfl$YdsH[j] <- nfl$YdsW[j]
      nfl$TOH[j] <- nfl$TOW[j]
      nfl$YdsA[j] <- nfl$YdsL[j]
      nfl$TOA[j] <- nfl$TOL[j]
    }
  }
  
  ### Remove unessesary columns
  nfl$Col4 <- NULL
  nfl$Col6 <- NULL
  nfl$Day <- NULL
  nfl$Winner.tie <- NULL
  nfl$Loser.tie <- NULL
  nfl$PtsW <- NULL
  nfl$PtsL <- NULL
  nfl$YdsW <- NULL
  nfl$YdsL <- NULL
  nfl$TOW <- NULL
  nfl$TOL <- NULL
  
  print("Write file to DB...")
  
  ## Write data to db
  dbWriteTable(nfl.db, name = "scores", nfl, append = TRUE)
  
  if(i == tail(years, n = 1)){
    print("Finished!")
  } else {
    print("Next...")
  }
}

# Disconnect from db
dbDisconnect(nfl.db)
