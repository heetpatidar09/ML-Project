from flask import Flask, request, jsonify
from flask_cors import CORS

import os
import shutil
import subprocess


app = Flask(__name__)
CORS(app)


BACKEND_DIR = os.path.dirname(os.path.abspath(__file__))
PROJECT_DIR = os.path.dirname(BACKEND_DIR)
MODEL_DIR = os.path.join(PROJECT_DIR, "model")
PREDICT_SCRIPT = os.path.join(MODEL_DIR, "predict.R")
TRAIN_SCRIPT = os.path.join(MODEL_DIR, "customer_health_model.R")

MODEL_FILES = {
    "logistic": os.path.join(MODEL_DIR, "customer_health_model.rds"),
    "decision_tree": os.path.join(MODEL_DIR, "customer_health_model_decision_tree.rds"),
    "random_forest": os.path.join(MODEL_DIR, "customer_health_model_random_forest.rds"),
    "svm": os.path.join(MODEL_DIR, "customer_health_model_svm.rds"),
}

MODEL_LABELS = {
    "logistic": "Logistic Regression",
    "decision_tree": "Decision Tree",
    "random_forest": "Random Forest",
    "svm": "Support Vector Machine"
}


@app.route("/", methods=["GET"])
def home():
    return jsonify({
        "status": "success",
        "message": "Customer Health Risk Prediction API is running",
        "endpoint": "/predict",
        "available_models": list(MODEL_FILES.keys())
    })


@app.route("/models", methods=["GET"])
def list_models():
    models = [
        {
            "name": name,
            "label": MODEL_LABELS.get(name, name),
            "file": MODEL_FILES[name]
        }
        for name in MODEL_FILES
    ]

    return jsonify({
        "status": "success",
        "models": list(MODEL_FILES.keys()),
        "details": models,
        "default": "logistic"
    })


@app.route("/predict", methods=["POST"])
def predict():
    try:
        data = request.get_json(silent=True)

        if data is None:
            return jsonify({"error": "No JSON data received"}), 400

        age = float(data.get("age"))
        bmi = float(data.get("bmi"))
        blood_pressure = float(data.get("blood_pressure"))
        exercise_hours = float(data.get("exercise_hours"))
        model_name = str(data.get("model", "logistic")).strip().lower()

        if model_name not in MODEL_FILES:
            return jsonify({
                "error": "Unsupported model type",
                "supported_models": list(MODEL_FILES.keys())
            }), 400

        if not os.path.isdir(MODEL_DIR):
            return jsonify({
                "error": "Model folder not found",
                "expected_path": MODEL_DIR
            }), 500

        if not os.path.isfile(PREDICT_SCRIPT):
            return jsonify({
                "error": "predict.R not found",
                "expected_path": PREDICT_SCRIPT
            }), 500

        rscript = shutil.which("Rscript")

        if rscript is None:
            return jsonify({
                "error": "Rscript not found",
                "message": "Make sure R is installed and Rscript is added to Windows PATH."
            }), 500

        if not os.path.isfile(MODEL_FILES[model_name]):
            if not os.path.isfile(TRAIN_SCRIPT):
                return jsonify({
                    "error": "Training script not found",
                    "expected_path": TRAIN_SCRIPT
                }), 500

            subprocess.run(
                [rscript, TRAIN_SCRIPT],
                capture_output=True,
                text=True,
                cwd=MODEL_DIR
            )

        if not os.path.isfile(MODEL_FILES[model_name]):
            return jsonify({
                "error": f"{model_name} model file not found",
                "expected_path": MODEL_FILES[model_name],
                "message": "Run customer_health_model.R first to create all model files."
            }), 500

        result = subprocess.run(
            [
                rscript,
                PREDICT_SCRIPT,
                model_name,
                str(age),
                str(bmi),
                str(blood_pressure),
                str(exercise_hours)
            ],
            capture_output=True,
            text=True,
            cwd=MODEL_DIR
        )

        if result.returncode != 0:
            return jsonify({
                "error": "R model prediction failed",
                "details": result.stderr,
                "stdout": result.stdout
            }), 500

        output = result.stdout.strip().splitlines()

        if len(output) < 2:
            return jsonify({
                "error": "Invalid response from R model",
                "r_output": result.stdout
            }), 500

        prediction = output[0].strip()
        probability = float(output[1].strip())

        return jsonify({
            "status": "success",
            "prediction": prediction,
            "probability": round(probability, 4),
            "probability_percent": round(probability * 100, 2),
            "model": model_name,
            "model_label": MODEL_LABELS.get(model_name, model_name),
            "input": {
                "age": age,
                "bmi": bmi,
                "blood_pressure": blood_pressure,
                "exercise_hours": exercise_hours
            }
        })

    except KeyError as e:
        return jsonify({"error": f"Missing field: {e.args[0]}"}), 400

    except TypeError:
        return jsonify({"error": "All input values must be numeric"}), 400

    except ValueError:
        return jsonify({"error": "All input values must be numeric"}), 400

    except FileNotFoundError:
        return jsonify({
            "error": "Rscript could not be executed",
            "message": "Check your R installation and PATH."
        }), 500

    except Exception as e:
        return jsonify({"error": str(e)}), 500


if __name__ == "__main__":
    app.run(host="127.0.0.1", port=5000, debug=True)
