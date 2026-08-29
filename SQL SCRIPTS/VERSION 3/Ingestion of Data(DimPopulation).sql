USE MLanding1;
SELECT * FROM Stg_Population_Permanent
GO
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