USE MLanding1;



---INSERT DATA INTO THE FactPopulation_Table
INSERT INTO Fact_Population(GeographyKey, DateKey, Estimated_Population)
SELECT 
		geo.GeographyKey,
		d.DateKey,
		p.Estimated_Population
		FROM Stg_Population_Unpivoted p
 JOIN DimGeography geo  ON p.District = geo.DistrictName  AND p.Region = geo.RegionName
 JOIN DimDate d ON p.Year = d.Year
 WHERE d.Month = 1
 AND p.Region <> P.District
;


SELECT * FROM Fact_Population; 

SELECT * FROM  Dimpopulation

TRUNCATE TABLE Fact_Population;