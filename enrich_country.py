import duckdb
import pandas as pd
import geopandas as gpd
import gc

# Connect to DuckDB warehouse
conn = duckdb.connect("warehouse/ookla.duckdb")

# Final output table
conn.execute("DROP TABLE IF EXISTS performance_with_country")

# Load country boundary shapefile
shapefile_path = "data/reference/ne_110m_admin_0_countries/ne_110m_admin_0_countries.shp"

world = gpd.read_file(shapefile_path)

# Keep only country name and geometry
world = world[["ADMIN", "geometry"]].rename(columns={"ADMIN": "country"})

# Make sure CRS matches lat/lon coordinates
world = world.to_crs("EPSG:4326")

batch_size = 100_000
offset = 0
first_batch = True
total_processed = 0

while True:
    df = conn.execute(f"""
        SELECT *
        FROM performance_with_geo
        LIMIT {batch_size}
        OFFSET {offset}
    """).fetchdf()

    if df.empty:
        break

    print(f"Processing rows {offset} to {offset + len(df)}")

    # Convert lat/lon into geometry points
    points = gpd.GeoDataFrame(
        df,
        geometry=gpd.points_from_xy(df["longitude"], df["latitude"]),
        crs="EPSG:4326"
    )

    # Spatial join: assign country based on point inside country polygon
    enriched = gpd.sjoin(
        points,
        world,
        how="left",
        predicate="within"
    )

    # Drop geometry/helper columns before saving to DuckDB
    enriched = enriched.drop(columns=["geometry", "index_right"])

    # Register current batch as temporary DuckDB table
    conn.register("batch_df", enriched)

    if first_batch:
        conn.execute("""
            CREATE TABLE performance_with_country AS
            SELECT * FROM batch_df
        """)
        first_batch = False
    else:
        conn.execute("""
            INSERT INTO performance_with_country
            SELECT * FROM batch_df
        """)

    # Memory cleanup
    conn.unregister("batch_df")
    del df
    del points
    del enriched
    gc.collect()

    total_processed += batch_size
    offset += batch_size

    # Progress check
    check = conn.execute("""
        SELECT COUNT(*) AS total_rows,
               COUNT(country) AS matched_country_rows
        FROM performance_with_country
    """).fetchdf()

    print(check)
    print(f"Completed batch. Total processed so far: {offset}")

print("DONE: Created final table performance_with_country")

final_check = conn.execute("""
    SELECT COUNT(*) AS total_rows,
           COUNT(country) AS matched_country_rows
    FROM performance_with_country
""").fetchdf()

print(final_check)

preview = conn.execute("""
    SELECT latitude, longitude, country
    FROM performance_with_country
    LIMIT 10
""").fetchdf()

print(preview)

conn.close()