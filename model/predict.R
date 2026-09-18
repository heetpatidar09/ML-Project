# ============================================================
# WEATHER PREDICTION SCRIPT
# ============================================================

# Get arguments from Flask
args <- commandArgs(trailingOnly = TRUE)

# Check arguments
if (length(args) != 4) {
  stop("Expected 4 arguments: temp humidity wind pressure")
}

# Convert input values
temp <- as.numeric(args[1])
humidity <- as.numeric(args[2])
wind <- as.numeric(args[3])
pressure <- as.numeric(args[4])

# Validate input
if (
  is.na(temp) ||
  is.na(humidity) ||
  is.na(wind) ||
  is.na(pressure)
) {
  stop("Invalid numeric input")
}

# ============================================================
# LOAD MODEL
# ============================================================

model_file <- file.path(
  getwd(),
  "weather_model.rds"
)

if (!file.exists(model_file)) {
  stop(
    paste(
      "weather_model.rds not found at:",
      model_file
    )
  )
}

model <- readRDS(model_file)

# ============================================================
# CREATE NEW WEATHER DATA
# ============================================================

new_weather <- data.frame(
  temp = temp,
  humidity = humidity,
  wind = wind,
  pressure = pressure
)

# ============================================================
# MAKE PREDICTION
# ============================================================

probability <- predict(
  model,
  newdata = new_weather,
  type = "response"
)

prediction <- ifelse(
  probability >= 0.5,
  "Rain",
  "No Rain"
)

# ============================================================
# OUTPUT
# IMPORTANT:
# Flask reads line 1 as prediction
# Flask reads line 2 as probability
# ============================================================

cat(prediction, "\n")
cat(probability, "\n")