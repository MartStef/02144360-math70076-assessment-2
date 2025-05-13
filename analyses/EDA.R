library(torch)
library(torchvision)
library(here)
library(magrittr)
library(coro)
library(ggplot2)
library(tidyr)


train_path <- here("data", "derived", "train-data")
val_path <- here("data", "derived", "validation-data")


# Define transform function
transform <- function(img) {
  # Convert the image to a torch tensor (if it's not already a tensor)
  if (!inherits(img, "torch_tensor")) {
    img <- torch_tensor(img)
  }
  
  # Convert image from HWC to CHW (channels, height, width) format
  img <- img$permute(c(3, 1, 2))
  
  # Resize the image to 224x224
  img <- transform_resize(img, size = c(224, 224))
  
  return(img)
}

dataset_train <- image_folder_dataset(
  root = train_path,
  transform = transform
)

dataset_val <- image_folder_dataset(
  root = val_path,
  transform = transform
)

num_samples <- length(dataset_train)
class_names <- dataset_train$classes
num_classes <- length(class_names)

cat("Number of samples: ", num_samples, "\n")
cat("Number of classes: ", num_classes, "\n")
cat("Example classes:\n")
print(head(class_names, 10))

# Samples per class
df <- data.frame(class = class_labels,
                 count = as.numeric(class_counts))

p1 <- ggplot(df, aes(x = reorder(class, -count), y = count)) +
  geom_bar(stat = "identity", fill = "steelblue") +
  labs(title = "Samples per Class", x = "Class", y = "Count") +
  # set theme in a similar style to The Economist
  theme_minimal() +
  theme(
    text = element_text(family = "Gotham"),  # Use Gotham font for text
    axis.title = element_text(size = 12, color = "#3F5661"),
    axis.text.x = element_text(angle = 90, hjust = 1, size = 6, color = "#3F5661"),
    plot.title = element_text(hjust = 0.5, size = 16, 
                              face = "bold", color = "#3F5661"),
    plot.background = element_rect(fill = "#E9EDF0", color = "#E9EDF0"),
    legend.title = element_blank()
  )

# Save the output in the correct directory
# Setting resolution to 300dpi
ggsave(filename = here("outputs", "samples-per-class.png"),
       plot = p1, dpi = 300)

# Train/Validation split balance
get_class_counts <- function(dataset, num_classes) {
  targets <- sapply(1:length(dataset), function(i) dataset[[i]][[2]])
  table(factor(targets, levels = 0:(num_classes - 1)))
}

train_counts <- get_class_counts(dataset_train, length(dataset_train$classes))
val_counts <- get_class_counts(dataset_val, length(dataset_val$classes))

df_split <- data.frame(
  class = dataset$classes,
  train = as.numeric(train_counts),
  val = as.numeric(val_counts)
)


df_long <- pivot_longer(df_split, cols = c(train, val), names_to = "split", values_to = "count")

p2 <- ggplot(df_long, aes(x = reorder(class, -count), y = count, fill = split)) +
  geom_bar(stat = "identity", position = "dodge") +
  scale_fill_manual(values = c("steelblue", "#3EBCD2")) +
  labs(title = "Train vs Validation Class Distribution", x = "Class", y = "Count") +
  # set theme in a similar style to The Economist
  theme_minimal() +
  theme(
    text = element_text(family = "Gotham"),  # Use Gotham font for text
    axis.title = element_text(size = 12, color = "#3F5661"),
    axis.text.x = element_text(angle = 90, hjust = 1, size = 6, color = "#3F5661"),
    plot.title = element_text(hjust = 0.5, size = 16, 
                              face = "bold", color = "#3F5661"),
    plot.background = element_rect(fill = "#E9EDF0", color = "#E9EDF0"),
    legend.title = element_blank()
  )

# Save the output in the correct directory
# Setting resolution to 300dpi
ggsave(filename = here("outputs", "train-val-split-balance.png"),
       plot = p2, dpi = 300)







