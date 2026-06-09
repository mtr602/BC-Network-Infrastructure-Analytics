import duckdb
import pandas as pd
from pyquadkey2.quadkey import QuadKey

conn = duckdb.connect("warehouse/ookla.duckdb")

conn.execute("DROP TABLE IF EXISTS performance_with_geo")

batch_size = 100_000
offset = 0
first_batch = True

def quadkey_to_geo(qk):
    tile = QuadKey(qk)
    lat, lon = tile.to_geo()
    return pd.Series([lat, lon])

while True:
    df = conn.execute(f"""
        SELECT *
        FROM raw_performance
        LIMIT {batch_size}
        OFFSET {offset}
    """).fetchdf()

    if df.empty:
        break

    print(f"Processing rows {offset} to {offset + len(df)}")

    df[["latitude", "longitude"]] = df["quadkey"].apply(quadkey_to_geo)

    conn.register("batch_df", df)

    if first_batch:
        conn.execute("CREATE TABLE performance_with_geo AS SELECT * FROM batch_df")
        first_batch = False
    else:
        conn.execute("INSERT INTO performance_with_geo SELECT * FROM batch_df")

    offset += batch_size

print("Done. Created table: performance_with_geo")