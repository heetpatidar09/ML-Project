from flask import Flask, request, jsonify
from flask_cors import CORS
import subprocess
import os

app = Flask(__name__)
CORS(app)


@app.route("/")
def home():
    return jsonify({
        "message": "Weather Prediction API is running"
    })


@app.route("/predict", methods=["POST"])
def predict():

    try:
        data = request.get_json()

        temp = float(data["temp"])
        humidity = float(data["humidity"])
        wind = float(data["wind"])
        pressure = float(data["pressure"])

        result = subprocess.run(
            [
                "Rscript",
                "../model/predict.R",
                str(temp),
                str(humidity),
                str(wind),
                str(pressure)
            ],
            capture_output=True,
            text=True,
            cwd=os.path.dirname(os.path.abspath(__file__))
        )

        if result.returncode != 0:
            return jsonify({
                "error": result.stderr
            }), 500

        output = result.stdout.strip().splitlines()

        prediction = output[0]
        probability = float(output[1])

        return jsonify({
            "prediction": prediction,
            "probability": round(probability, 4),
            "probability_percent": round(probability * 100, 2),
            "input": {
                "temp": temp,
                "humidity": humidity,
                "wind": wind,
                "pressure": pressure
            }
        })

    except KeyError as e:
        return jsonify({
            "error": f"Missing field: {e.args[0]}"
        }), 400

    except ValueError:
        return jsonify({
            "error": "All input values must be numeric"
        }), 400

    except Exception as e:
        return jsonify({
            "error": str(e)
        }), 500


if __name__ == "__main__":
    app.run(debug=True)
