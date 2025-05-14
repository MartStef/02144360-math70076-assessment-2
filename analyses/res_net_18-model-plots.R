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
source(here("analyses", "res_net_18-model.R"))

df <- data.frame(
  epoch = 1:length(train_losses_resnet),
  train_loss = train_losses_resnet,
  val_loss = val_losses_resnet,
  train_acc = train_accuracies_resnet,
  val_acc = val_accuracies_resnet
)

# Plot loss
p1 <- ggplot(df, aes(x = epoch)) +
  geom_line(aes(y = train_loss, color = "Train Loss")) +
  geom_line(aes(y = val_loss, color = "Val Loss")) +
  labs(title = "Loss over Epochs for RESNET18", y = "Loss") +
  scale_color_manual(values = c("Train Loss" = "steelblue", "Val Loss" = "#3EBCD2")) +
  # set theme in a similar style to The Economist
  theme_minimal() +
  theme(
    text = element_text(family = "Gotham"),  # Use Gotham font for text
    axis.title = element_text(size = 12, color = "#3F5661"),
    axis.text.x = element_text(hjust = 1, size = 12, color = "#3F5661"),
    plot.title = element_text(hjust = 0.5, size = 16, 
                              face = "bold", color = "#3F5661"),
    plot.background = element_rect(fill = "#E9EDF0", color = "#E9EDF0"),
    legend.title = element_blank()
  )

# Save the output in the correct directory
# Setting resolution to 300dpi
ggsave(filename = here("outputs", "loss-res_net_18-model.png"),
       plot = p1, dpi = 300)

# Plot accuracy
p2 <- ggplot(df, aes(x = epoch)) +
  geom_line(aes(y = train_acc, color = "Train Accuracy")) +
  geom_line(aes(y = val_acc, color = "Val Accuracy")) +
  labs(title = "Accuracy over Epochs for RESNET18", y = "Accuracy") +
  scale_color_manual(values = c("Train Accuracy" = "steelblue", "Val Accuracy" = "#3EBCD2")) +
  # set theme in a similar style to The Economist
  theme_minimal() +
  theme(
    text = element_text(family = "Gotham"),  # Use Gotham font for text
    axis.title = element_text(size = 12, color = "#3F5661"),
    axis.text.x = element_text(hjust = 1, size = 12, color = "#3F5661"),
    plot.title = element_text(hjust = 0.5, size = 16, 
                              face = "bold", color = "#3F5661"),
    plot.background = element_rect(fill = "#E9EDF0", color = "#E9EDF0"),
    legend.title = element_blank()
  )

# Save the output in the correct directory
# Setting resolution to 300dpi
ggsave(filename = here("outputs", "accuracy-res_net_18-model.png"),
       plot = p2, dpi = 300)





