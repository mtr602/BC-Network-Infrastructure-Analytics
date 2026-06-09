
library(tidyverse)
library(tidygeocoder)
library(readr)
library(dplyr)
library(sf)

colnames(BC_clean)

colnames(bc_data)



bc_gazetteer <- read.csv("/Users/user/Desktop/Project/Network/bc-gazetteer-2026-03-30.csv")

View(bc_gazetteer)

colnames(bc_gazetteer)

unique(bc_gazetteer$Feature.Type)

BC_reference <- bc_gazetteer %>%
  filter(
    Feature.Type %in% c(
      "City",
      "Town",
      "Village (1)",
      "First Nation Village",
      "Mountain"
    )
  )

colnames(BC_clean)
colnames(BC_reference)

# Mapping Code

BC_points <- st_as_sf(
  BC_clean,
  coords = c("longitude", "latitude"),
  crs = 4326,
  remove = FALSE
)

BC_ref_points <- st_as_sf(
  BC_reference,
  coords = c("LongDD", "LatDD"),
  crs = 4326,
  remove = FALSE
)

nearest_id <- st_nearest_feature(BC_points, BC_ref_points)

BC_clean_mapped <- BC_clean %>%
  mutate(
    nearest_name = BC_reference$Official.Name[nearest_id],
    nearest_type = BC_reference$Feature.Type[nearest_id],
    nearest_lat = BC_reference$LatDD[nearest_id],
    nearest_long = BC_reference$LongDD[nearest_id],
    distance_km = as.numeric(st_distance(BC_points, BC_ref_points[nearest_id, ], by_element = TRUE)) / 1000
  )

View(BC_clean_mapped)


write.csv(
  BC_clean_mapped,
  "/Users/user/Desktop/Project/Network/BC_clean_mapped.csv",
  row.names = FALSE
)



unique(BC_clean_mapped$nearest_name)


BC_clean_mapped <- BC_clean_mapped %>%
  mutate(
    region_bucket = case_when(
      nearest_name %in% c(
        "Vancouver","Burnaby","Richmond","Surrey","Coquitlam",
        "North Vancouver","New Westminster","Delta","Langley",
        "Port Moody","Port Coquitlam","Maple Ridge","Abbotsford",
        "White Rock","Nanaimo","Kelowna","Kamloops","Victoria"
      ) ~ "Urban Regions",
      
      nearest_name %in% c(
        "Prince George","Chilliwack","Penticton","Vernon","Salmon Arm",
        "Revelstoke","Nelson","Castlegar","Terrace","Smithers",
        "Quesnel","Williams Lake","Prince Rupert","Dawson Creek",
        "Fort St. John","Campbell River","Powell River","Cranbrook",
        "Fernie","Whistler","Pemberton","Gibsons","Courtenay",
        "Comox","Trail","Rossland","Grand Forks","Oliver",
        "Osoyoos","Golden","Nakusp","Kaslo","Kimberley"
      ) ~ "Regional Communities",
      
      nearest_name %in% c(
        "Masset","Port Clements","Tahsis","Gold River","Zeballos",
        "Midway","Greenwood","Slocan","Silverton","New Denver",
        "Yahk","Canal Flats","Pouce Coupe","Fraser Lake",
        "Burns Lake","Valemount","McBride","Lytton","Ashcroft",
        "Cache Creek","Barrière","Chase","Enderby","Lumby",
        "Keremeos","Princeton","Creston","Lake Cowichan","Duncan"
      ) ~ "Rural Areas",
      
      TRUE ~ "Remote Terrain Regions"
    )
  )


unique(BC_clean_mapped$region_bucket)
table(BC_clean_mapped$region_bucket)


BC_clean_mapped %>%
  group_by(region_bucket) %>%
  summarise(
    locations = n(),
    avg_download_mbps = round(mean(avg_d_kbps, na.rm = TRUE) / 1000, 2),
    avg_upload_mbps = round(mean(avg_u_kbps, na.rm = TRUE) / 1000, 2),
    avg_latency_ms = round(mean(avg_lat_ms, na.rm = TRUE), 2),
    total_tests = sum(tests, na.rm = TRUE),
    avg_tests_per_location = round(mean(tests, na.rm = TRUE), 1)
  ) %>%
  arrange(avg_latency_ms)

getwd()

