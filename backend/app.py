from flask import Flask, request, jsonify
from flask_cors import CORS

import subprocess
import os
import shutil


# ============================================================
# FLASK SETUP
# ============================================================

app = Flask(__name__)
CORS(app)


# ============================================================
# PROJECT PATHS
# ============================================================

# Location of this file:
# ML Project/backend/app.py

BACKEND_DIR = os.path.dirname(
    os.path.abspath(__file__)
)

# Go one level up:
# ML Project/
PROJECT_DIR = os.path.dirname(
    BACKEND_DIR
)

# Model directory:
# ML Project/model/
MODEL_DIR = os.path.join(
    PROJECT_DIR,
    "model"
)

# R prediction script:
# ML Project/model/predict.R
PREDICT_SCRIPT = os.path.join(
    MODEL_DIR,
    "predict.R"
)

# R model:
# ML Project/model/weather_model.rds
MODEL_FILE = os.path.join(
    MODEL_DIR,
    "weather_model.rds"
)


# ============================================================
# DEBUG INFORMATION
# ============================================================

print("==============================================")
print("WEATHER PREDICTION API")
print("==============================================")

print("Backend directory:")
print(BACKEND_DIR)

print("\nProject directory:")
print(PROJECT_DIR)

print("\nModel directory:")
print(MODEL_DIR)

print("\nPrediction script:")
print(PREDICT_SCRIPT)

print("\nModel file:")
print(MODEL_FILE)

print("==============================================")


# ============================================================
# HOME ROUTE
# ============================================================

@app.route("/", methods=["GET"])
def home():

    return jsonify({
        "status": "success",
        "message": "Weather Prediction API is running",
        "endpoint": "/predict"
    })


# ============================================================
# PREDICT ROUTE
# ============================================================

@app.route("/predict", methods=["POST"])
def predict():

    try:

        # ----------------------------------------------------
        # GET JSON DATA
        # ----------------------------------------------------

        data = request.get_json()

        if data is None:
            return jsonify({
                "error": "No JSON data received"
            }), 400


        # ----------------------------------------------------
        # READ INPUT
        # ----------------------------------------------------

        temp = float(data["temp"])
        humidity = float(data["humidity"])
        wind = float(data["wind"])
        pressure = float(data["pressure"])


        # ----------------------------------------------------
        # CHECK MODEL DIRECTORY
        # ----------------------------------------------------

        if not os.path.isdir(MODEL_DIR):

            return jsonify({
                "error": "Model folder not found",
                "expected_path": MODEL_DIR
            }), 500


        # ----------------------------------------------------
        # CHECK predict.R
        # ----------------------------------------------------

        if not os.path.isfile(PREDICT_SCRIPT):

            return jsonify({
                "error": "predict.R not found",
                "expected_path": PREDICT_SCRIPT
            }), 500


        # ----------------------------------------------------
        # CHECK weather_model.rds
        # ----------------------------------------------------

        if not os.path.isfile(MODEL_FILE):

            return jsonify({
                "error": "weather_model.rds not found",
                "expected_path": MODEL_FILE,
                "message": "Run weather_model.R first to create the model."
            }), 500


        # ----------------------------------------------------
        # FIND RSCRIPT
        # ----------------------------------------------------

        rscript = shutil.which("Rscript")

        if rscript is None:

            return jsonify({
                "error": "Rscript not found",
                "message": "Make sure R is installed and Rscript is added to Windows PATH."
            }), 500


        print("\n==============================================")
        print("NEW PREDICTION")
        print("==============================================")

        print("Temperature:", temp)
        print("Humidity:", humidity)
        print("Wind:", wind)
        print("Pressure:", pressure)

        print("\nRscript:", rscript)
        print("Model directory:", MODEL_DIR)
        print("Predict script:", PREDICT_SCRIPT)


        # ----------------------------------------------------
        # RUN R SCRIPT
        # ----------------------------------------------------

        result = subprocess.run(
            [
                rscript,
                PREDICT_SCRIPT,
                str(temp),
                str(humidity),
                str(wind),
                str(pressure)
            ],
            capture_output=True,
            text=True,
            cwd=MODEL_DIR
        )


        # ----------------------------------------------------
        # DISPLAY R OUTPUT
        # ----------------------------------------------------

        print("\nR STDOUT:")
        print(result.stdout)

        print("\nR STDERR:")
        print(result.stderr)

        print("\nR RETURN CODE:")
        print(result.returncode)


        # ----------------------------------------------------
        # CHECK R ERROR
        # ----------------------------------------------------

        if result.returncode != 0:

            return jsonify({
                "error": "R model prediction failed",
                "details": result.stderr,
                "stdout": result.stdout
            }), 500


        # ----------------------------------------------------
        # READ R OUTPUT
        # ----------------------------------------------------

        output = result.stdout.strip().splitlines()


        if len(output) < 2:

            return jsonify({
                "error": "Invalid response from R model",
                "r_output": result.stdout
            }), 500


        # First line = Rain / No Rain
        prediction = output[0].strip()

        # Second line = probability
        probability = float(
            output[1].strip()
        )


        # ----------------------------------------------------
        # RETURN RESULT
        # ----------------------------------------------------

        return jsonify({

            "status": "success",

            "prediction": prediction,

            "probability": round(
                probability,
                4
            ),

            "probability_percent": round(
                probability * 100,
                2
            ),

            "input": {

                "temp": temp,

                "humidity": humidity,

                "wind": wind,

                "pressure": pressure
            }
        })


    # ========================================================
    # ERRORS
    # ========================================================

    except KeyError as e:

        return jsonify({
            "error": f"Missing field: {e.args[0]}"
        }), 400


    except ValueError:

        return jsonify({
            "error": "All input values must be numeric"
        }), 400


    except FileNotFoundError:

        return jsonify({
            "error": "Rscript could not be executed",
            "message": "Check your R installation and PATH."
        }), 500


    except Exception as e:

        print("Python error:", str(e))

        return jsonify({
            "error": str(e)
        }), 500


# ============================================================
# START SERVER
# ============================================================

if __name__ == "__main__":

    app.run(
        host="127.0.0.1",
        port=5000,
        debug=True
    )