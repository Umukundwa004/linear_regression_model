from datetime import datetime

from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field
import joblib
import numpy as np
from pathlib import Path

app = FastAPI(title="Bike Rental Prediction API", version="1.0.0")
current_dir = Path(__file__).parent

# Allow CORS for Flutter app
app.add_middleware(CORSMiddleware, allow_origins=["*"], allow_methods=["*"], allow_headers=["*"])

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

@app.post("/predict")
def predict(data: PredictionData):
    try:
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
def predict_batch(batch_data: dict):
    try:
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
    uvicorn.run(app, host="0.0.0.0", port=8005)
