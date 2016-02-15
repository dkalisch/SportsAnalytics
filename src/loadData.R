# Load package
library(dplyr)

# Open data
#nfl.db <- src_postgres("nfl", host = "localhost", user = "dominik")
nfl.db <- src_postgres("nfl", host = "localhost", user = "msharp",
                       password = "nflpassword")
nfl <- tbl(nfl.db, "scores")

# Get data

nfl.df <- nfl %>%
  filter(Date >= "2014-01-01",
         Date < "2015-01-01") %>%
  collect()

nfl.years <- nfl %>%
  select(Date) %>%
  collect()

nfl.years <- unique(year(nfl.years$Date))
