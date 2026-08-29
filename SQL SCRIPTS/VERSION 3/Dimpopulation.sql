USE MLanding1;

CREATE TABLE Dimpopulation(
        PopulationKey INT IDENTITY(1,1) PRIMARY KEY,
        GeographyKey INT NOT NULL,
        Region NVARCHAR(200) NOT NULL,
        DistrictName NVARCHAR(200) NOT NULL,
        Year INT,
        Estimated_Population INT
);





/**Insertion of Data into a Dimpopulation**/

DECLARE @cols NVARCHAR(MAX);
DECLARE @cross_apply_values NVARCHAR(MAX);
SELECT @cross_apply_values = STRING_AGG(
         '(''' + COLUMN_NAME + ''', ' + CAST(QUOTENAME(COLUMN_NAME) + ')' AS NVARCHAR(MAX)), ',') 
		FROM INFORMATION_SCHEMA.COLUMNS
		WHERE TABLE_NAME = 'Stg_Population_Permanent' AND 
		(
		 COLUMN_NAME LIKE '%2020%' 
		 OR COLUMN_NAME LIKE '%2021%'
		 OR COLUMN_NAME LIKE '%2022%'
		 OR COLUMN_NAME LIKE '%2023%'
		 OR COLUMN_NAME LIKE '%2024%'
		);

--Build the final unpivoting query execution block
DECLARE @sql NVARCHAR(MAX);
SET @sql = '
	WITH UNPIVOTED AS(
			SELECT
					Region,
					District,
					ColName,
					Value
					FROM [MLanding1].dbo.Stg_Population_Permanent
					CROSS APPLY(
					  VALUES ' + @cross_apply_values + '
					) AS unpiv(ColName, [Value])
	),
	PARSED AS (
	     SELECT Region,
		 District,
		 CAST(RIGHT(ColName, 4) AS INT) AS Year,
		 Value AS Estimated_Population
	FROM UNPIVOTED
	)
	INSERT INTO DimPopulation(GeographyKey, Region, DistrictName, Year, Estimated_Population)
				SELECT 
				d.GeographyKey,
				p.Region,
				p.District AS DistrictName,
				p.Year,
				p.Estimated_Population
		FROM [MLanding1].dbo.DimGeography d
		JOIN PARSED p ON d.DistrictName =   p.District
'

EXEC sp_executesql @sql;



SELECT * FROM DimPopulation;

SELECT 
    src.Region,
    src.District,
    unpiv.ColName,
    unpiv.[Value]
FROM [MLanding1].dbo.Stg_Population_Permanent AS src
CROSS APPLY (
    VALUES 
        ('Population_2020', src.Population_2020),
        ('Population_2021', src.Population_2021),
        ('Population_2022', src.Population_2022), 
        ('Population_2023', src.Population_2023),
        ('Population_2024', src.Population_2024)
) AS unpiv(ColName, [Value]);
