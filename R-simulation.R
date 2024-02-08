library(foreach)
library(doParallel)

# Parallel backend
num_cores <- 8
registerDoParallel(num_cores)

# Set initial SEED
SEED <- 42
set.seed(SEED)

# Load data
train_rose <- read.csv("data/train_rose.csv")
test <- read.csv("data/test.csv")

# Set "random" parameters
n <- 5
a <- 0
b <- n*3
SEEDS <- sample(a:b, n, replace = FALSE)

# Simulation params for each SEED
train_perc <- 0.8
boot_perc <- 0.8
boot_n <- 20
boot_l <- round(boot_perc * nrow(train_rose), 0)

# SIMULATION
t0 <- Sys.time()
foreach(i = 1:n, .packages = c("stats","doParallel")) %dopar% {
  SEED <- SEEDS[i]
  set.seed(SEED)
  
  train_index <- sample(1:nrow(train_rose), round(train_perc * nrow(train_rose), 0))
  train <- train_rose[train_index,]
  val <- train_rose[-train_index,]
  
  bootstrap_samples <- lapply(1:boot_n, function(x) train[sample(1:nrow(train), boot_l, replace = TRUE), ])
  
  y_pred_val <- matrix(0, nrow = nrow(val), ncol = boot_n)
  y_pred_test <- matrix(0, nrow = nrow(test), ncol = boot_n)
  
  foreach(j = 1:boot_n, .combine = 'c') %dopar% {
    model <- glm(formula = CARAVAN ~ ., data = bootstrap_samples[[j]], family = "binomial")
    
    # Predict and store predictions
    y_pred_val[,j] <- predict(model, val)
    y_pred_test[,j] <- predict(model, test)
  }
  
  # Compute final predictions
  final_pred_val <- ifelse(rowMeans(y_pred_val) > 0.5, 1, 0)
  final_pred_test <- ifelse(rowMeans(y_pred_test) > 0.5, 1, 0)
  
  # Save predictions to CSV files
  write.csv(final_pred_val, paste0("SEED_", SEED, "_HARD", "_pred_val.csv"), row.names = FALSE)
  write.csv(final_pred_test, paste0("SEED_", SEED,"_HARD", "_pred_test.csv"), row.names = FALSE)
}
t1 <- Sys.time()
print(t1 - t0)
