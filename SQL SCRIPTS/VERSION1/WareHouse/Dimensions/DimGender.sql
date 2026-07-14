USE MalariaWareHouse_DB;

---GENDER DIMENSION(DimGender)
CREATE TABLE DimGender(
	GenderKey  INT IDENTITY(1,1) PRIMARY KEY,
	Gender VARCHAR(20) NOT NULL UNIQUE
);


/**Ingesting Data Into DimGender**/

INSERT INTO DimGender(Gender)
SELECT  DISTINCT Gender FROM
[MalariaLanding_DB].dbo.Stg_Malaria_Permanent;





