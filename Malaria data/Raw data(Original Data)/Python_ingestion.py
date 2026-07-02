# %% [markdown]
# ## FILE EXPORTATION STEPS
# - **Step 1:**  Import the required Libraries.
# - **Step 2:**  Get the Absolute path of the current working Directory (Which contains our raw files) and Change Directory 
# - **Step 3:**  Get the absolute path of all our Csv files using **glob** library
# - **Step 4:**   Loop through one file at a time and read it into a data frame using **pandas**
# - **Step 5:**   Change the data columns to the desired datatypes for Usability
# - **Step 6:**   Connect to the SQL database and Push the raw file 

# %% [markdown]
# ###  Step 1: Import libraries

# %%
# Libraries
from sqlalchemy import create_engine
import pyodbc
import pandas as pd
import numpy as np
import glob
import os 
import urllib

# %% [markdown]
# - **sqlalchemy(create_engine):** - Acts as a translator; Provides connectivity between SQL and Python
# - **pyodbc(PythonOpenDatabaseConnection):** - Bridge/driver that allows python to physically connect to SQL server database.
# - **pandas:** - For reading csv files into dataframes (Structured tables)
# - **numpy:** - Handling Division by Zero in Population (#DIV/0!), mathematical computations to handle NAN values. 
# - **glob:** - File finder that allows us to search for files using wild cards.
# - **OS:** - Allows python to talk to windows operating system.
# - **urllib:** - Encoding Connection string for create_engine.

# %% [markdown]
# ### Step II: Understand the Absolute path of our raw files

# %%
# Fix directory mappings to clear out mixed formatting slashes
base_path = r'D:\Data Analyst\MALARIA ANALYTICS\FULL PROJECT\Malaria data\Raw data(Original Data)'
os.chdir(base_path)
print(f"Current Execution Directory: {os.getcwd()}")

# %% [markdown]
# ### Step III: Loop, Process and Read the files sequentially

# %%
# Target the specific files matching your file structural naming rules
search_path = os.path.join(base_path, 'Raw data', 'Jamir Data *.csv')
all_files = glob.glob(search_path)
print(f"Detected {len(all_files)} target spreadsheets for ingestion pipeline processing.")

# Step 1: Define SQL Server connection parameters
server = "DESKTOP-U507UFU\\MSSQLSERVER01"
database = "MLanding1"

conn_str = (
    "Driver={ODBC Driver 17 for SQL Server};"
    f"Server={server};"
    f"Database={database};"
    "Trusted_Connection=yes;"
)
params = urllib.parse.quote_plus(conn_str)
engine = create_engine(f"mssql+pyodbc:///?odbc_connect={params}", fast_executemany=True)

# Loop over files and push them safely one by one
for file in all_files:
    file_name = os.path.basename(file)
    print(f"Processing File Target: {file_name}")
    
    # Extract the numerical year out of the filename string to dynamically name the DB tables
    # e.g., 'Jamir data 2024.csv' -> Destination Table: 'Malaria2024'
    file_year = "".join(filter(str.isdigit, file_name))
    if not file_year:
        file_year = "Unknown"
    target_table = f"Malaria{file_year}"
    
    # Python reads long headers perfectly without truncation errors
    df1 = pd.read_csv(file)

    # %% [markdown]
    # ### Step IV: Change columns to respective data types
    
    # Adjust numeric data types safely
    for col in df1.columns:
        if pd.api.types.is_numeric_dtype(df1[col]):
            if (df1[col].dropna() % 1 == 0).all():
                df1[col] = df1[col].astype("Int64")   # Nullable integer
            else:
                df1[col] = df1[col].astype("float")
        else:
            df1[col] = df1[col].astype("str")
            df1[col] = df1[col].replace(['nan', 'None', '<NA>'], np.nan)

    # %% [markdown]
    # ### Step V: Push the raw files to the SQL server Database
    
    print(f"Streaming data framework rows into landing table: {target_table}...")
    
    # Using 'replace' for landing layer so SQL Server dynamically builds the wide table structure
    df1.to_sql(
        name=target_table,
        con=engine,
        if_exists="replace",
        index=False,
        chunksize=5000
    )
    print(f"Successfully processed and migrated {len(df1)} rows to target table.")

print("All database landing staging file processes are fully complete.")
