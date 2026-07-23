# Youth Earning Potential — Rwanda

**Mission:** Reduce youth unemployment in Rwanda by identifying which factors — education,
location, sector — most affect earning potential, so that skills and opportunity-access
interventions can be targeted where they matter most. This model predicts hourly cash income
for employed Rwandan youth (16–30) using the **NISR Rwanda Labour Force Survey 2021**.

## API

Once deployed, the Swagger UI (interactive API docs) will be publicly available at:

**https://linear-regression-model-kkrq.onrender.com/docs** 

### Endpoints
- `GET /` — health check
- `POST /predict` — predict hourly & monthly income given a youth's profile
- `POST /retrain` — upload a CSV of new labour-force-style rows to retrain the model on combined data

## Running locally

```bash
# from the repo root (where this README and pyproject.toml live)
uv sync
cd summative/API
uv run --project ../.. uvicorn prediction:app --reload
```

Then open http://127.0.0.1:8000/docs in your browser.


## Project structure

```
linear_regression_model/
├── summative/
│   ├── linear_regression/
│   │   └── multivariate.ipynb      # Task 1: EDA, feature engineering, model comparison
│   ├── API/
│   │   ├── prediction.py           # Task 2: FastAPI service
│   │   ├── requirements.txt
│   │   └── model/
│   │       ├── train.py            # shared preprocessing + training, used by notebook & /retrain
│   │       ├── best_model.pkl
│   │       ├── scaler.pkl
│   │       ├── feature_columns.pkl
│   │       └── training_data.csv
│   └── FlutterApp/                 # Task 3: Flutter mobile app
├── pyproject.toml
└── uv.lock
```

## Dataset

National Institute of Statistics of Rwanda (NISR), Rwanda Labour Force Survey 2021 — annual
estimates from four quarterly CAPI rounds (Feb/May/Aug/Nov 2021), covering employment status,
income, education, and location for individuals aged 16+.
