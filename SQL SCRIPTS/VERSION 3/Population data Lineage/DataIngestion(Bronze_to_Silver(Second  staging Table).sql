USE MLanding1;




/**Insertion of Data into The Second Staging Table(Stg_Malaria_Unpivoted**/

DECLARE @cols NVARCHAR(MAX);
DECLARE @cross_apply_values NVARCHAR(MAX);
SELECT @cross_apply_values = STRING_AGG(
         '(''' + COLUMN_NAME + ''', ' + CAST(QUOTENAME(COLUMN_NAME) + ')' AS NVARCHAR(MAX)), ',') 
		FROM INFORMATION_SCHEMA.COLUMNS
		WHERE TABLE_NAME = 'Stg_Population_Pivoted' AND 
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
					FROM [MLanding1].dbo.Stg_Population_Pivoted
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
	INSERT INTO Stg_Population_Unpivoted(Region, District, Year, Estimated_Population)
				SELECT 
				Region,
				District,
				Year,
				Estimated_Population
		FROM Parsed 
'

EXEC sp_executesql @sql;






---Custom Unpivot Script t
SELECT 
    src.Region,
    src.District,
    unpiv.ColName,
    unpiv.[Value]
FROM [MLanding1].dbo.Stg_Population_Pivoted AS src
CROSS APPLY (
    VALUES 
        ('Population_2020', src.Population_2020),
        ('Population_2021', src.Population_2021),
        ('Population_2022', src.Population_2022), 
        ('Population_2023', src.Population_2023),
        ('Population_2024', src.Population_2024)
) AS unpiv(ColName, [Value]);
