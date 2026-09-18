// script.js
// Frontend logic for the Weather Prediction app.
// Sends the form's weather inputs to the R plumber API (plumber_api.R) and
// displays the returned prediction.
//
// Make sure the API is running first:
//   Rscript run_api.R
// (it listens on http://127.0.0.1:8000)

const API_URL = "http://127.0.0.1:8000/predict";

const form = document.getElementById("weather-form");
const resultBox = document.getElementById("result");

form.addEventListener("submit", async function (event) {
  event.preventDefault();

  const payload = {
    temp: parseFloat(document.getElementById("temp").value),
    humidity: parseFloat(document.getElementById("humidity").value),
    wind: parseFloat(document.getElementById("wind").value),
    pressure: parseFloat(document.getElementById("pressure").value)
  };

  showResult("Predicting...", null);

  try {
    const response = await fetch(API_URL, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(payload)
    });

    if (!response.ok) {
      throw new Error(`Server responded with status ${response.status}`);
    }

    const data = await response.json();
    const prediction = data.prediction;
    const probability = data.probability;

    const label = prediction === "Rain" ? "☔ Rain" : "☀️ No Rain";
    showResult(
      `${label} — probability: ${(probability * 100).toFixed(1)}%`,
      prediction === "Rain" ? "rain" : "no-rain"
    );
  } catch (err) {
    showResult(
      "Could not reach the prediction API. Is plumber running on port 8000?",
      "error"
    );
    console.error(err);
  }
});

function showResult(message, type) {
  resultBox.textContent = message;
  resultBox.className = "visible" + (type ? " " + type : "");
}