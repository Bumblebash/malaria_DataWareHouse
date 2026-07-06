USE MLanding1;


---Age group Table
CREATE TABLE DimAgeGroup(
	AgeKey INT IDENTITY(1,1) PRIMARY KEY,
	AgeGroup NVARCHAR(50) NOT NULL UNIQUE,
	ValidFrom DATETIME NOT NULL,
	ValidTo DATETIME  NULL,
	IsCurrent  BIT DEFAULT 1
);

ALTER TABLE DimAgeGroup ALTER COLUMN ValidTo DATETIME NULL;
----Region Table
CREATE TABLE DimRegion(
		RegionKey INT IDENTITY(1,1) PRIMARY KEY,
		Region  NVARCHAR(100) NOT NULL UNIQUE,
		ValidFrom DATETIME NOT NULL,
		ValidTo DATETIME NULL,
		IsCurrent BIT DEFAULT 1
);




---Apply Legacy SCD 2 tracKing infrastructure attributes to Dim District
CREATE TABLE DimDistrict(
	DistrictKey INT IDENTITY(1,1) PRIMARY KEY,
	DistrictName NVARCHAR(120) NOT NULL,
	RegionKey INT NOT NULL,
	IsCity BIT DEFAULT 0,
	ValidFrom DATETIME NOT NULL,
	ValidTo DATETIME NULL,
	IsCurrent BIT DEFAULT 1,
	CONSTRAINT FK_District_Region FOREIGN KEY(RegionKey) REFERENCES DimRegion(RegionKey)

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


----Gender Table

CREATE TABLE DimGender(
		GenderKey INT IDENTITY(1,1) PRIMARY KEY,
		Gender VARCHAR(20) NOT NULL UNIQUE

);

---- Configuring Fact Tables to capture the Execution Lineage Token (BatchID)
CREATE TABLE Fact_Malaria(
	   FactID BIGINT IDENTITY(1,1) PRIMARY KEY,
	   BatchID UNIQUEIDENTIFIER NOT NULL, ---Core tracking lineage Token
	   FacilityKey INT NOT NULL,
	   DateKey INT NOT NULL,
	   GenderKey INT NOT NULL,
	   AgeKey INT NOT NULL,
	   ConfirmedCases INT NOT NULL,
	   TreatedCases INT NOT NULL,
	   PregnantCases INT NOT NULL,
	   TotalCases INT NOT NULL,
	   LoadDate DATETIME DEFAULT GETDATE(),
	CONSTRAINT FK_Fact_Facility FOREIGN KEY(FacilityKey) REFERENCES DimFacility(FacilityKey),
	CONSTRAINT FK_Fact_Gender FOREIGN KEY(GenderKey) REFERENCES DimGender(GenderKey),
	CONSTRAINT FK_Fact_AgeGroup FOREIGN KEY(AgeKey) REFERENCES DimAgeGroup(AgeKey),
	CONSTRAINT FK_Date_Key FOREIGN KEY(DateKey) REFERENCES DimDate(DateKey)
);




 


-----Fact Population


CREATE TABLE Fact_Population(
			PopulationKey INT IDENTITY(1,1) PRIMARY KEY,
			BatchID UNIQUEIDENTIFIER NOT NULL,
			DistrictKey INT NOT NULL,
			DateKey INT NOT NULL,
			Estimated_Popualtion INT NOT NULL,
		CONSTRAINT FK_Popn_District FOREIGN KEY(DistrictKey) REFERENCES DimDistrict(DistrictKey),
		CONSTRAINT FK_Popn_Date FOREIGN KEY(DateKey) REFERENCES DimDate(DateKey)

		);


--DimFacility
CREATE TABLE DimFacility(
		FacilityKey INT IDENTITY(1,1) PRIMARY KEY,
		Source_FacilityID NVARCHAR(100) NOT NULL,
		DistrictKey INT NOT NULL,
		ValidFrom DATETIME NOT NULL DEFAULT GETDATE(),
		ValidTo DATETIME NULL,
		IsCurrent BIT NOT NULL DEFAULT 1,
		CONSTRAINT FK_DimDistrict FOREIGN KEY(DistrictKey) REFERENCES DimDistrict(DistrictKey)
);
GO



GO
-- 4 Seeding Unknown Mmebber defaults to handle missing or dirty staging lookups
SET IDENTITY_INSERT DimRegion ON;
INSERT INTO DimRegion (RegionKey, Region, ValidFrom, IsCurrent) 
VALUES (-1, 'UNKNOWN REGION', '1900-01-01', 1);
SET IDENTITY_INSERT DimRegion OFF;

SET IDENTITY_INSERT DimDistrict ON;
INSERT INTO DimDistrict (DistrictKey, DistrictName, RegionKey, IsCity, ValidFrom, IsCurrent) 
VALUES (-1, 'UNKNOWN DISTRICT', -1, 0, '1900-01-01', 1);
SET IDENTITY_INSERT DimDistrict OFF;

SET IDENTITY_INSERT DimAgeGroup ON;
INSERT INTO DimAgeGroup (AgeKey, AgeGroup, ValidFrom, IsCurrent) 
VALUES (-1, 'UNKNOWN AGE GROUP', '1900-01-01', 1);
SET IDENTITY_INSERT DimAgeGroup OFF;


SET IDENTITY_INSERT DimFacility ON;
INSERT INTO DimFacility (FacilityKey, Source_FacilityID, DistrictKey, ValidFrom, IsCurrent)
VALUES (-1 , 'UNKNOWN_ID', -1, '1900-01-01', 1);
SET IDENTITY_INSERT DimFacility  OFF;
GO


