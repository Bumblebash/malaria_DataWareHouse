USE MLanding1;
GO

ALTER PROCEDURE dbo.SP_ETL_Stage2_Sync_Dimensions
    @BatchID UNIQUEIDENTIFIER
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Enforce ACID compliance during execution flights
    BEGIN TRANSACTION;
    BEGIN TRY

        -- =========================================================================
        -- 1. AUTOMATED DYNAMIC DATE INGESTION (Populates DimDate on the fly)
        -- =========================================================================
        INSERT INTO dbo.DimDate (DateKey, FullDate, Year, Quarter, Month, MonthName, YearMonth)
        SELECT DISTINCT
            Year * 10000 + Month * 100 + 1 AS DateKey,
            DATEFROMPARTS(Year, Month, 1) AS FullDate,
            Year,
            DATEPART(QUARTER, DATEFROMPARTS(Year, Month, 1)) AS Quarter,
            Month,
            DATENAME(MONTH, DATEFROMPARTS(Year, Month, 1)) AS MonthName,
            CONCAT(Year, '_', RIGHT('0' + CAST(Month AS VARCHAR), 2)) AS YearMonth
        FROM dbo.Stg_Malaria_Permanent
        WHERE BatchID = @BatchID
          AND (Year * 10000 + Month * 100 + 1) NOT IN (SELECT DateKey FROM dbo.DimDate);


        -- =========================================================================
        -- 2. SYNC GENDER DIMENSION (SCD Type 0 - Insert Only If Missing)
        -- =========================================================================
        INSERT INTO dbo.DimGender (Gender)
        SELECT DISTINCT Gender 
        FROM dbo.Stg_Malaria_Permanent
        WHERE BatchID = @BatchID 
          AND Gender IS NOT NULL
          AND Gender NOT IN (SELECT Gender FROM dbo.DimGender);


        -- =========================================================================
        -- 3. SYNC AGE GROUP DIMENSION (SCD Type 0 - Clean Insert Only)
        -- =========================================================================
        INSERT INTO dbo.DimAgeGroup (AgeGroup, ValidFrom, IsCurrent)
        SELECT DISTINCT AgeGroup, GETDATE(), 1
        FROM dbo.Stg_Malaria_Permanent
        WHERE BatchID = @BatchID 
          AND AgeGroup IS NOT NULL
          AND AgeGroup NOT IN (SELECT AgeGroup FROM dbo.DimAgeGroup);


        -- =========================================================================
        -- 4. GEOGRAPHY DIMENSION MANAGEMENT (SCD Type 2 Pattern)
        -- =========================================================================
        
        -- STEP A: Close out old rows if the District or Region attributes changed
        UPDATE target 
        SET target.IsCurrent = 0, 
            target.ValidTo = GETDATE()
        FROM dbo.DimGeography target
        INNER JOIN dbo.Stg_Malaria_Permanent src 
            ON src.FacilityID = target.Source_FacilityID
        WHERE src.BatchID = @BatchID 
          AND target.IsCurrent = 1
          -- Explicit change criteria trigger:
          AND (target.DistrictName <> src.District OR target.RegionName <> src.Region);

        -- STEP B: Insert the new active rows (Handles both new facilities and changed history)
        INSERT INTO dbo.DimGeography (Source_FacilityID, DistrictName, RegionName, IsCity, ValidFrom, IsCurrent)
        SELECT DISTINCT 
            src.FacilityID, 
            src.District, 
            src.Region,
            CASE WHEN src.District LIKE '%CITY%' THEN 1 ELSE 0 END,
            GETDATE(), 
            1
        FROM dbo.Stg_Malaria_Permanent src
        WHERE src.BatchID = @BatchID 
          AND src.FacilityID IS NOT NULL 
          -- Only insert if the facility doesn't exist as active yet
          AND src.FacilityID NOT IN (
              SELECT Source_FacilityID 
              FROM dbo.DimGeography 
              WHERE IsCurrent = 1
          );

        -- Commit everything safely if zero engine syntax alerts triggered
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        -- Roll back open locks to prevent staging blockages on failure
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO
