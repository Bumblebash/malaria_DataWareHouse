USE MalariaLanding_DB;

--Creation of Permanent Staging Table(Estimated Population)
CREATE TABLE Stg_Population_Permanent(
----Business Grains
	Region VARCHAR(100) NOT NULL,
	District VARCHAR(100) NOT NULL,


--Fact/Measures
	Population_2020 INT,
	Population_2021 INT,
	Population_2022 INT,
	Population_2023 INT,
	Population_2024 INT,

---Audit/Governance Columns
	IngestionTimestamp DATETIME DEFAULT GETDATE(),

---Primary Key to prevent Ingestion Of Duplicates
PRIMARY KEY(Region, District)
);
GO 


--Index for Query Optimization(Makes Queries Faster When Filtering)
CREATE INDEX IX_PopnStg_Grains ON Stg_Population_Permanent(District, Region)

SELECT * FROM Stg_Population_Permanent;


--Renaming a column name
EXEC sp_rename 'Stg_Population_Permanent.Popualation_2022', 'Population_2022', 'column';
EXEC sp_rename 'Stg_Population_Permanent.INgestionTimestamp', 'IngestionTimestamp','column';