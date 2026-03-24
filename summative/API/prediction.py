from datetime import datetime
import os

from fastapi import FastAPI, HTTPException, Request
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field
import joblib
import numpy as np
from pathlib import Path

current_dir = Path(__file__).parent


def load_env_file(env_path: Path) -> None:
    if not env_path.exists():
        return
    for raw_line in env_path.read_text(encoding="utf-8").splitlines():
        line = raw_line.strip()
        if not line or line.startswith("#") or "=" not in line:
            continue
        key, value = line.split("=", 1)
        key = key.strip()
        value = value.strip().strip('"').strip("'")
        os.environ.setdefault(key, value)


load_env_file(current_dir / ".env")

app = FastAPI(title="Bike Rental Prediction API", version="1.0.0")

API_HOST = os.getenv("API_HOST", "0.0.0.0")
API_PORT = int(os.getenv("API_PORT", "8005"))
API_KEY = os.getenv("API_KEY", "")

allow_all_origins = os.getenv("ALLOW_ALL_ORIGINS", "true").lower() == "true"
allowed_origins_env = os.getenv("ALLOWED_ORIGINS", "")
allowed_origins = [o.strip() for o in allowed_origins_env.split(",") if o.strip()]
cors_origins = ["*"] if allow_all_origins or not allowed_origins else allowed_origins

# Allow CORS for Flutter app
app.add_middleware(CORSMiddleware, allow_origins=cors_origins, allow_methods=["*"], allow_headers=["*"])

# Load model and optional scaler.
model_path = current_dir / "bike_model.pkl"
if not model_path.exists():
    model_path = current_dir / "treemodel.pkl"

model = joblib.load(model_path) if model_path.exists() else None
scaler = joblib.load(current_dir / "scaler.pkl") if (current_dir / "scaler.pkl").exists() else None

# Define input validation
class PredictionData(BaseModel):
    date: str
    hour: int = Field(..., ge=0, le=23)
    holiday: int = Field(default=0, ge=0, le=1)
    weather: int = Field(..., ge=1, le=4)
    temp: float = Field(..., ge=-10, le=50)
    humidity: float = Field(..., ge=0, le=100)
    windspeed: float = Field(..., ge=0, le=50)


def get_season(month: int) -> int:
    if month in [3, 4, 5]:
        return 1
    if month in [6, 7, 8]:
        return 2
    if month in [9, 10, 11]:
        return 3
    return 4


def require_api_key(request: Request) -> None:
    # If API_KEY is empty in .env, auth is disabled for local development.
    if not API_KEY:
        return
    if request.headers.get("x-api-key") != API_KEY:
        raise HTTPException(status_code=401, detail="Invalid or missing API key")

@app.post("/predict")
def predict(data: PredictionData, request: Request):
    try:
        require_api_key(request)
        if model is None:
            raise HTTPException(status_code=500, detail="Model not loaded")

        date = datetime.strptime(data.date, "%Y-%m-%d")
        weekday = date.weekday()
        workingday = 1 if weekday < 5 else 0
        month = date.month
        year = 1 if date.year >= 2012 else 0
        season = get_season(month)

        features = np.array([[
            season,
            year,
            month,
            data.hour,
            data.holiday,
            weekday,
            workingday,
            data.weather,
            data.temp,
            data.humidity,
            data.windspeed,
        ]])

        input_features = scaler.transform(features) if scaler is not None else features
        prediction = model.predict(input_features)[0]

        return {"predicted_rentals": int(max(0, prediction))}
    except ValueError:
        raise HTTPException(status_code=422, detail="date must be in YYYY-MM-DD format")
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))

@app.post("/predict-batch")
def predict_batch(batch_data: dict, request: Request):
    try:
        require_api_key(request)
        if model is None:
            raise HTTPException(status_code=500, detail="Model not loaded")
        
        predictions = []
        for item in batch_data.get("predictions", []):
            data = PredictionData(**item)
            date = datetime.strptime(data.date, "%Y-%m-%d")
            weekday = date.weekday()
            workingday = 1 if weekday < 5 else 0
            month = date.month
            year = 1 if date.year >= 2012 else 0
            season = get_season(month)
            features = np.array([[season, year, month, data.hour, data.holiday,
                                 weekday, workingday, data.weather,
                                 data.temp, data.humidity, data.windspeed]])
            input_features = scaler.transform(features) if scaler is not None else features
            pred = model.predict(input_features)[0]
            predictions.append(max(0, pred))
        
        return {"predictions": [round(p, 2) for p in predictions], "average": round(np.mean(predictions), 2)}
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))

@app.get("/")
def root():
    return {"message": "Bike Rental API running", "docs": "/docs"}

@app.get("/model-info")
def model_info():
    return {
        "model": type(model).__name__ if model else "Not loaded",
        "scaler": type(scaler).__name__ if scaler else "Not loaded",
        "status": "Ready" if model and scaler else "Error"
    }

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host=API_HOST, port=API_PORT)
