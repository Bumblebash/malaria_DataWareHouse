USE MLanding1;


---Age group Table
CREATE TABLE DimAgeGroup(
	AgeKey INT IDENTITY(1,1) PRIMARY KEY,
	AgeGroup NVARCHAR(50) NOT NULL UNIQUE,
	ValidFrom DATETIME NOT NULL,
	ValidTo DATETIME NOT NULL,
	IsCurrent  BIT DEFAULT 1
);



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
	   RegionKey INT NOT NULL,
	   DistrictKey INT NOT NULL,
	   DateKey INT NOT NULL,
	   GenderKey INT NOT NULL,
	   AgeKey INT NOT NULL,
	   ConfirmedCases INT NOT NULL,
	   TreatedCases INT NOT NULL,
	   PregnantCases INT NOT NULL,
	   TotalCases INT NOT NULL,
	   LoadDate DATETIME DEFAULT GETDATE(),
	CONSTRAINT FK_Fact_Date FOREIGN KEY (DateKey) REFERENCES DimDate(DateKey),
	CONSTRAINT FK_Fact_Region FOREIGN KEY(RegionKey) REFERENCES DimRegion(RegionKey),
	CONSTRAINT FK_Fact_District FOREIGN KEY(DistrictKey) REFERENCES DimDistrict(DistrictKey),
	CONSTRAINT FK_Fact_Gender FOREIGN KEY(GenderKey) REFERENCES DimGender(GenderKey),
	CONSTRAINT FK_Fact_AgeGroup FOREIGN KEY(AgeKey) REFERENCES DimAgeGroup(AgeKey)
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







