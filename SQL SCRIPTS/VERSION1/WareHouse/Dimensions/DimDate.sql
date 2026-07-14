
USE MalariaWareHouse_DB;

---Creating Date Dimesion Table
CREATE TABLE DimDate(
	DateKey INT PRIMARY KEY,
	FullDate DATE NOT NULL,
	Year INT NOT NULL,
	Quarter INT NOT NULL,
	Month INT NOT NULL,
	MonthName NVARCHAR(20),
	YearMonth VARCHAR(8)
);
GO 

------INGEST DateDimension data into Dimdate
INSERT INTO DimDate
SELECT DISTINCT
       Year*10000 + Month*100 + 1 AS DateKey,
       DATEFROMPARTS(Year,Month,1),
       Year,
       DATEPART(QUARTER, DATEFROMPARTS(Year, Month,1)),
       Month,
       DATENAME(MONTH, DATEFROMPARTS(Year, Month,1)),
       CONCAT(Year, '_', RIGHT('0' + CAST(Month AS VARCHAR), 2))
FROM [MalariaLanding_DB].dbo.Stg_Malaria_Permanent;
GO
SELECT * FROM DimDate;