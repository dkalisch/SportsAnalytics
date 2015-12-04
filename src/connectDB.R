###
### Project:  NFL Sports Analytics 
###
### Url:      http://www.kalisch.biz
###
### File:     connectDB.R
###
### Author:   Dominik P.H. Kalisch (dkalisch@trinity.edu)
###
### Desc.:    This script connects to a database 
###
###
### Modification history
### ----------------------------------------------------------------------------
###
### Date        Version   Who                 Description
### 2015-12-03  0.1       Dominik Kalisch     initial build
###
### Needed R packages:  DBI
###                     RPostgreSQL
###
### Needed R files: dbSettings.R
###

# Load needded libraries
library(DBI) # For connecting to the DB
library(RPostgreSQL) # Driver for PostgreSQL

# Set the driver
drv <- dbDriver("PostgreSQL")

# Read the database settings
source('src/dbSettings.R')

# Open connection to database
nfl.db <- dbConnect(drv,
                 host = host,
                 port = port, 
                 dbname = dbname,
                 user = user,
                 password = pwd)

