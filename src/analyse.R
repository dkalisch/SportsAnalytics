# load used libraries
library(dplyr)

# Connect to database
nfl.db <- src_postgres("nfl")
nfl <- tbl(nfl.db, "scores")


# create a matrix with this columns
#1: DATE ID
#2: AWAY ID
#3: AWAY SCORE
#4: HOME ID
#5: HOME SCORE

#the winner is always left unless there is an @ sign in clo6