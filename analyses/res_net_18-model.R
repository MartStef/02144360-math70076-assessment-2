library(torch)
library(torchvision)
library(here)
library(magrittr)
library(coro)

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

train_dl <- dataloader(dataset_train, batch_size = 32, shuffle = TRUE)
val_dl <- dataloader(dataset_val, batch_size = 32)

# Load the pre-trained ResNet18 model
model <- model_resnet18(pretrained = TRUE)

# Freeze all layers except the final fully connected layer
for (param in model$parameters) {
  param$requires_grad_(FALSE)
}

# Replace the final layer with a new one matching your number of classes
num_classes <- 50
model$fc <- nn_linear(in_features = model$fc$in_features, out_features = num_classes)

# Only train the final layer
optimizer <- optim_adam(model$fc$parameters, lr = 0.001)

criterion <- nn_cross_entropy_loss()

train_losses_resnet <- c()
val_losses_resnet <- c()
train_accuracies_resnet <- c()
val_accuracies_resnet <- c()

# Training loop (simplified)
for (epoch in 1:10) {
  model$train()
  total_loss <- 0
  correct <- 0
  total <- 0
  
  coro::loop(for (batch in train_dl) {
    optimizer$zero_grad()

    # Get input and target
    x <- batch[[1]]
    y <- batch[[2]]$to(dtype = torch_long())$squeeze()
    
    # Forward pass
    output <- model(x)

    # Loss
    loss <- criterion(output, y)
    loss$backward()
    optimizer$step()
    
    total_loss <- total_loss + loss$item()
    preds <- output$argmax(dim = 2)
    correct <- correct + (preds == batch[[2]]$view(c(-1)))$sum()$item()
    total <- total + length(batch[[2]])
  })
  
  train_losses_resnet <- c(train_losses_resnet, total_loss)
  train_accuracies_resnet <- c(train_accuracies_resnet, correct / total * 100)
  
  cat(sprintf("Epoch %d - Loss: %.4f\n", epoch, total_loss))
}

model$eval()

val_loss <- 0
val_correct <- 0
val_total <- 0

coro::loop(for (batch in val_dl) {
  output <- model(batch[[1]])
  val_loss <- val_loss + criterion(output, batch[[2]])$item()
  preds <- output$argmax(dim = 2)
  val_correct <- val_correct + (preds == batch[[2]]$view(c(-1)))$sum()$item()
  val_total <- val_total + length(batch[[2]])
})

val_losses_resnet <- c(val_losses_resnet, val_loss)
val_accuracies_resnet <- c(val_accuracies_resnet, val_correct / val_total * 100)

cat(sprintf("Validation accuracy: %.2f%%\n", val_correct / val_total * 100))

get_predictions <- function(model, dataloader) {
  preds_all <- c()
  targets_all <- c()
  
  model$eval()
  coro::loop(for (batch in dataloader) {
    x <- batch[[1]]
    y <- as.integer(as_array(batch[[2]]))
    output <- model(x)
    preds <- as.integer(as_array(output$argmax(dim = 2)))
    
    preds_all <- c(preds_all, preds)
    targets_all <- c(targets_all, y)
  })
  
  all_levels <- sort(unique(c(as.character(targets_all), as.character(preds_all))))
  
  data.frame(
    truth = factor(targets_all, levels = all_levels),
    prediction = factor(preds_all, levels = all_levels)
  )
}

results <- get_predictions(model, val_dl)

# Compute metrics one by one with macro averaging
resnet18_acc <- accuracy(results, truth = truth, estimate = prediction)
resnet18_precision <- precision(results, truth = truth, estimate = prediction, estimator = "macro")
resnet18_recall <- recall(results, truth = truth, estimate = prediction, estimator = "macro")
resnet18_f1 <- f_meas(results, truth = truth, estimate = prediction, estimator = "macro")

