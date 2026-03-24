# Summative - Mobile App Regression Analysis

## Mission

I built a bike-rental demand predictor for urban mobility planning in tourist-heavy periods.
The model predicts hourly rental counts using weather, calendar, and time signals.
This helps operators reduce shortages, improve bike allocation, and cut idle inventory.
The use case is demand optimization for bike-sharing operations, not house-price prediction.

## Dataset Description And Source

- Source: Kaggle Bike Sharing Dataset (hour.csv)
- URL: https://www.kaggle.com/datasets/lakshmi25npathi/bike-sharing-dataset?select=hour.csv
- Volume: 17,379 hourly rows
- Variety: season, date/time features, holiday/working-day flags, weather, temperature, humidity, wind speed, and rental count target

## Linear Regression Task

- Notebook: summative/linear_regression/bike_rental_analysis.ipynb
- Script version: bikeRental_analysis.py
- Models implemented in code:

1. Linear Regression with gradient descent (SGDRegressor + epoch-wise loss tracking)
2. Decision Tree Regressor
3. Random Forest Regressor

- Visualizations included:

1. Correlation heatmap
2. Distribution/relationship plot for hourly rentals
3. Train vs test loss curve
4. Actual vs predicted scatter for the linear model

- Feature handling covered:

1. Dropping non-informative/leaky columns
2. Numeric conversion and preprocessing
3. Standardization via StandardScaler

- Best model persistence:

1. Model artifact saved after comparison by MSE
2. One-row prediction on test data included in code

## API (Task 2)

- API code: summative/API/prediction.py
- Prediction endpoint: POST /predict
- Batch endpoint: POST /predict-batch
- Retraining endpoint (model update trigger): POST /retrain with labeled CSV upload
- Built-in browser UI endpoint: GET /ui
- Validation and constraints: implemented with Pydantic BaseModel fields and numeric ranges
- CORS middleware: configured with explicit origins, methods, headers, and credentials (no wildcard)
- CORS env options:

1. ALLOWED_ORIGINS=http://localhost:3000,http://127.0.0.1:5173 (custom allowed list)
2. ALLOW_ALL_ORIGINS=true (dev only, sets Access-Control-Allow-Origin: \*)

### Local Swagger UI

- http://localhost:8005/docs

### Local Browser UI

- http://localhost:8005/ui

### Public Swagger UI (Render)

- Add your deployed URL here before submission: https://YOUR-RENDER-SERVICE.onrender.com/docs

## Flutter App

- App code: summative/FlutterApp/lib/main.dart
- One-page prediction UI includes:

1. Inputs for required model variables (date/time, season, weather, holiday, temperature, humidity, wind speed)
2. Predict button
3. Result or error display area
4. Runtime API endpoint indicator for debugging connectivity

## How To Run

### 1) Run API

1. Open terminal in summative/API
2. Install dependencies: pip install -r requirements.txt
3. Start API: uvicorn prediction:app --host 0.0.0.0 --port 8005 --reload
4. Open Swagger UI: http://localhost:8005/docs

### 2) Run Flutter App

1. Open terminal in summative/FlutterApp
2. Get packages: flutter pub get
3. Run (web): flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:8005
4. Run (Android emulator): flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8005

## Video Demo (Task 4)

- YouTube link (max 7 minutes, camera on): https://YOUR-YOUTUBE-LINK

## Required Demo Talking Points Checklist

1. Show mobile app predictions (not only web)
2. Show Swagger tests with valid and invalid inputs (datatype/range checks)
3. Explain model comparison using loss metrics
4. Explain why selected model fits this dataset/use case
5. Explain hyperparameters and how they affect performance
6. Explain retraining path with new data via /retrain endpoint
7. Explain CORS configuration basis

## Repository Structure

- summative/linear_regression/bike_rental_analysis.ipynb
- summative/API/prediction.py
- summative/API/requirements.txt
- summative/FlutterApp/
