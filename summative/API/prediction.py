"""
FastAPI service for the Youth Earning Potential model.

Mission: predict hourly cash income (RWF) for Rwandan youth (16-30) given
education, location, sector and hours worked, so that skills/opportunity
interventions can be targeted where they matter most.

Run locally:
    uv run uvicorn prediction:app --reload

Docs (Swagger UI) will be at:
    http://127.0.0.1:8000/docs
"""

import io
import os
from enum import Enum

import joblib
import numpy as np
import pandas as pd
from fastapi import FastAPI, File, HTTPException, UploadFile
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field

from model.train import RAW_COLUMNS, build_features, train_and_save

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
MODEL_DIR = os.path.join(BASE_DIR, "model")
MODEL_PATH = os.path.join(MODEL_DIR, "best_model.pkl")
SCALER_PATH = os.path.join(MODEL_DIR, "scaler.pkl")
COLUMNS_PATH = os.path.join(MODEL_DIR, "feature_columns.pkl")
DATA_PATH = os.path.join(MODEL_DIR, "training_data.csv")

app = FastAPI(
    title="Youth Earning Potential API",
    description=(
        "Predicts hourly cash income (RWF) for Rwandan youth (16-30) based on "
        "education, location, sector and hours worked. Built on the NISR Rwanda "
        "Labour Force Survey 2021, in support of youth skills and employment "
        "access initiatives."
    ),
    version="1.0.0",
)

ALLOWED_ORIGINS = [
    "http://localhost:3000",
    "http://localhost:8080",
    "http://127.0.0.1:3000",
]

app.add_middleware(
    CORSMiddleware,
    allow_origins=ALLOWED_ORIGINS,
    allow_credentials=False,   
    allow_methods=["GET", "POST"],   
    allow_headers=["Content-Type"],
)


# Request / response schemas

class EducationLevel(str, Enum):
    primary = "Primary"
    lower_secondary = "Lower_secondary"
    upper_secondary = "Upper_secondary"
    university = "University"


class Sex(str, Enum):
    male = "Male"
    female = "Female"


class UrbanRural(str, Enum):
    urban = "Urban"
    rural = "Rural"


class Province(str, Enum):
    kigali = "Kigali city"
    northern = "Northern Province"
    southern = "Southern Province"
    eastern = "Eastern Province"
    western = "Western Province"


class Sector(str, Enum):
    agriculture = "Agriculture"
    industry = "Industry"
    services = "Services"


class PredictionRequest(BaseModel):
    age: int = Field(..., ge=16, le=30, description="Age in years (youth range: 16-30)")
    hours_worked: float = Field(..., gt=0, le=112, description="Usual hours worked per week (realistic max ~112 = 16h/day)")
    education: EducationLevel = Field(..., description="Highest education level attained")
    sex: Sex = Field(..., description="Sex")
    urban_rural: UrbanRural = Field(..., description="Urban or rural residence")
    province: Province = Field(..., description="Province of residence")
    sector: Sector = Field(..., description="Sector of main employment")

    class Config:
        json_schema_extra = {
            "example": {
                "age": 24,
                "hours_worked": 40,
                "education": "Upper_secondary",
                "sex": "Female",
                "urban_rural": "Urban",
                "province": "Kigali city",
                "sector": "Services",
            }
        }


class PredictionResponse(BaseModel):
    predicted_hourly_income_rwf: float
    predicted_monthly_income_rwf: float


class RetrainResponse(BaseModel):
    message: str
    n_rows_trained_on: int
    test_mse: float
    test_r2: float



# Endpoints

@app.get("/", tags=["Health"])
def health_check():
    return {"status": "ok", "message": "Youth Earning Potential API is running. See /docs for Swagger UI."}


@app.post("/predict", response_model=PredictionResponse, tags=["Prediction"])
def predict(payload: PredictionRequest):
    """Predict hourly (and estimated monthly) cash income for a youth given their profile."""
    if not os.path.exists(MODEL_PATH):
        raise HTTPException(status_code=503, detail="Model not trained yet. Call /retrain first.")

    model = joblib.load(MODEL_PATH)
    scaler = joblib.load(SCALER_PATH)
    feature_columns = joblib.load(COLUMNS_PATH)

    raw_row = pd.DataFrame([{
        "income_hr": np.nan,  # placeholder, dropped before prediction
        "education": payload.education.value,
        "sex": payload.sex.value,
        "age": payload.age,
        "urban_rural": payload.urban_rural.value,
        "province": payload.province.value,
        "sector": payload.sector.value,
        "hours_worked": payload.hours_worked,
    }])

    features = build_features(raw_row.assign(income_hr=1.0))  # dummy income so build_features doesn't drop the row
    features = features.drop(columns=["log_income"])
    features = features.reindex(columns=feature_columns, fill_value=0)

    features_scaled = scaler.transform(features)
    log_pred = model.predict(features_scaled)[0]
    hourly = float(np.expm1(log_pred))
    monthly = hourly * payload.hours_worked * 4.33  # ~4.33 weeks/month

    return PredictionResponse(
        predicted_hourly_income_rwf=round(hourly, 2),
        predicted_monthly_income_rwf=round(monthly, 2),
    )


@app.post("/retrain", response_model=RetrainResponse, tags=["Retraining"])
def retrain(file: UploadFile = File(..., description="CSV with columns: " + ", ".join(RAW_COLUMNS))):
    """
    Trigger model retraining using newly uploaded data combined with the existing
    training set. The uploaded CSV must have the same raw columns as the original
    survey extract: income_hr, education, sex, age, urban_rural, province, sector,
    hours_worked.
    """
    try:
        contents = file.file.read()
        new_df = pd.read_csv(io.BytesIO(contents))
    except Exception as e:
        raise HTTPException(status_code=400, detail=f"Could not parse uploaded CSV: {e}")

    missing = set(RAW_COLUMNS) - set(new_df.columns)
    if missing:
        raise HTTPException(status_code=400, detail=f"Uploaded CSV is missing required columns: {missing}")

    existing_df = pd.read_csv(DATA_PATH) if os.path.exists(DATA_PATH) else pd.DataFrame(columns=RAW_COLUMNS)
    combined_df = pd.concat([existing_df, new_df[RAW_COLUMNS]], ignore_index=True)
    combined_df.to_csv(DATA_PATH, index=False)

    metrics = train_and_save(combined_df)

    return RetrainResponse(
        message="Model retrained successfully on combined dataset.",
        n_rows_trained_on=metrics["n_rows_trained_on"],
        test_mse=metrics["test_mse"],
        test_r2=metrics["test_r2"],
    )
