USE MLanding1;
GO

CREATE PROCEDURE dbo.SP_ETL_Stage2_Sync_Dimensions
    @BatchID UNIQUEIDENTIFIER
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRANSACTION;
    BEGIN TRY

            -- 1. AUTOMATED DYNAMIC DATE INGESTION (Populates DimDate on the fly)
            INSERT INTO dbo.DimDate (DateKey, FullDate, Year, Quarter, Month, MonthName, YearMonth)
            SELECT DISTINCT
                   Year*10000 + Month*100 + 1 AS DateKey,
                   DATEFROMPARTS(Year, Month, 1) AS FullDate,
                   Year,
                   DATEPART(QUARTER, DATEFROMPARTS(Year, Month, 1)) AS Quarter,
                   Month,
                   DATENAME(MONTH, DATEFROMPARTS(Year, Month, 1)) AS MonthName,
                   CONCAT(Year, '_', RIGHT('0' + CAST(Month AS VARCHAR), 2)) AS YearMonth
            FROM dbo.Stg_Malaria_Permanent
            WHERE BatchID = @BatchID
              AND (Year*10000 + Month*100 + 1) NOT IN (SELECT DateKey FROM dbo.DimDate);

            -- 2. Sync Region lookups
            INSERT INTO DimRegion (Region, ValidFrom, IsCurrent)
                SELECT DISTINCT Region, GETDATE(), 1 FROM Stg_Malaria_Permanent 
                WHERE BatchID = @BatchID AND Region IS NOT NULL AND Region NOT IN (SELECT Region FROM DimRegion);

            -- 3. Sync District lookups
            UPDATE target SET target.IsCurrent = 0
            FROM DimDistrict target
                INNER JOIN Stg_Malaria_Permanent src
                ON src.District = target.DistrictName
                INNER JOIN DimRegion r 
                ON r.Region = src.Region AND r.IsCurrent = 1
            WHERE src.BatchID = @BatchID AND target.RegionKey <> r.RegionKey;

            INSERT INTO DimDistrict (DistrictName, RegionKey, IsCity, ValidFrom)
                SELECT DISTINCT src.District, r.RegionKey, 
                   CASE WHEN 
                           src.District LIKE '%CITY%' THEN 1 
                           ELSE 0 END, 
                    GETDATE()
                FROM Stg_Malaria_Permanent src
                INNER JOIN DimRegion r ON r.Region = src.Region AND r.IsCurrent = 1
            WHERE src.BatchID = @BatchID AND src.District IS NOT NULL AND src.District NOT IN (SELECT DistrictName FROM DimDistrict);

            -- 4. Sync Facility lookups (Managing SCD Type 2 timeline boundaries)
            UPDATE target SET target.IsCurrent = 0, target.ValidTo = GETDATE() FROM DimFacility target
                INNER JOIN Stg_Malaria_Permanent src ON src.FacilityID = target.Source_FacilityID
                INNER JOIN DimDistrict d ON d.DistrictName = src.District 
            WHERE src.BatchID = @BatchID AND target.IsCurrent = 1 AND target.DistrictKey <> d.DistrictKey;

            INSERT INTO DimFacility (Source_FacilityID, DistrictKey, ValidFrom, ValidTo, IsCurrent)
                SELECT DISTINCT stg.FacilityID, dist.DistrictKey, GETDATE(), NULL, 1
                FROM Stg_Malaria_Permanent stg
                INNER JOIN DimDistrict dist ON dist.DistrictName = stg.District 
            WHERE stg.BatchID = @BatchID AND stg.FacilityID NOT IN (SELECT Source_FacilityID FROM DimFacility WHERE IsCurrent = 1);

            --5 Data Insert into DimAgeGroup
            INSERT INTO DimAgeGroup(AgeGroup, ValidFrom, VAlidTo)
                SELECT ;
            ---I need Help on How to implement SCD-2 on DimAge group category

            --6.Ingestion of Data  into the GenderDimesion
            INSERT INTO DimGender(Gender)
            SELECT DISTINCT Gender FROM [MLanding1].dbo.Stg_Malaria_Permanent;


        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO
