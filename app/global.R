require(plyr)
require(dplyr) # Data manipulation
require(lubridate) # Get year component of a date
require(ggplot2) # For plotting
require(XLConnect)


# Open data
nfl.db <- src_postgres("nfl", host = "localhost", user = "dominik")
nfl <- tbl(nfl.db, "scores")


# Get years in db
nfl.years <- nfl %>%
  select(Date) %>%
  collect()

nfl.years <- unique(year(nfl.years$Date))
