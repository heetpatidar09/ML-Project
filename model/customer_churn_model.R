# ============================================================
# CUSTOMER CHURN PREDICTION MODELS
# ============================================================

if (!requireNamespace("rpart", quietly = TRUE)) {
  install.packages("rpart", repos = "https://cloud.r-project.org")
}

if (!requireNamespace("randomForest", quietly = TRUE)) {
  install.packages("randomForest", repos = "https://cloud.r-project.org")
}

if (!requireNamespace("e1071", quietly = TRUE)) {
  install.packages("e1071", repos = "https://cloud.r-project.org")
}

customer_data <- data.frame(
  age = c(22, 31, 45, 28, 52, 36, 41, 29, 48, 33, 39, 26, 57, 34, 43),
  monthly_spend = c(120, 180, 260, 150, 340, 210, 290, 170, 320, 200, 240, 140, 380, 210, 300),
  support_calls = c(4, 2, 7, 3, 9, 5, 6, 2, 8, 4, 5, 3, 10, 4, 7),
  tenure_months = c(12, 9, 24, 18, 6, 15, 11, 20, 8, 14, 10, 19, 5, 17, 13),
  churn = factor(c("Retain", "Retain", "Churn", "Retain", "Churn", "Churn", "Churn", "Retain", "Churn", "Retain", "Churn", "Retain", "Churn", "Retain", "Churn"))
)

print(customer_data)

set.seed(123)
train_index <- sample(1:nrow(customer_data), size = floor(0.8 * nrow(customer_data)))
train_data <- customer_data[train_index, ]
test_data <- customer_data[-train_index, ]

# ============================================================
# LOGISTIC REGRESSION
# ============================================================

logistic_model <- glm(
  churn ~ age + monthly_spend + support_calls + tenure_months,
  data = train_data,
  family = binomial
)

logistic_prob <- predict(logistic_model, newdata = test_data, type = "response")
logistic_pred <- ifelse(logistic_prob >= 0.5, "Churn", "Retain")
logistic_accuracy <- mean(logistic_pred == test_data$churn)

saveRDS(logistic_model, file = "customer_churn_model.rds")

cat("Logistic accuracy:", logistic_accuracy, "\n")

# ============================================================
# DECISION TREE
# ============================================================

library(rpart)

decision_model <- rpart(
  churn ~ age + monthly_spend + support_calls + tenure_months,
  data = train_data,
  method = "class"
)

decision_prob <- predict(decision_model, newdata = test_data, type = "prob")
decision_pred <- ifelse(decision_prob[, "Churn"] >= 0.5, "Churn", "Retain")
decision_accuracy <- mean(decision_pred == test_data$churn)

saveRDS(decision_model, file = "customer_churn_model_decision_tree.rds")

cat("Decision Tree accuracy:", decision_accuracy, "\n")

# ============================================================
# RANDOM FOREST
# ============================================================

library(randomForest)

random_forest_model <- randomForest(
  churn ~ age + monthly_spend + support_calls + tenure_months,
  data = train_data,
  ntree = 500,
  importance = TRUE
)

random_prob <- predict(random_forest_model, newdata = test_data, type = "prob")
random_pred <- ifelse(random_prob[, "Churn"] >= 0.5, "Churn", "Retain")
random_accuracy <- mean(random_pred == test_data$churn)

saveRDS(random_forest_model, file = "customer_churn_model_random_forest.rds")

cat("Random Forest accuracy:", random_accuracy, "\n")

# ============================================================
# SUPPORT VECTOR MACHINE
# ============================================================

library(e1071)

svm_model <- svm(
  churn ~ age + monthly_spend + support_calls + tenure_months,
  data = train_data,
  kernel = "radial",
  probability = TRUE
)

svm_pred <- predict(svm_model, newdata = test_data, probability = TRUE)
svm_prob <- attr(svm_pred, "probabilities")
svm_prob <- svm_prob[, "Churn"]
svm_pred_class <- ifelse(svm_prob >= 0.5, "Churn", "Retain")
svm_accuracy <- mean(svm_pred_class == test_data$churn)

saveRDS(svm_model, file = "customer_churn_model_svm.rds")

cat("SVM accuracy:", svm_accuracy, "\n")

# ============================================================
# SAMPLE PREDICTION
# ============================================================

sample_customer <- data.frame(
  age = 34,
  monthly_spend = 220,
  support_calls = 5,
  tenure_months = 12
)

sample_lg <- predict(logistic_model, newdata = sample_customer, type = "response")
cat("Logistic sample probability:", sample_lg, "\n")

sample_dt <- predict(decision_model, newdata = sample_customer, type = "prob")
cat("Decision tree sample probability:", sample_dt[, "Churn"], "\n")

sample_rf <- predict(random_forest_model, newdata = sample_customer, type = "prob")
cat("Random forest sample probability:", sample_rf[, "Churn"], "\n")

sample_svm <- predict(svm_model, newdata = sample_customer, probability = TRUE)
cat("SVM sample probability:", attr(sample_svm, "probabilities")[, "Churn"], "\n")

cat("========================================\n")
cat("All customer churn model files created successfully!\n")
cat("========================================\n")