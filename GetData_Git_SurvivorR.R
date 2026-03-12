library(dplyr)
library(tidyverse)
library(readr)

install.packages("survivoR")
library(survivoR)

# Confessional timing
# Included in the package is a confessional timing app to record the length of confessionals while watching the episode.
# launch app
launch_confessional_app()

# .rda files downaloased from survivorR Git repo by doehm
# https://github.com/doehm/survivoR

#this script saves them as .csv files

getwd()
folder<- "/Users/Polina/Documents/Projects/survivor_dashboard/"
setwd(folder)
#writing advantages_details .rda to .csv
write_csv(advantage_details, 
          file = "/Users/Polina/Documents/Projects/survivor_dashboard/CSV/advantage_details.csv")

#writing advantage_movement .rda to .csv
write_csv(advantage_movement, 
          file = "/Users/Polina/Documents/Projects/survivor_dashboard/CSV/advantage_movement.csv")

#writing confessionsals .rda to .csv
write_csv(confessionals, 
          file = "/Users/Polina/Documents/Projects/survivor_dashboard/CSV/confessionals.csv")

#writing vote_history .rda to .csv
write_csv(vote_history, 
          file = "/Users/Polina/Documents/Projects/survivor_dashboard/CSV/vote_history.csv")

#writing cataways .rda to .csv
write_csv(castaways, 
          file = "/Users/Polina/Documents/Projects/survivor_dashboard/CSV/castaways.csv")


#################################################################
#exploring clean datasets to assist with BULK INSERT into SQL database

folder<- "/Users/Polina/Documents/Projects/survivor_dashboard/CSV"
setwd(folder)

castaways<- read.csv("castaways.csv")

typeof(castaways$jury)
isTRUE(castaways$jury[1])
isTRUE(castaways$jury[8])
castaways$castaway_id[is.na(castaways$jury)]

typeof(castaways$ack_score)

#deleting ack_quote and ack-score columns - they are not useful to me 
# and the quotation in ack_quote is causing a truncation issue during BULK INSERT
# can get arounf it by chagning to CSV format in SQL Server but not worth the hassle for this analysis

castaways<- castaways%>%
  select(-c(ack_quote, ack_score))

write_csv(castaways, 
          file = "/Users/Polina/Documents/Projects/survivor_dashboard/CSV/castaways.csv")

vote_history<- read.csv("vote_history.csv")



