import json

from backend.app import app


def test_home_route():
    client = app.test_client()
    response = client.get("/")
    assert response.status_code == 200
    data = response.get_json()
    assert data["status"] == "success"


def test_predict_accepts_model_selection():
    client = app.test_client()
    payload = {
        "age": 34,
        "bmi": 27.5,
        "blood_pressure": 128,
        "exercise_hours": 3,
        "model": "logistic"
    }
    response = client.post("/predict", data=json.dumps(payload), content_type="application/json")
    assert response.status_code == 200, response.get_data(as_text=True)
    data = response.get_json()
    assert "prediction" in data
    assert "probability" in data
    assert data["model"] == "logistic"


def test_models_route_lists_supported_models():
    client = app.test_client()
    response = client.get("/models")
    assert response.status_code == 200
    data = response.get_json()
    assert "models" in data
    assert "logistic" in data["models"]
    assert "decision_tree" in data["models"]
    assert "random_forest" in data["models"]
    assert "svm" in data["models"]
