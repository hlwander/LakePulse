# LP zoop data exploration

#load packages
pacman::p_load(tidyverse)

#read in the zoop datasets for LP
lp_zoop_raw <- read.csv("data/ZooLakePulseRaw_ALLfinal_grouping2017_2018_2019.csv") |>
  filter(!Lake_ID %in% "")

lp_zoop_final <- read.csv("data/LP_Zoo_ALLfinal_grouping2017_2018_2019.csv")
#the only difference between these files is that final data = raw x 10^9
# what are the units???? I guess it's prob biomass but it doesn't make sense that density isn't also available

# zoop data from 624 lakes sampled over 3 summers in 12 ecozones
# Definitely biomass but unclear if they also have density - only one in the datasets I have


# NLA zoop data
nla_zoop_raw <- read.csv("data/NLAzoo2017/nla-2017-zooplankton-raw-count-data-updated-12092021.csv")
#just total abundance per sample and biomass factor or the average biomass per taxa (ug dw)

nla_zoop_count <- read.csv("data/NLAzoo2017/nla-2017-zooplankton-count-data.csv")
#biomass and count in 300 organism subsample vs. in sample (I believe this is scaled up mathematically?)
# UID = Lake_ID

unique(nla_zoop_count$TARGET_TAXON)

#Questions
# 1 - What metric is LP dataset (biomass) and what are units?
# 2 - In NLA dataset, how does Daphnia differ from D. pulicaria, D. ambigua, etc..? 
# 3 - Is the NLA biomass or biomass in 300 the one that is comparable to LP?


