library(here)

# Set paths
zip_path <- here("data", "raw", "stanford-car-dataset-by-classes-folder.zip")
extract_dir <- here("data", "raw", "car_data")


# Download if the zip file doesn't exist
if (!file.exists(zip_path)) {
  cat("📥 Downloading dataset...\n")
  system(paste("kaggle datasets download -d jutrera/stanford-car-dataset-by-classes-folder -p", here("data", "raw")))
}

unzip(zip_path, exdir = extract_dir)
