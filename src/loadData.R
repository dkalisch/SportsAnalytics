# Load library
library(dplyr)

# Open data
nfl.db <- src_postgres("nfl", host = "localhost", user = "dominik")
nfl <- tbl(nfl.db, "scores")

# Get data

nfl.df <- nfl %>%
  filter(Date >= "2014-01-01",
         Date < "2015-01-01") %>%
  collect()
