# preliminary analyses

# read in packages
pacman::p_load(tidyverse, ggplot2)


#read in harmonized plankton datasets
phytos <- read.csv("data/HarmonizedPhyto_LakePulseNLA2017_19092022.csv")
#zoops <- read.csv("data/")

# read in harmonized env driver dataset
pred <- read.csv("data/HarmonizedPredictors_LakePulseNLA2017_21062022.csv")
