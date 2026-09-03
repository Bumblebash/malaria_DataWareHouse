# MalariaDataWareHouse 
Development of a data Warehouse for Malaria Records in Uganda Between 2020 to 2024 


# Table of Contents
1. Architecture  BackGround
2. Repository File Structure
3. The wide-Matrix Pipeline Breakdown
4. Database Schema Blueprint (Gold Layer)
5. Data Quality & Auditing Farmework(dbt)
6. Native Automation & Orchestration(SQL server Agent)
7. Analytical Perfomance & Benchmarks
8. Downstream Applications (ArcGIS & Data Science)
9. Getting Started & Installation
10. Academic Reference & Citation


## Architecture Background
- Unlike legacy infrastructures that rely heavily  on mapping blocks(e.g , SSIS) which might crash when headers change  or exceed character limits, this system utilizes a code-first pipeline:
  1. Bronze(Raw Landing Layer): Using Python to ingest wide matrix-column csv files into SQL server database(Landing Zone)(Extract-Load)
  2. Silver(Staging Layer): Horizontally unpivoted  the raw data using  dynamic SQL (CROSS APPLY VALUES) , Transfomed and inserted into the Permanent Staging Table.(Load - Transform)
  3. Gold(Analytical Layer): Finally ingested the data from the permanent staging table into an organised dimensional Star schema with historical tracking(SCD-2), using a virtual presenation Layer(rpt).
 
     
