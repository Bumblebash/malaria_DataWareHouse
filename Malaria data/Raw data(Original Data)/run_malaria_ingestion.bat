@echo off 
echo ===================================================
echo STARTING MALARIA DATA PIPELINE INGESTION LOOP
echo ======================================================

:: Step 1: Install or verify missing depencies from the requirements file
echo Checking and installing project dependencies...
"C:\Python314\python.exe" -m pip install -r "D:\Data Analyst\MALARIA ANALYTICS\FULL PROJECT\Malaria data\Raw data(Original Data)\requirements.txt"

echo -----------------------------------------------------------------

:: Step 2: Execute the core python data pipeline
:: Run the script using the system's global Python execution wrapper
echo Executing Python data ingestion script.......
"C:\Python314\python.exe" "D:\Data Analyst\MALARIA ANALYTICS\FULL PROJECT\Malaria data\Raw data(Original Data)\Python_ingestion.py"


echo ========================================================================
echo   INGESTION PROCESS COMPLETE 
echo ==========================================================================