# LP and NLA zoop harmonization script
#Note - cannot actually harmonize these two datasets because LP mesh size = 100 um and NLA is 50 or 150 um

#load packages
pacman::p_load(tidyverse, stringr)

#col names = lake_id, classic_group, target_taxon, biomass_ugL, dens??, Survey
# first start with LP and convert from wide to long
lp_zoop_biom <- read.csv("data/ZooLakePulseRaw_ALLfinal_grouping2017_2018_2019.csv") |>
  filter(!Lake_ID %in% "") |>
    pivot_longer(!Lake_ID, names_to = "target_taxon",
               values_to = "biomass_ugL") |> 
  mutate(survey = "Lake Pulse",
         target_taxon = ifelse(target_taxon %in% c("ostracod"),"Ostracoda",
                               ifelse(target_taxon %in% c("harpacticoid"),"Hapracticoida",
                                      ifelse(target_taxon %in% c("cyclopoid.copepodid"), "Cyclopoida",
                                             ifelse(target_taxon %in% c("calanoid.copepodid"),"Calanoida", 
                                                    target_taxon)))),
         target_taxon = str_remove(target_taxon, "\\.spp?\\.$")) |>
  filter(!biomass_ugL %in% c(0)) # remove rows with biomass = 0

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
lp_zoop_biom <- lp_zoop_biom |>
  left_join(taxa_lookup %>% select(target_taxon, classic_group),
            by = "target_taxon")

#for the taxa names that don't match exactly, do a partial join
#unique(lp_zoop_final$target_taxon[is.na(lp_zoop_final$classic_group)])
lp_zoop_biom_final <- lp_zoop_biom |>
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
  select(-taxon_prefix, -classic_group_lookup) 

#clean up the lp density data too
lp_zoop_dens <- read.csv("data/ALLgrouping_concentrationsL.csv", sep=";") |>
  pivot_longer(!Lake_ID, names_to = "target_taxon",
               values_to = "density_NopL") |> 
  mutate(survey = "Lake Pulse",
         target_taxon = ifelse(target_taxon %in% c("ostracod"),"Ostracoda",
                               ifelse(target_taxon %in% c("harpacticoid"),"Hapracticoida",
                                      ifelse(target_taxon %in% c("cyclopoid.copepodid"), "Cyclopoida",
                                             ifelse(target_taxon %in% c("calanoid.copepodid"),"Calanoida", 
                                                    target_taxon)))),
         target_taxon = str_remove(target_taxon, "\\.spp?\\.$")) |>
  filter(!density_NopL %in% c(0)) |> # remove rows with density = 0
  left_join(taxa_lookup %>% select(target_taxon, classic_group),
            by = "target_taxon") # add classic group col

# and do the partial join for those species that are not in the lookup table
lp_zoop_dens_final <- lp_zoop_dens |>
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
  select(-taxon_prefix, -classic_group_lookup) 

#combine density and biomass data into one df
zoop_dens_biom <- full_join(lp_zoop_dens_final, lp_zoop_biom_final, 
          by = c("Lake_ID", "target_taxon","survey","classic_group"))
#write.csv(zoop_dens_biom, "data/LP_zoop_dens_biom_11Sep2025.csv")

#-------------------------------------------------------------------------------#
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
         density_NopL = DENSITY,
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
  mutate(Lake_ID = as.character(Lake_ID)) |>
  filter(!is.na(density_NopL))
#write.csv(nla_zoop_final,"data/NLA2017_zoop_dens_biom_11Sep2025.csv")

#unique(nla_zoop_final$target_taxon[is.na(nla_zoop_final$classic_group)])