# Weather prediction model in R
# Predicts: 1 = rain, 0 = no rain

# Create sample weather dataset
weather_data <- data.frame(
  temp = c(28, 30, 22, 24, 29, 21, 25, 20, 27, 19, 31, 18),
  humidity = c(80, 75, 90, 85, 78, 92, 88, 95, 70, 96, 72, 97),
  wind = c(8, 7, 12, 10, 6, 14, 11, 15, 5, 16, 7, 18),
  pressure = c(1012, 1010, 1008, 1006, 1011, 1005, 1007, 1003, 1014, 1002, 1013, 1004),
  rain = c(1, 1, 1, 1, 0, 1, 1, 1, 0, 1, 0, 1)
)

# View dataset
print(weather_data)

# Split data into training and testing sets
set.seed(123)
train_index <- sample(1:nrow(weather_data), 0.8 * nrow(weather_data))
train_data <- weather_data[train_index, ]
test_data <- weather_data[-train_index, ]

# Train logistic regression model
model <- glm(
  rain ~ temp + humidity + wind + pressure,
  data = train_data,
  family = binomial
)

# View model summary
summary(model)

# Predict on test data
predicted_prob <- predict(model, newdata = test_data, type = "response")
predicted_class <- ifelse(predicted_prob >= 0.5, 1, 0)

# Compare actual vs predicted
result <- data.frame(
  actual = test_data$rain,
  predicted = predicted_class,
  probability = predicted_prob
)

print(result)

# Accuracy
accuracy <- mean(result$actual == result$predicted)
cat("Model accuracy:", accuracy, "\n")

# Make prediction for a new day
new_weather <- data.frame(
  temp = 26,
  humidity = 82,
  wind = 9,
  pressure = 1011
)

new_prob <- predict(model, newdata = new_weather, type = "response")
new_prediction <- ifelse(new_prob >= 0.5, "Rain", "No Rain")

cat("Prediction probability:", new_prob, "\n")
cat("Prediction:", new_prediction, "\n")

# Save model
saveRDS(model, "weather_model.rds")