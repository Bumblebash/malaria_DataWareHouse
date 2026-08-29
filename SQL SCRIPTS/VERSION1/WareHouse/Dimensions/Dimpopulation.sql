USE MalariaWareHouse_DB;

CREATE TABLE Dimpopulation(
        PopulationKey INT IDENTITY(1,1) PRIMARY KEY,
        DistrictKey INT NOT NULL,
        Region NVARCHAR(200) NOT NULL,
        DistrictName NVARCHAR(200) NOT NULL,
        Year INT,
        Estimated_Population INT
);





/**Insertion of Data into a Dimpopulation**/

DECLARE @cols NVARCHAR(MAX);

SELECT @cols = STRING_AGG(CAST(QUOTENAME(COLUMN_NAME) AS NVARCHAR(MAX)), ',')

FROM [MalariaLanding_DB].INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'Stg_Population_Permanent'
AND TABLE_SCHEMA = 'dbo'
AND (
 COLUMN_NAME LIKE '%2020%'
 OR COLUMN_NAME LIKE '%2021%'
 OR COLUMN_NAME LIKE '%2022%'
 OR COLUMN_NAME LIKE '%2023%'
 OR COLUMN_NAME  LIKE '%2024%'
);
DECLARE @sql NVARCHAR(MAX);
SET @sql= '
    WITH UNPIVOTED AS (
        SELECT 
        Region,
        District,
        ColName,
        Value
        FROM [MalariaLanding_DB].dbo.Stg_Population_Permanent
        UNPIVOT(
                Value FOR ColName IN ('+ @cols +')
   ) u 
    ),
    PARSED S(
        SELECT Region,
        District,
        CAST(RIGHT(ColName,4) AS INT) AS Year,
        Value AS Estimated_population
FROM UNPIVOTED
)
INSERT INTO Dimpopulation(DistrictKey,Region, DistrictName,Year, Estimated_Population)
        SELECT 
        d.DistrictKey,
        p.Region,
        p.District  AS DistrictName,
        p.Year,
        p.Estimated_Population
        FROM [MalariaWareHouse_DB].dbo.DimDistrict d
JOIN PARSED p ON d.DistrictName = p.District

 '

SELECT 
    src.Region,
    src.District,
    unpiv.ColName,
    unpiv.[Value]
FROM [MalariaLanding_DB].dbo.Stg_Population_Permanent AS src
CROSS APPLY (
    VALUES 
        ('Population_2020', src.Population_2020),
        ('Population_2021', src.Population_2021),
        ('Population_2022', src.Population_2022), 
        ('Population_2023', src.Population_2023),
        ('Population_2024', src.Population_2024)
) AS unpiv(ColName, [Value]);
