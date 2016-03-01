###
### Project:  NFL Sports Analytics
###
### Url:      http://www.kalisch.biz
###
### File:     ColleyScore.R
###
### Author:   Dominik P.H. Kalisch (dkalisch@trinty.edu)
###
### Desc.:    This script calculates the Colley scores for a given set of teams
###
###
### Modification history
### ----------------------------------------------------------------------------
###
### Date        Version   Who                 Description
### 2016-02-09  0.1       Dominik Kalisch     initial build
###
### Needed R packages:  dplyr
###                     fBasics
###                 
###

# Load library
library(dplyr) # Data gathering and manipulation
library(fBasics) # Havyside function

# Get data
## Open connection to data base
nfl.db <- src_postgres(dbname = "nfl", host = "localhost", user = "dominik")
nfl <- tbl(nfl.db, "scores")

## Request a time frame from the data base
nfl.df <- nfl %>%
  dplyr::filter(Date >= "2015-06-01",
                Date < "2016-05-31") %>%
  collect()

# Prepare data for the calculations
## Set team names to factors for sorting in matrix
nfl.df$Home <- as.factor(nfl.df$Home)
nfl.df$Away <- as.factor(nfl.df$Away)

## Split data into regular season and playoffs 
nflReg <- suppressWarnings(nfl.df[!is.na(as.numeric(nfl.df$Week)),])
nflPO <- anti_join(nfl.df, nflReg, by = "Week")

## Define a wight
w <- Heaviside(as.numeric(nflReg$Week)-2.5) + 1

# Create a incidence matrix
## Start with an empty matrix
A <- matrix(nrow = nlevels(nflReg$Home), ncol = nlevels(nflReg$Home), 0)

## Compare results of home and away team and set set 1 for the winner
## where is row the home team and column the away team with the index number
## equal to the factor of the variable.
for(i in 1:nrow(nflReg)){
  # Get the position of the current team in the matrix
  a <- as.numeric(nflReg$Home[i])
  b <- as.numeric(nflReg$Away[i])
  
  # Fill in the values
  if(nflReg$PtsH[i] > nflReg$PtsA[i]){
    A[a, b] <- A[a, b] + 1 * w[i] 
  } else if(nflReg$PtsH[i] < nflReg$PtsA[i]){
    A[b, a] <- A[b, a] + 1 * w[i]
  } else {
    A[a, b] <- A[a, b] + 0.5 * w[i]
    A[b, a] <- A[b, a] + 0.5 * w[i]
  }
}

# Colley Calculations
## Create colley matrix
colley.m <- -(A + t(A)) + diag(rowSums(A) + colSums(A) + 2)

## Create result data frame
colley.r <- data_frame(TeamID = levels(sort(nflReg$Home)), # Name of the team
                       Wins = rowSums(A), # How many wins
                       Loss = colSums(A), # How many loss
                       WinP = rowSums(A) / (Wins + Loss), # win-loss ratio
                       Colley = solve(colley.m, (0.5 * (rowSums(A) - colSums(A)) + 1)) # solved colley equation
)

# Predict playoff's 
## Look up the win-loss ratio and the colley ratio and add them to the playoff data frame
nflPO <- colley.r %>%
  dplyr::select(TeamID, WinP, Colley) %>%
  dplyr::left_join(x = nflPO, by = c("Home" = "TeamID"))
nflPO <- colley.r %>%
  dplyr::select(TeamID, WinP, Colley) %>%
  dplyr::left_join(x = nflPO, by = c("Away" = "TeamID"))
names(nflPO) <- c(names(nfl.df), "WinPH", "ColleyH", "WinPA", "ColleyA") # Update names for better readability


