USE MLanding1;

-----Permanent Staging Table
CREATE TABLE Stg_Malaria_Permanent(

		BatchID UNIQUEIDENTIFIER NOT NULL,
		FacilityID NVARCHAR(MAX) NOT NULL,
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
		PRIMARY KEY (BatchID, Region, District, Year, Month, AgeGroup, Gender)
);




---Staging Table Population

CREATE TABLE Stg_Population_Permanent(
		BatchID UNIQUEIDENTIFIER NOT NULL,
		Region VARCHAR(100) NOT NULL,
		District VARCHAR(100) NOT NULL,
		Population_2020 INT NULL,
		Population_2021  INT NULL,
		Population_2022 INT NULL,
		Population_2023 INT NULL,
		Population_2024 INT NULL,
		DataQualityFlag VARCHAR(100) NULL,
		IngestionTimestamp DATETIME DEFAULT GETDATE(),
		PRIMARY KEY (BatchID , Region, District)

);


USE MLanding1;
GO

-- Prevent log spamming during the generation loop
SET NOCOUNT ON;

DECLARE @CurrentDate DATE = '2015-01-01';
DECLARE @TargetEndDate DATE = '2035-12-31';

-- Populate the table systematically day-by-day
WHILE @CurrentDate <= @TargetEndDate
BEGIN
    INSERT INTO dbo.DimDate (DateKey, FullDate, Year, Quarter, Month, MonthName, YearMonth)
    VALUES (
        -- Convert Date format directly into a compact integer surrogate key (e.g., 20240101)
        CAST(CONVERT(VARCHAR(8), @CurrentDate, 112) AS INT),
        @CurrentDate,
        YEAR(@CurrentDate),
        DATEPART(QUARTER, @CurrentDate),
        MONTH(@CurrentDate),
        DATENAME(MONTH, @CurrentDate),
        LEFT(CONVERT(VARCHAR(8), @CurrentDate, 112), 6)
    );

    SET @CurrentDate = DATEADD(DAY, 1, @CurrentDate);
END;
GO

-- Seed the system default historical date fallback record to catch missing date keys safely
INSERT INTO dbo.DimDate (DateKey, FullDate, Year, Quarter, Month, MonthName, YearMonth)
VALUES (19000101, '1900-01-01', 1900, 1, 1, 'UNKNOWN', '190001');
GO


SELECT * FROM DimDate;



----Stg_Malaria_Qaurantine
CREATE TABLE Stg_Malaria_Quarantine(
	BatchID  UNIQUEIDENTIFIER NOT NULL,
	FacilityID NVARCHAR(MaX),
	Region VARCHAR(100),
	District VARCHAR(100),
	Year INT,
	Month INT,
	AgeGroup NVARCHAR(20),
	Gender VARCHAR(10),
	ConfirmedCases INT,
	TreatedCases INT,
	PregnancyCases INT,
	TotalCasesRecorded INT,
	QuarantineReason NVARCHAR(MAX)
)


ALTER TABLE Stg_Malaria_Quarantine DROP COLUMN DataQualityFlag;
ALTER TABLE  Stg_Malaria_Quarantine ADD  	QuarantineReason NVARCHAR(MAX);