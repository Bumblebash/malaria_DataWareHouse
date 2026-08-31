USE MLanding1;

-----Permanent Staging Table
CREATE TABLE Stg_Malaria_Permanent(
		BatchID UNIQUEIDENTIFIER NOT NULL,
		FacilityID NVARCHAR(100) NOT NULL,
		Region VARCHAR(100) NOT NULL,
		District VARCHAR(100) NOT NULL,
		Year INT NOT NULL,
		Month INT NOT NULL,
		AgeGroup VARCHAR(50) NOT NULL,
		Gender VARCHAR(20) NOT NULL,
		ConfirmedCases INT DEFAULT 0,
		TreatedCases INT DEFAULT 0,
		PregnancyCases INT DEFAULT 0,
		TotalCasesRecorded INT DEFAULT 0,
		DataQualityFlag VARCHAR(100) NULL,
		IngestionTimestamp DATETIME DEFAULT GETDATE(),
		PRIMARY KEY (BatchID, Region, District, Year, Month, AgeGroup, Gender, FacilityID)
);




---Staging Table Population

CREATE TABLE Stg_Population_Pivoted(
		BatchID UNIQUEIDENTIFIER NULL,
		Region VARCHAR(100) NOT NULL,
		District VARCHAR(100) NOT NULL,
		Population_2020 INT NULL,
		Population_2021  INT NULL,
		Population_2022 INT NULL,
		Population_2023 INT NULL,
		Population_2024 INT NULL,
		DataQualityFlag VARCHAR(100) NULL,
		IngestionTimestamp DATETIME DEFAULT GETDATE(),
		PRIMARY KEY (Region, District)

);

---STAGING TABLE 2(POPULATION) Stg_Population_Unpivoted

CREATE TABLE Stg_Population_Unpivoted(
				BatchID UNIQUEIDENTIFIER NULL,
				Region VARCHAR(100) NOT NULL,
				District VARCHAR(100) NOT NULL,
				Year INT,
				Estimated_Population INT 
);





USE MLanding1

SELECT * FROM DimDate;

GO



