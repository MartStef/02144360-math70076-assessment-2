# Import required libraries
library(magrittr)
library(dplyr)
library(readr)
library(tidyverse)
library(here)
library(jpeg)
library(torch)
library(torchvision)
library(ggplot2)
library(yardstick)
source(here("analyses", "cnn-model.R"))
source(here("analyses", "res_net_18-model.R"))

metrics_df <- tibble::tibble(
  metric = c("Precision", "Recall", "F1-score"),
  CNN = c(cnn_precision$.estimate, cnn_recall$.estimate, cnn_f1$.estimate),
  RESNET18 = c(resnet18_precision$.estimate, resnet18_recall$.estimate, resnet18_f1$.estimate)
) %>%
  pivot_longer(cols = c(CNN, RESNET18), names_to = "Model", values_to = "Value")

p1 <- ggplot(metrics_df, aes(x = metric, y = Value, fill = Model)) +
  geom_bar(stat = "identity", position = position_dodge(width = 0.7), width = 0.6) +
  labs(title = "Model Performance Comparison",
       y = "Score",
       x = "Metric") +
  scale_fill_manual(values = c("steelblue", "#3EBCD2")) +
  ylim(0, 0.6) + 
  geom_text(aes(label = sprintf("%.2f", Value)), 
                         position = position_dodge(width = 0.7), 
                         vjust = -0.5, size = 3, color = "#3F5661") +
  theme_minimal() +
  theme(
    text = element_text(family = "Gotham"),  # Use Gotham font for text
    axis.title = element_text(size = 12, color = "#3F5661"),
    plot.title = element_text(hjust = 0.5, size = 16, 
                              face = "bold", color = "#3F5661"),
    plot.background = element_rect(fill = "#E9EDF0", color = "#E9EDF0"),
    legend.title = element_blank()
  )

# Save the output in the correct directory
# Setting resolution to 300dpi
ggsave(filename = here("outputs", "metric-comparison.png"),
       plot = p1, dpi = 300)


