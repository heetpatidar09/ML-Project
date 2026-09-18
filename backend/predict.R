args <- commandArgs(trailingOnly = TRUE)

temp <- as.numeric(args[1])
humidity <- as.numeric(args[2])
wind <- as.numeric(args[3])
pressure <- as.numeric(args[4])

model <- readRDS("weather_model.rds")

new_weather <- data.frame(
  temp = temp,
  humidity = humidity,
  wind = wind,
  pressure = pressure
)

probability <- predict(
  model,
  newdata = new_weather,
  type = "response"
)

prediction <- ifelse(probability >= 0.5, "Rain", "No Rain")

cat(prediction, "\n")
cat(probability, "\n")