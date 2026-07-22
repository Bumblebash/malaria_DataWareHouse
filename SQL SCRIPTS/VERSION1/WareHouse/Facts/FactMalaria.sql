USE MalariaWareHouse_DB;


--CREATING FACT TABLE
CREATE TABLE Fact_Malaria(
       FactID  BIGINT IDENTITY(1,1) PRIMARY KEY,
       RegionKey INT NOT NULL,
       DistrictKey INT NOT NULL,
       DateKey INT NOT NULL,
       Genderkey INT NOT NULL,
       AgeKey INT NOT NULL,

       --Measures
       ConfirmedCases INT  NULL,
       TreatedCases INT  NULL,
       PregnantCases INT  NULL,
       TotalCases INT  NULL,

       LoadDate DATETIME DEFAULT GETDATE(),
       --Constraints
       --DateConstraint--
       CONSTRAINT FK_Fact_Date
              FOREIGN KEY (DateKey) 
              REFERENCES DimDate(DateKey),
        ---RegionConstraint---
        CONSTRAINT FK_Fact_Region
                FOREIGN KEY (RegionKey)
                REFERENCES DimRegion(RegionKey),
        ---DistrictConstraint--
        CONSTRAINT FK_Fact_District
                   FOREIGN KEY (DistrictKey)
                   REFERENCES DimDistrict(Districtkey),
        ----Gender Constraint--
        CONSTRAINT FK_Fact_Gender
                   FOREIGN KEY (GenderKey)
                   REFERENCES DimGender(GenderKey),

        ---AgeGroup Constraint---
        CONSTRAINT FK_Fact_AgeGroup
                   FOREIGN  KEY (AgeKey)
                   REFERENCES DimAgeGroup(AgeKey)                
);




/**INSERTION OF DATA INTO THE FACT TABLE **/
INSERT INTO Fact_Malaria(RegionKey,DistrictKey, DateKey, GenderKey, AgeKey, ConfirmedCases, TreatedCases, PregnantCases, TotalCases)
SELECT
       dist.RegionKey,
       dist. DistrictKey,
       d.DateKey,
       gen.GenderKey,
       age.AgeKey,
       m.ConfirmedCases,
       m.TreatedCases,
       m.PregnancyCases,
       m.TotalCasesRecorded As TotalCases
FROM [MalariaLanding_DB].dbo.Stg_Malaria_Permanent m
JOIN DimDate d ON m.Year = d.Year AND d.Month = m.Month
JOIN DimDistrict dist ON m.District = dist.DistrictName
JOIN DimAgeGroup age ON m.AgeGroup = age.AgeGroup
JOIN DimGender gen ON m.Gender = gen.Gender
;

--Confirmation 
SELECT * FROM Fact_Malaria;



