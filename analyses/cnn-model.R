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

net <- nn_module(
  "CNN",
  initialize = function() {
    self$conv1 <- nn_conv2d(3, 16, kernel_size = 3, padding = 1)
    self$pool <- nn_max_pool2d(kernel_size = 2)
    self$conv2 <- nn_conv2d(16, 32, kernel_size = 3, padding = 1)
    self$fc1 <- nn_linear(32 * 56 * 56, 128)  # adjust depending on image size
    self$fc2 <- nn_linear(128, length(dataset$classes))
  },
  forward = function(x) {
    x %>% 
      self$conv1() %>%
      nnf_relu() %>%
      self$pool() %>%
      self$conv2() %>%
      nnf_relu() %>%
      self$pool() %>%
      torch_flatten(start_dim = 2) %>%
      self$fc1() %>%
      nnf_relu() %>%
      self$fc2()
  }
)

model <- net()

optimizer <- optim_adam(model$parameters, lr = 0.001)

criterion <- nn_cross_entropy_loss()

train_losses <- c()
val_losses <- c()
train_accuracies <- c()
val_accuracies <- c()

# Training loop (simplified)
for (epoch in 1:5) {
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
  
  train_losses <- c(train_losses, total_loss)
  train_accuracies <- c(train_accuracies, correct / total)
  
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

val_losses <- c(val_losses, val_loss)
val_accuracies <- c(val_accuracies, val_correct / val_total)

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
accuracy(results, truth = truth, estimate = prediction)
precision(results, truth = truth, estimate = prediction, estimator = "macro")
recall(results, truth = truth, estimate = prediction, estimator = "macro")
f_meas(results, truth = truth, estimate = prediction, estimator = "macro")

