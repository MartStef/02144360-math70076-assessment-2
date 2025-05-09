library(here)

#if (!dir.exists("data")) dir.create("data")

#url <- "http://ai.stanford.edu/~jkrause/car196/cars_train.tgz"
url <- "https://www.kaggle.com/datasets/jutrera/stanford-car-dataset-by-classes-folder/data?select=car_data"
dest <- here("data", "raw", "car_data")

#if (!file.exists(dest)) {
#  cat("📥 Downloading dataset...\n")
#  download.file(url, dest)
#  cat("📦 Extracting...\n")
#  untar(dest, exdir = "data/")
#} else {
#  cat("✅ Dataset already exists. Skipping download.\n")
#}

# Only download if not already there
if (!file.exists(dest)) {
  cat("📥 Downloading dataset from Kaggle...\n")
  system("kaggle datasets download -d jutrera/stanford-car-dataset-by-classes-folder -p data/")
}

# Unzip it
unzip(dest, exdir = here("data", "raw"))
