"""Ejecuta features_churn.sql con DuckDB y guarda data/features.csv"""
import duckdb

with open("features_churn.sql", encoding="utf-8") as f:
    consulta = f.read()

df = duckdb.sql(consulta).df()
print(df.head(10).to_string(index=False))
df.to_csv("data/features.csv", index=False)
print(f"\nFeatures guardadas en data/features.csv ({len(df)} usuarios)")
