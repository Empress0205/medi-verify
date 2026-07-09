# database.py
import pandas as pd
import os

def load_tmda_db(path=None):
    # If no path given, look for the CSV next to this file OR in current dir
    if path is None:
        script_dir = os.path.dirname(os.path.abspath(__file__))
        candidates = [
            os.path.join(script_dir, "medicine_database.CSV"),
            os.path.join(script_dir, "medicine_database.csv"),
            "medicine_database.CSV",
            "medicine_database.csv",
        ]
        for candidate in candidates:
            if os.path.exists(candidate):
                path = candidate
                break
        if path is None:
            raise FileNotFoundError(
                "medicine_database.CSV not found. Place it in the same folder as database.py"
            )

    df = pd.read_csv(path, skiprows=8, encoding='latin1', header=None, on_bad_lines='skip')

    df.columns = [
        'No', 'Product_Category', 'Certificate_Number', 'Brand_Name',
        'Classification', 'Generic_Name', 'Dosage_Form', 'Unnamed_7',
        'Active_Ingredients', 'Product_Strength', 'Registrant',
        'Registrant_Country', 'Local_Rep', 'Manufacturer',
        'Manufacturing_Country', 'Registration_Status'
    ]

    key_cols = ['Certificate_Number', 'Brand_Name', 'Manufacturer', 'Registration_Status']
    for col in key_cols:
        df[col] = df[col].fillna('').astype(str).str.strip().str.upper()

    print(f"✅ TMDA Database loaded successfully: {len(df):,} records")
    return df

db = load_tmda_db()