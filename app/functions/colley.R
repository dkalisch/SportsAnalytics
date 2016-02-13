###
### Project:  NFL Sports Analytics
###
### Url:      http://www.kalisch.biz
###
### File:     colley.R
###
### Author:   Dominik P.H. Kalisch (dkalisch@trinty.edu)
###
### Desc.:    This script includes a function, that calculates the Colley scores
###           for a given set of teams
###
###
### Modification history
### ----------------------------------------------------------------------------
###
### Date        Version   Who                 Description
### 2016-02-10  0.1       Dominik Kalisch     initial build
###
### Needed R packages:  dplyr
###                     fBasics
###                 
###
# Load need required libraries
library(fBasics)
library(dplyr)

colley <- function(df, gamma = 1, week = 2){
  # Prepare data for the calculations
  
  suppressWarnings(df$Week[is.na(as.numeric(df$Week))] <- 18)
  
  ## Set team names to factors for sorting in matrix
  df$Home <- as.factor(df$Home)
  df$Away <- as.factor(df$Away)
  
  ## Define a wight
  w <- pmax((Sign(as.numeric(df$Week) - (week-0.5)) * gamma),1)
  
  # Create a incidence matrix
  ## Start with an empty matrix
  A <- matrix(nrow = nlevels(df$Home), ncol = nlevels(df$Home), 0)
  
  ## Compare results of home and away team and set set 1 for the winner
  ## where is row the home team and column the away team with the index number
  ## equal to the factor of the variable.
  for(i in 1:nrow(df)){
    # Get the position of the current team in the matrix
    a <- as.numeric(df$Home[i])
    b <- as.numeric(df$Away[i])
    
    # Fill in the values
    if(df$PtsH[i] > df$PtsA[i]){
      A[a, b] <- A[a, b] + 1 * w[i] 
    } else if(df$PtsH[i] < df$PtsA[i]){
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
  colley.r <- suppressMessages(data_frame(TeamID = levels(sort(df$Home)), # Name of the team
                         Wins = rowSums(A), # How many wins
                         Loss = colSums(A), # How many loss
                         WinP = rowSums(A) / (Wins + Loss), # win-loss ratio
                         Colley = solve(colley.m, (0.5 * (rowSums(A) - colSums(A)) + 1)) # solved colley equation
  ))
  
  result <- list(colly.r = colley.r, colley.m = colley.m)

  return(result)
}
