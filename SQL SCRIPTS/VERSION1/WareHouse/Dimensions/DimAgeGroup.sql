USE MalariaWareHouse_DB;
--CREATING AgeGroup Dimension
CREATE TABLE DimAgeGroup(
    AgeKey INT IDENTITY(1,1) PRIMARY KEY,
    AgeGroup NVARCHAR(50) NOT NULL UNIQUE
);
GO
/**Insert DimAgeGroup Data**/
INSERT INTO DimAgeGroup (AgeGroup)
    SELECT DISTINCT AgeGroup
FROM [MalariaLanding_DB].dbo.Stg_Malaria_Permanent
WHERE AgeGroup IS NOT NULL;

--Confirmation 
SELECT * FROM DimAgeGroup;
