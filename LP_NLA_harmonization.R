# LP and NLA zoop harmonization script

#load packages
pacman::p_load(tidyverse, stringr)

#col names = lake_id, classic_group, target_taxon, biomass_ugL, dens??, Survey
# first start with LP and convert from wide to long
lp_zoop_final <- read.csv("data/LP_Zoo_ALLfinal_grouping2017_2018_2019.csv") |>
  mutate(across(-1, ~ as.numeric(gsub(",", "", .)))) |> #need to drop commas (but these are very large numbers...)
    pivot_longer(!Lake_ID, names_to = "target_taxon",
               values_to = "biomass_ugL") |> #check metric and units
  mutate(survey = "Lake Pulse",
         target_taxon = ifelse(target_taxon %in% c("ostracod"),"Ostracoda",
                               ifelse(target_taxon %in% c("harpacticoid"),"Hapracticoida",
                                      ifelse(target_taxon %in% c("cyclopoid.copepodid"), "Cyclopoida",
                                             ifelse(target_taxon %in% c("calanoid.copepodid"),"Calanoida", 
                                                    target_taxon)))),
         target_taxon = str_remove(target_taxon, "\\.spp?\\.$"))

# read in lookup table
taxa_lookup <- read.csv("data/NLA2017LakePulse-zooplankton-taxa-list-data-06062022.csv") |>
  select("TARGET_TAXON":"SUBSPECIES") |>
  rename(target_taxon = TARGET_TAXON) |>
  mutate(target_taxon = str_to_lower(target_taxon),
         target_taxon = str_c(str_to_upper(str_sub(target_taxon, 1, 1)),
                            str_sub(target_taxon, 2))) |>
  mutate(target_taxon = str_replace_all(target_taxon, " ", ".")) |>
  mutate(classic_group = case_when(
    PHYLUM == "ROTIFERA" ~ "rotifera",
    CLASS == "BRANCHIOPODA" & SUBORDER == "CLADOCERA" ~ "cladocera",
    CLASS == "MAXILLOPODA" & SUBCLASS == "COPEPODA" ~ "copepoda",
    TRUE ~ NA_character_
  )) |>
  filter(!if_all(everything(), ~ is.na(.) | . == ""))

# now add classic_group col
lp_zoop_final <- lp_zoop_final |>
  left_join(taxa_lookup %>% select(target_taxon, classic_group),
            by = "target_taxon")

#for the taxa names that don't match exactly, do a partial join
#unique(lp_zoop_final$target_taxon[is.na(lp_zoop_final$classic_group)])

lp_zoop_final <- lp_zoop_final |> #ugh something bad happens here....
  mutate(taxon_prefix = str_remove(target_taxon, "\\..*")) |>
  left_join(
    taxa_lookup |>
      mutate(taxon_prefix = str_remove(target_taxon, "\\..*")) |>
      select(taxon_prefix, classic_group) |>
      distinct(taxon_prefix, classic_group),  
    by = "taxon_prefix",
    suffix = c("", "_lookup")
  ) |>
  mutate(classic_group = if_else(is.na(classic_group),
                                 classic_group_lookup,
                                 classic_group)) |>
  select(-taxon_prefix, -classic_group_lookup) |>
  filter(biomass_ugL >= 0.01)

# now clean up NLA zoops (ZOCN = 150 um; ZOFN = 50 um)
nla_zoop <- read.csv("data/NLAzoo2017/nla-2017-zooplankton-count-data.csv") |>
  select(UID, ECO_BIO, SAMPLE_TYPE, TARGET_TAXON, BIOMASS, DENSITY, FFG) |> #make sure the biom/dens are the correct cols (not the 300)
  mutate(TARGET_TAXON = str_to_lower(TARGET_TAXON),
         TARGET_TAXON = str_c(str_to_upper(str_sub(TARGET_TAXON, 1, 1)),
                              str_sub(TARGET_TAXON, 2))) |>
  rename(Lake_ID = UID,
         eco_bio = ECO_BIO,
         sample_type = SAMPLE_TYPE,
         target_taxon = TARGET_TAXON,
         biomass_ugL = BIOMASS,
         density_nopL = DENSITY,
         ffg = FFG) |>
  mutate(survey = "NLA 2017")

#bring in the taxa lookup table again bc different target_taxon nomenclature
taxa_lookup <- read.csv("data/NLA2017LakePulse-zooplankton-taxa-list-data-06062022.csv") |>
  select("TARGET_TAXON":"SUBSPECIES") |>
  rename(target_taxon = TARGET_TAXON) |>
  mutate(target_taxon = str_to_lower(target_taxon),
         target_taxon = str_c(str_to_upper(str_sub(target_taxon, 1, 1)),
                              str_sub(target_taxon, 2))) |>
  mutate(classic_group = case_when(
    PHYLUM == "ROTIFERA" ~ "rotifera",
    CLASS == "BRANCHIOPODA" & SUBORDER == "CLADOCERA" ~ "cladocera",
    CLASS == "MAXILLOPODA" & SUBCLASS == "COPEPODA" ~ "copepoda",
    TRUE ~ NA_character_
  )) |>
  filter(!if_all(everything(), ~ is.na(.) | . == ""))

# now add classic_group col
nla_zoop_final <- nla_zoop |>
  left_join(taxa_lookup %>% select(target_taxon, classic_group),
            by = "target_taxon") |>
  mutate(Lake_ID = as.character(Lake_ID)) #to help with merging below
#unique(nla_zoop_final$target_taxon[is.na(nla_zoop_final$classic_group)])

#------------------------------------------------------------------------------#
# LAST STEP - combine NLA and LP datasets!

harmonized_zoop_df <- full_join(lp_zoop_final, nla_zoop_final, 
                                by = c("Lake_ID", "target_taxon", "classic_group","survey"))
#write.csv(harmonized_zoop_df, "data/HarmonizedZoop_LakePulseNLA2017_10092025.csv")

