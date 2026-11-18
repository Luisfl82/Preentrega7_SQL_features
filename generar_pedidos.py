"""Genera pedidos de e-commerce de ejemplo en data/orders.csv"""
import numpy as np
import pandas as pd

rng = np.random.default_rng(11)
n = 1500
df = pd.DataFrame({
    "order_id": np.arange(1, n + 1),
    "user_id": rng.integers(1, 201, n),
    "order_date": pd.to_datetime("2024-01-01") + pd.to_timedelta(rng.integers(0, 365, n), unit="D"),
    "amount": rng.gamma(2.0, 40, n).round(2),
})
df["order_date"] = df["order_date"].dt.strftime("%Y-%m-%d")
df.to_csv("data/orders.csv", index=False)
print("Creado data/orders.csv")
