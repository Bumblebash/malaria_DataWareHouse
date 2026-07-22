USE MalariaWareHouse_DB;

--Creating Region Dimesion
CREATE TABLE DimRegion(
   RegionKey INT IDENTITY(1,1) PRIMARY KEY,
   Region VARCHAR(20) NOT NULL UNIQUE

);
GO

/**Inserting Data Into Region dimension **/
INSERT INTO DimRegion(Region)
SELECT DISTINCT Region FROM [MalariaLanding_DB].dbo.Stg_Malaria_Permanent;
 
---Confirmation 
SELECT * FROM DimRegion;