USE MLanding1;



---INSERT DATA INTO THE FactPopulation_Table
INSERT INTO Fact_Population( PopulationKey, GeographyKey, DateKey, Estimated_Population)
SELECT 
        p.PopulationKey,
		geo.GeographyKey,
		d.DateKey,
		p.Estimated_Population
		FROM DimPopulation p
 JOIN DimGeography geo  ON p.GeographyKey = geo.GeographyKey
 JOIN DimDate d ON p.Year = d.Year
 
 WHERE d.Month = 1
 AND p.Region <> P.DistrictName
;


SELECT * FROM Fact_Population; 

SELECT * FROM  Dimpopulation

TRUNCATE TABLE Fact_Population;