USE MLanding1;

--- FACTS AND Dimensions
---Age group Table
CREATE TABLE DimAgeGroup(
	AgeKey INT IDENTITY(1,1) PRIMARY KEY,
	AgeGroup NVARCHAR(50) NOT NULL 
);


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


---Geography Dimension
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



---- Configuring the  Fact Table to capture the Execution Lineage Token (BatchID)
CREATE TABLE Fact_Malaria(
	   FactID BIGINT IDENTITY(1,1) PRIMARY KEY,
	   BatchID UNIQUEIDENTIFIER NOT NULL, --- Token for tracking data lineage
	   DateKey INT NOT NULL,
	   GenderKey INT NOT NULL,
	   AgeKey INT NOT NULL,
	   GeographyKey INT NOT NULL,
	   ConfirmedCases INT NULL,
	   TreatedCases INT  NULL,
	   PregnantCases INT NULL,
	   TotalCases INT  NULL,
	   LoadDate DATETIME DEFAULT GETDATE(),
	CONSTRAINT FK_Fact_Gender FOREIGN KEY(GenderKey) REFERENCES DimGender(GenderKey),
	CONSTRAINT FK_Geography_Key FOREIGN KEY(GeographyKey) REFERENCES DimGeography(GeographyKey),
	CONSTRAINT FK_Fact_AgeGroup FOREIGN KEY(AgeKey) REFERENCES DimAgeGroup(AgeKey),
	CONSTRAINT FK_Date_Key FOREIGN KEY(DateKey) REFERENCES DimDate(DateKey)
);




-----Fact Population
CREATE TABLE Fact_Population(
            FactID INT IDENTITY(1,1) PRIMARY KEY,
			BatchID UNIQUEIDENTIFIER  NULL,
			DateKey INT NOT NULL,
			GeographyKey INT NOT NULL,
			Estimated_Population INT  NULL,
		CONSTRAINT FK_Popn_Date FOREIGN KEY(DateKey) REFERENCES DimDate(DateKey),
		CONSTRAINT FK_Popn_Geography FOREIGN KEY(GeographyKey) REFERENCES DimGeography(GeographyKey) 
		);






GO
-- 4 Seeding Unknown Member defaults to handle missing or dirty staging lookups
SET IDENTITY_INSERT DimGeography ON;
INSERT INTO DimGeography (GeographyKey, Source_FacilityID,  DistrictName, RegionName, IsCity, ValidFrom, IsCurrent)
VALUES (-1, 'UNKNOWN_ID', 'UNKNOWN DISTRICT', 'UNKNOWN REGION', 0, '1900-01-01', 1);
SET IDENTITY_INSERT DimGeography OFF;








