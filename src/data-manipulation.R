## Reads raw data and creates necessary data sets for the analysis

# Import required libraries
library(magrittr)
library(dplyr)
library(readr)
library(tidyverse)
library(here)
library(jpeg)
library(torch)
library(torchvision)

# Define paths
train_path <- here("data", "raw", "car-data", "car_data", "car_data", "train")
test_path <- here("data", "raw", "car-data", "car_data", "car_data", "test")

# Get class names (folder names = labels)
class_names <- list.dirs(train_path, full.names = FALSE, recursive = FALSE)

# Create a tibble with class and image paths
train_data <- list.dirs(train_path, full.names = TRUE, recursive = FALSE) %>%
  map_dfr(function(class_dir) {
    image_files <- list.files(class_dir, full.names = TRUE, pattern = "\\.jpg$")
    tibble(
      class = basename(class_dir),
      image_path = image_files
    )
  })

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
# Get dataset
dataset <- image_folder_dataset(
  root = train_path,
  transform = transform
)

# Extract all class labels (integers) from the dataset
labels <- sapply(1:length(dataset), function(i) dataset[i][["y"]])

# Pick 50 unique class indices
set.seed(42)
selected_classes <- sample(unique(labels), 50)

# Filter dataset to only those classes
filtered_indices <- which(labels %in% selected_classes)
filtered_dataset <- dataset_subset(dataset, indices = filtered_indices)

# Create a mapping: original_label -> new_label (1 to 50)
label_map <- setNames(1:50, selected_classes)

# Apply label mapping to dataset
remapped_dataset <- lapply(1:length(filtered_dataset), function(i) {
  item <- filtered_dataset[i]
  x <- item[[1]]
  y <- item[[2]]  # get scalar label
  y_remapped <- label_map[as.character(y)]
  list(x = x, y = torch_tensor(y_remapped, dtype = torch_long()))
})

remapped_dataset <- dataset(
  name = "RemappedDataset",
  initialize = function(data) {
    self$data <- data
  },
  .getitem = function(i) {
    self$data[[i]]
  },
  .length = function() {
    length(self$data)
  }
)(remapped_dataset)

# Split into train and validation sets
n <- length(remapped_dataset)
indices <- sample(1:n)
split <- floor(0.8 * n)
train_indices <- indices[1:split]
val_indices <- indices[(split + 1):n]

train_ds <- dataset_subset(remapped_dataset, indices = train_indices)
val_ds <- dataset_subset(remapped_dataset, indices = val_indices)

# Save images function to create subset of data
save_images <- function(subset, folder) {
  dir.create(folder, recursive = TRUE, showWarnings = FALSE)
  
  for (i in 1:length(subset)) {
    example <- subset[i]
    img_tensor <- example[[1]]
    class_name <- dataset$classes[selected_classes[example[[2]]$item()]]
    
    class_folder <- file.path(folder, class_name)
    dir.create(class_folder, showWarnings = FALSE)
    
    # Convert tensor back to image
    img_array <- as.array(img_tensor$permute(c(2, 3, 1)))  # CHW -> HWC
    img_array <- pmin(pmax(img_array, 0), 1)  # clip to [0, 1]
    
    img_path <- file.path(class_folder, paste0("img_", i, ".jpg"))
    
    # Save using jpeg package
    jpeg::writeJPEG(img_array, target = img_path)
  }
}

# Create derived data
save_images(train_ds, here("data", "derived", "train-data"))
save_images(val_ds, here("data", "derived", "validation-data"))





