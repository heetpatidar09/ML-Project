# ============================================================
# CUSTOMER CHURN PREDICTION SCRIPT
# ============================================================

args <- commandArgs(trailingOnly = TRUE)

if (length(args) >= 5) {
  model_name <- tolower(args[1])
  values <- args[2:5]
} else if (length(args) == 4) {
  model_name <- "logistic"
  values <- args[1:4]
} else {
  stop("Expected 4 arguments: age bmi blood_pressure exercise_hours or model_name age bmi blood_pressure exercise_hours")
}

# Convert input values
age <- as.numeric(values[1])
bmi <- as.numeric(values[2])
blood_pressure <- as.numeric(values[3])
exercise_hours <- as.numeric(values[4])

if (is.na(age) || is.na(bmi) || is.na(blood_pressure) || is.na(exercise_hours)) {
  stop("Invalid numeric input")
}

model_map <- c(
  logistic = "customer_health_model.rds",
  decision_tree = "customer_health_model_decision_tree.rds",
  random_forest = "customer_health_model_random_forest.rds",
  svm = "customer_health_model_svm.rds"
)

if (!(model_name %in% names(model_map))) {
  stop(paste(
    "Unsupported model:", model_name,
    ". Choose one of:",
    paste(names(model_map), collapse = ", ")
  ))
}

model_file <- file.path(getwd(), model_map[[model_name]])

if (!file.exists(model_file)) {
  stop(paste("Model file not found for", model_name, ":", model_file))
}

model <- readRDS(model_file)

if (model_name %in% c("random_forest", "svm")) {
  if (model_name == "random_forest") {
    if (!requireNamespace("randomForest", quietly = TRUE)) {
      stop("The randomForest package is required for random forest predictions.")
    }
    library(randomForest)
  }

  if (model_name == "svm") {
    if (!requireNamespace("e1071", quietly = TRUE)) {
      stop("The e1071 package is required for SVM predictions.")
    }
    library(e1071)
  }
}

new_customer <- data.frame(
  age = age,
  bmi = bmi,
  blood_pressure = blood_pressure,
  exercise_hours = exercise_hours
)

get_probability <- function(model_obj, model_type) {
  if (model_type == "svm") {
    prediction <- predict(model_obj, newdata = new_customer, probability = TRUE)
    probs <- attr(prediction, "probabilities")

    if (!is.null(probs)) {
      risk_column <- which(colnames(probs) %in% c("High Risk", "High_Risk", "high_risk", "1", "Yes", "yes", "At Risk", "at_risk"))
      if (length(risk_column) > 0) {
        return(as.numeric(probs[, risk_column[1]]))
      }
      return(as.numeric(probs[, 1]))
    }

    return(as.numeric(prediction == "High Risk"))
  }

  pred <- predict(model_obj, newdata = new_customer, type = if (model_type %in% c("decision_tree", "random_forest")) "prob" else "response")

  if (is.matrix(pred)) {
    risk_column <- which(colnames(pred) %in% c("High Risk", "High_Risk", "high_risk", "1", "Yes", "yes", "At Risk", "at_risk"))
    if (length(risk_column) > 0) {
      return(as.numeric(pred[, risk_column[1]]))
    }
    return(as.numeric(pred[, 1]))
  }

  if (is.data.frame(pred)) {
    risk_column <- which(colnames(pred) %in% c("High Risk", "High_Risk", "high_risk", "1", "Yes", "yes", "At Risk", "at_risk"))
    if (length(risk_column) > 0) {
      return(as.numeric(pred[, risk_column[1]]))
    }
    return(as.numeric(pred[[1]]))
  }

  as.numeric(pred)
}

probability <- get_probability(model, model_name)
probability <- as.numeric(probability[1])
probability <- max(min(probability, 1), 0)

prediction <- ifelse(probability >= 0.5, "High Risk", "Low Risk")

cat(prediction, "\n")
cat(probability, "\n")