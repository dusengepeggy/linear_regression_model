"""
Shared training pipeline for the youth-income model.

"""

import os

import joblib
import numpy as np
import pandas as pd
from sklearn.ensemble import RandomForestRegressor
from sklearn.model_selection import train_test_split
from sklearn.preprocessing import StandardScaler

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
MODEL_PATH = os.path.join(BASE_DIR, "best_model.pkl")
SCALER_PATH = os.path.join(BASE_DIR, "scaler.pkl")
COLUMNS_PATH = os.path.join(BASE_DIR, "feature_columns.pkl")
DATA_PATH = os.path.join(BASE_DIR, "training_data.csv")

EDU_MAP = {"Primary": 1, "Lower_secondary": 2, "Upper_secondary": 3, "University": 4}

RAW_COLUMNS = [
    "income_hr", "education", "sex", "age", "urban_rural", "province", "sector", "hours_worked",
]

PROVINCES = ["Eastern Province", "Kigali city", "Northern Province", "Southern Province", "Western Province"]
SECTORS = ["Agriculture", "Industry", "Services"]


def build_features(raw_df: pd.DataFrame) -> pd.DataFrame:
    """Turn raw survey-shaped rows into the encoded feature matrix the model expects.
    Mirrors the feature engineering decisions made in the notebook, including
    deliberately NOT using wealth_quintile (dropped there due to target leakage).
    """
    data = raw_df.copy()
    data["education_ord"] = data["education"].map(EDU_MAP)
    data["sex_male"] = (data["sex"] == "Male").astype(int)
    data["urban"] = (data["urban_rural"] == "Urban").astype(int)

    data = pd.get_dummies(data, columns=["province", "sector"])

    # Ensure every known category column exists even if absent from this batch
    for p in PROVINCES:
        col = f"province_{p}"
        if col not in data.columns:
            data[col] = False
    for s in SECTORS:
        col = f"sector_{s}"
        if col not in data.columns:
            data[col] = False

    data["log_income"] = np.log1p(data["income_hr"])
    keep = ["age", "hours_worked", "education_ord", "sex_male", "urban"]
    keep += [f"province_{p}" for p in PROVINCES if p != "Eastern Province"]  # drop_first-style baseline
    keep += [f"sector_{s}" for s in SECTORS if s != "Agriculture"]
    keep += ["log_income"]
    return data[keep].dropna()


def train_and_save(raw_df: pd.DataFrame) -> dict:
    """Train a fresh Random Forest on raw_df and overwrite the saved model artifacts."""
    model_df = build_features(raw_df)
    X = model_df.drop(columns=["log_income"])
    y = model_df["log_income"]

    X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2, random_state=42)

    scaler = StandardScaler()
    X_train_scaled = scaler.fit_transform(X_train)
    X_test_scaled = scaler.transform(X_test)

    model = RandomForestRegressor(n_estimators=200, max_depth=8, random_state=42, n_jobs=-1)
    model.fit(X_train_scaled, y_train)

    from sklearn.metrics import mean_squared_error, r2_score
    pred = model.predict(X_test_scaled)
    metrics = {
        "test_mse": float(mean_squared_error(y_test, pred)),
        "test_r2": float(r2_score(y_test, pred)),
        "n_rows_trained_on": int(len(model_df)),
    }

    joblib.dump(model, MODEL_PATH)
    joblib.dump(scaler, SCALER_PATH)
    joblib.dump(list(X.columns), COLUMNS_PATH)

    return metrics


if __name__ == "__main__":
    df = pd.read_csv(DATA_PATH)
    result = train_and_save(df)
    print("Retrained on", DATA_PATH)
    print(result)
