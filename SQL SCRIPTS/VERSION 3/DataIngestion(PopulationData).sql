USE MLanding1;

/** Insertion of Data Into Permanent Staging Table(Population) **/ 
WITH rate AS(
SELECT
	Region,
	District,
	population_2014,
	population_2024,
	((LOG(population_2024) - LOG(population_2014)) / 10) As rate
	FROM UBOS_population_data
),
Estimated_population AS (
SELECT 
	Region,
	District,
	rate,
	(population_2014 * EXP(rate*6)) AS est_2020,
	(population_2014 * EXP(rate*7)) AS est_2021,
	(population_2014 * EXP(rate*8)) AS est_2022,
	(population_2014 * EXP(rate*9)) AS est_2023,
	population_2024
FROM rate
)
INSERT INTO Stg_Population_Permanent(
 Region,
 District,
 Population_2020,
 Population_2021,
 Population_2022,
 Population_2023,
 Population_2024
)
SELECT
      Region,
	  District,
	  est_2020 AS Population_2020,
	  est_2021 AS Population_2021,
	  est_2022 AS Population_2022,
	  est_2023 AS Popualtion_2023,
	  population_2024 AS Population_2024
	FROM Estimated_population;

GO 



ALTER TABLE Stg_Population_Permanent ALTER  COLUMN BatchID NVARCHAR;


SELECT *	FROM DimGeography