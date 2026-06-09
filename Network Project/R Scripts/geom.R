
library(tidyverse)
library(dplyr)
library(ggplot2)
library(scales)
library(readr)

BC_clean_mapped %>%
  filter(region_bucket != "Remote Terrain Regions") %>%
  mutate(avg_download_mbps = avg_d_kbps / 1000) %>%
  group_by(region_bucket) %>%
  summarise(avg_download_mbps = mean(avg_download_mbps, na.rm = TRUE)) %>%
  mutate(region_bucket = factor(
    region_bucket,
    levels = c("Urban Regions", "Regional Communities", "Rural Areas")
  )) %>%
  ggplot(aes(x = region_bucket, y = avg_download_mbps, fill = region_bucket)) +
  geom_col(width = 0.58, show.legend = FALSE) +
  geom_text(
    aes(label = paste0(round(avg_download_mbps, 1), " Mbps")),
    vjust = -0.45,
    fontface = "bold",
    size = 5
  ) +
  scale_y_continuous(
    labels = label_number(suffix = " Mbps"),
    limits = c(0, 310),
    expand = expansion(mult = c(0, 0.04))
  ) +
  labs(
    title = "Average Download Speed by Region Type",
    subtitle = "Urban BC leads network performance, while rural areas show a measurable speed gap",
    x = NULL,
    y = "Average Download Speed",
    caption = "Data source: Ookla Speedtest Intelligence, 2024 Q1\nRemote terrain regions excluded due to geographic mapping uncertainty."
  ) +
  theme_minimal(base_size = 14) +
  theme(
    plot.title = element_text(face = "bold", size = 22),
    plot.subtitle = element_text(face = "italic", size = 12),
    plot.caption = element_text(size = 9, hjust = 0),
    axis.text.x = element_text(face = "bold", size = 11),
    axis.text.y = element_text(size = 10),
    axis.title.y = element_text(face = "bold"),
    panel.grid.major.x = element_blank(),
    panel.grid.minor = element_blank()
  )

ggsave("BC_download_speed_chart.png", width = 12, height = 7, dpi = 300)

BC_clean_mapped <- BC_clean_mapped %>%
  mutate(
    avg_d_mbps = avg_d_kbps / 1000,
    avg_u_mbps = avg_u_kbps / 1000
  )

write.csv(
  BC_clean_mapped,
  "/Users/user/Desktop/Project/Network/BC_clean_mapped.csv",
  row.names = FALSE
)



getwd()