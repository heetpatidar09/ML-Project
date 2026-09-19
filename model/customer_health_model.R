# ============================================================
# CUSTOMER HEALTH RISK PREDICTION MODELS
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

health_data <- data.frame(
  age = c(22, 31, 45, 28, 52, 36, 41, 29, 48, 33, 39, 26, 57, 34, 43),
  bmi = c(22.5, 24.0, 30.1, 23.4, 31.8, 28.2, 29.7, 25.1, 32.5, 27.0, 29.2, 23.3, 33.5, 26.5, 30.6),
  blood_pressure = c(118, 122, 140, 124, 148, 135, 138, 120, 146, 129, 137, 121, 152, 128, 142),
  exercise_hours = c(5, 4, 2, 4, 1, 3, 2, 5, 1, 4, 2, 5, 1, 4, 2),
  risk = factor(c("Low Risk", "Low Risk", "High Risk", "Low Risk", "High Risk", "High Risk", "High Risk", "Low Risk", "High Risk", "Low Risk", "High Risk", "Low Risk", "High Risk", "Low Risk", "High Risk"))
)

print(health_data)

set.seed(123)
train_index <- sample(1:nrow(health_data), size = floor(0.8 * nrow(health_data)))
train_data <- health_data[train_index, ]
test_data <- health_data[-train_index, ]

# ============================================================
# LOGISTIC REGRESSION
# ============================================================

logistic_model <- glm(
  risk ~ age + bmi + blood_pressure + exercise_hours,
  data = train_data,
  family = binomial
)

logistic_prob <- predict(logistic_model, newdata = test_data, type = "response")
logistic_pred <- ifelse(logistic_prob >= 0.5, "High Risk", "Low Risk")
logistic_accuracy <- mean(logistic_pred == test_data$risk)

saveRDS(logistic_model, file = "customer_health_model.rds")

cat("Logistic accuracy:", logistic_accuracy, "\n")

# ============================================================
# DECISION TREE
# ============================================================

library(rpart)

decision_model <- rpart(
  risk ~ age + bmi + blood_pressure + exercise_hours,
  data = train_data,
  method = "class"
)

decision_prob <- predict(decision_model, newdata = test_data, type = "prob")
decision_pred <- ifelse(decision_prob[, "High Risk"] >= 0.5, "High Risk", "Low Risk")
decision_accuracy <- mean(decision_pred == test_data$risk)

saveRDS(decision_model, file = "customer_health_model_decision_tree.rds")

cat("Decision Tree accuracy:", decision_accuracy, "\n")

# ============================================================
# RANDOM FOREST
# ============================================================

library(randomForest)

random_forest_model <- randomForest(
  risk ~ age + bmi + blood_pressure + exercise_hours,
  data = train_data,
  ntree = 500,
  importance = TRUE
)

random_prob <- predict(random_forest_model, newdata = test_data, type = "prob")
random_pred <- ifelse(random_prob[, "High Risk"] >= 0.5, "High Risk", "Low Risk")
random_accuracy <- mean(random_pred == test_data$risk)

saveRDS(random_forest_model, file = "customer_health_model_random_forest.rds")

cat("Random Forest accuracy:", random_accuracy, "\n")

# ============================================================
# SUPPORT VECTOR MACHINE
# ============================================================

library(e1071)

svm_model <- svm(
  risk ~ age + bmi + blood_pressure + exercise_hours,
  data = train_data,
  kernel = "radial",
  probability = TRUE
)

svm_pred <- predict(svm_model, newdata = test_data, probability = TRUE)
svm_prob <- attr(svm_pred, "probabilities")
svm_prob <- svm_prob[, "High Risk"]
svm_pred_class <- ifelse(svm_prob >= 0.5, "High Risk", "Low Risk")
svm_accuracy <- mean(svm_pred_class == test_data$risk)

saveRDS(svm_model, file = "customer_health_model_svm.rds")

cat("SVM accuracy:", svm_accuracy, "\n")

# ============================================================
# SAMPLE PREDICTION
# ============================================================

sample_customer <- data.frame(
  age = 34,
  bmi = 27.5,
  blood_pressure = 128,
  exercise_hours = 3
)

sample_lg <- predict(logistic_model, newdata = sample_customer, type = "response")
cat("Logistic sample probability:", sample_lg, "\n")

sample_dt <- predict(decision_model, newdata = sample_customer, type = "prob")
cat("Decision tree sample probability:", sample_dt[, "High Risk"], "\n")

sample_rf <- predict(random_forest_model, newdata = sample_customer, type = "prob")
cat("Random forest sample probability:", sample_rf[, "High Risk"], "\n")

sample_svm <- predict(svm_model, newdata = sample_customer, probability = TRUE)
cat("SVM sample probability:", attr(sample_svm, "probabilities")[, "High Risk"], "\n")

cat("========================================\n")
cat("All customer health model files created successfully!\n")
cat("========================================\n")
