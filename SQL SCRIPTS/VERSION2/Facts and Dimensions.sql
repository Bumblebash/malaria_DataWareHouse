USE MLanding1;


---Age group Table
CREATE TABLE DimAgeGroup(
	AgeKey INT IDENTITY(1,1) PRIMARY KEY,
	AgeGroup NVARCHAR(50) NOT NULL UNIQUE,
	ValidFrom DATETIME NOT NULL,
	ValidTo DATETIME  NULL,
	IsCurrent  BIT DEFAULT 1
);


SELECT * FROM Stg_Malaria_Permanent;


	---Date Table
	CREATE TABLE DimDate(
		DateKey INT PRIMARY KEY, --YYYYMMDD
		FullDate DATE NOT NULL,
		Year INT NOT NULL,
		Quarter INT NOT NULL,
		Month INT NOT NULL,
		MonthName NVARCHAR(20) NOT NULL,
		YearMonth VARCHAR(8) NOT NULL
	);
	SELECT * FROM DimDate;

----Gender Table

CREATE TABLE DimGender(
		GenderKey INT IDENTITY(1,1) PRIMARY KEY,
		Gender VARCHAR(20) NOT NULL UNIQUE

);


---Geography Key
CREATE TABLE DimGeography(
   GeographyKey INT IDENTITY(1,1) PRIMARY KEY,
   Source_FacilityID NVARCHAR(100)  NOT NULL,
   DistrictName NVARCHAR(120) NOT NULL,
   RegionName NVARCHAR(100) NOT NULL,
   IsCity BIT DEFAULT 0,
   ValidFrom DATETIME NOT NULL,
   ValidTo DATETIME NULL,
   IsCurrent BIT DEFAULT 1
   )



---- Configuring Fact Tables to capture the Execution Lineage Token (BatchID)
CREATE TABLE Fact_Malaria(
	   FactID BIGINT IDENTITY(1,1) PRIMARY KEY,
	   BatchID UNIQUEIDENTIFIER NOT NULL, ---Core tracking lineage Token
	   DateKey INT NOT NULL,
	   GenderKey INT NOT NULL,
	   AgeKey INT NOT NULL,
	   ConfirmedCases INT NOT NULL,
	   TreatedCases INT NOT NULL,
	   PregnantCases INT NOT NULL,
	   TotalCases INT NOT NULL,
	   LoadDate DATETIME DEFAULT GETDATE(),
	CONSTRAINT FK_Fact_Gender FOREIGN KEY(GenderKey) REFERENCES DimGender(GenderKey),
	CONSTRAINT FK_Geography_Key FOREIGN KEY(GeographyKey) REFERENCES DimGeography(GeographyKey),
	CONSTRAINT FK_Fact_AgeGroup FOREIGN KEY(AgeKey) REFERENCES DimAgeGroup(AgeKey),
	CONSTRAINT FK_Date_Key FOREIGN KEY(DateKey) REFERENCES DimDate(DateKey)
);



EXEC sp_help Fact_Malaria;
-----Fact Population
CREATE TABLE Fact_Population(
			PopulationKey INT IDENTITY(1,1) PRIMARY KEY,
			BatchID UNIQUEIDENTIFIER NOT NULL,
			DateKey INT NOT NULL,
			GeographyKey INT NOT NULL,
			Estimated_Population INT NOT NULL,
		CONSTRAINT FK_Popn_Date FOREIGN KEY(DateKey) REFERENCES DimDate(DateKey),
		CONSTRAINT FK_Popn_Geography FOREIGN KEY(GeographyKey) REFERENCES DimGeography(GeographyKey) 

		);

ALTER TABLE Fact_Population DROP CONSTRAINT FK_Popn_Date;
ALTER TABLE Fact_Population ADD CONSTRAINT FK_Popn_Date FOREIGN KEY(DateKey) REFERENCES DimDate(DateKey)
	


GO
-- 4 Seeding Unknown Mmebber defaults to handle missing or dirty staging lookups
SET IDENTITY_INSERT DimGeography ON;
INSERT INTO DimGeography (GeographyKey, Source_FacilityID,  DistrictName, RegionName, IsCity, ValidFrom, IsCurrent)
VALUES (-1, 'UNKNOWN_ID', 'UNKNOWN DISTRICT', 'UNKNOWN REGION', 0, '1900-01-01', 1);
SET IDENTITY_INSERT DimGeography OFF;

SELECT * FROM DimGeography


-- Explicitly seed missing calendar records for 2022 through 2024
DECLARE @StartDate DATE = '2020-01-01';
DECLARE @EndDate DATE = '2025-12-31';

WHILE @StartDate <= @EndDate
BEGIN
    DECLARE @DK INT = YEAR(@StartDate) * 10000 + MONTH(@StartDate) * 100 + DAY(@StartDate);
    
    IF NOT EXISTS (SELECT 1 FROM dbo.DimDate WHERE DateKey = @DK)
    BEGIN
        INSERT INTO dbo.DimDate (DateKey, FullDate, Year, Quarter, Month, MonthName, YearMonth)
        VALUES (
            @DK, @StartDate, YEAR(@StartDate), DATEPART(QUARTER, @StartDate), 
            MONTH(@StartDate), DATENAME(MONTH, @StartDate), CONCAT(YEAR(@StartDate), '_', RIGHT('0' + CAST(MONTH(@StartDate) AS VARCHAR), 2))
        );
    END
    SET @StartDate = DATEADD(DAY, 1, @StartDate);
END;


SELECT * FROM DimDate;

