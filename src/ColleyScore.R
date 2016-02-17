# Load library
library(dplyr) # Data gathering and manipulation
library(fBasics) # Havyside function

# Open data
nfl.db <- src_postgres("nfl", host = "localhost", user = "dominik")
nfl <- tbl(nfl.db, "scores")

nfl.df <- nfl %>%
  dplyr::filter(Date >= "2014-01-01",
         Date < "2015-01-01") %>%
  collect()

nfl.df$Home <- as.factor(nfl.df$Home)
nfl.df$Away <- as.factor(nfl.df$Away)

nfl.df <- nfl.df[!is.na(nfl.df$Week),]

#### Not working
##library(Matrix)
##
##hs <- Heaviside(nfl.df$Week-2.5) + 1
##
##in.home.w <- sparseMatrix(i = as.numeric(nfl.df$Home),
##                          j = as.numeric(nfl.df$Away),
##                          x = (nfl.df$PtsH %*% hs),
##                          dims = c(nlevels(nfl.df$Home), nlevels(nfl.df$Home)))
##in.away.w <- sparseMatrix(i = as.numeric(nfl.df$Home),
##                          j = as.numeric(nfl.df$Away),
##                          x = (nfl.df$PtsA %*% hs),
##                          dims = c(nlevels(nfl.df$Home), nlevels(nfl.df$Home)))
##
##in.home.w + in.away.w
####

# Home is row, Away is column. Winner gets a 1
A <- matrix(nrow = nlevels(nfl.df$Home), ncol = nlevels(nfl.df$Home), 0)

# Compute incidence matrix
# This is not the best way to do it, but it makes it more clear what happens

for(i in 1:nrow(nfl.df)){
  if(nfl.df$PtsH[i] > nfl.df$PtsA[i]){
    A[as.numeric(nfl.df$Home[i]), as.numeric(nfl.df$Away[i])] <- 1
  } else if(nfl.df$PtsH[i] < nfl.df$PtsA[i]){
    A[as.numeric(nfl.df$Away[i]), as.numeric(nfl.df$Home[i])] <- 1
  } else {
    A[as.numeric(nfl.df$Home[i]), as.numeric(nfl.df$Away[i])] <- 0.5
    A[as.numeric(nfl.df$Away[i]), as.numeric(nfl.df$Home[i])] <- 0.5
  }
}

colley.m <- -(A + t(A)) + diag(rowSums(A) + colSums(A) + 2)

colley.r <- data_frame(TeamID = levels(sort(nfl.df$Home)),
                   Wins = rowSums(A),
                   Loss = colSums(A),
                   WinP = rowSums(A) / (Wins + Loss),
                   Colly = solve(colley.m, (0.5 * (rowSums(A) + colSums(A)) + 1))
                   )


