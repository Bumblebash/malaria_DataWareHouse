USE MLanding1;
GO

ALTER PROCEDURE dbo.SP_ETL_Stage3_Silver_To_Gold_Fact
    @BatchID UNIQUEIDENTIFIER,
    @RowsWritten INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    DELETE FROM dbo.Fact_Malaria
        WHERE DateKey IN (
            SELECT DISTINCT (Year * 10000 + Month * 100 + 1 )
            FROM Stg_Malaria_Permanent
            WHERE BatchID = @BatchID
        )
    
    DECLARE @SumSourceCases BIGINT = 0, 
            @SumTargetCases BIGINT = 0;
            
    BEGIN TRANSACTION;
    BEGIN TRY
    
        -- =========================================================================
        -- 1. TRANSFER VERIFIED RECORDS INTO CONFORMED KIMBALL FACT TABLE
        -- =========================================================================
        INSERT INTO dbo.Fact_Malaria (
            BatchID, 
            GeographyKey, -- Corrected from FacilityKey
            DateKey, 
            GenderKey, 
            AgeKey, 
            ConfirmedCases,
            TreatedCases, 
            PregnantCases, 
            TotalCases,
            LoadDate
        )
        SELECT
            @BatchID, 
            geo.GeographyKey, -- Correct conformed surrogate key lookup
            d.DateKey,
            gen.GenderKey,
            age.AgeKey,
            stg.ConfirmedCases, 
            stg.TreatedCases, 
            stg.PregnancyCases,
            stg.TotalCasesRecorded,
            GETDATE()
        FROM dbo.Stg_Malaria_Permanent stg
        --JOINS on Dimesions 
        INNER JOIN dbo.DimGeography geo 
            ON geo.Source_FacilityID = stg.FacilityID 
           AND geo.IsCurrent = 1
        INNER JOIN dbo.DimDate d 
            ON d.DateKey = (stg.Year * 10000 + stg.Month * 100 + 1)
        INNER JOIN dbo.DimAgeGroup age 
            ON age.AgeGroup = stg.AgeGroup
        INNER JOIN dbo.DimGender gen 
            ON gen.Gender = stg.Gender
        WHERE stg.BatchID = @BatchID 
          AND
          (stg.ConfirmedCases IS NOT NULL
    AND stg.TreatedCases IS NOT NULL 
    AND stg.PregnancyCases IS NOT NULL 
    AND stg.TotalCasesRecorded IS NOT NULL);
          
        SET @RowsWritten = @@ROWCOUNT;


        -- =========================================================================
        -- 2. RUN MATHEMATICAL BALANCING CHECK (QA RECONCILIATION)
        -- =========================================================================
        
        -- Source sum MUST match target filter conditions to prevent false rollbacks
        SELECT @SumSourceCases = ISNULL(SUM(TotalCasesRecorded), 0) 
        FROM dbo.Stg_Malaria_Permanent stg
        WHERE BatchID = @BatchID
          AND (stg.ConfirmedCases IS NOT NULL 
    AND  stg.TreatedCases IS NOT NULL 
    AND  stg.PregnancyCases IS NOT NULL 
    AND stg.TotalCasesRecorded IS NOT NULL);

        SELECT @SumTargetCases = ISNULL(SUM(TotalCases), 0) 
        FROM dbo.Fact_Malaria 
        WHERE BatchID = @BatchID;

        -- Write audit history trail into logging metrics table
        INSERT INTO dbo.DataQualityCheckLogs (
            BatchID, TargetTable, MetricName, SourceValue, TargetValue, Variance, CheckResult, ActionTaken
        )
        VALUES (
            @BatchID, 
            'Fact_Malaria', 
            'TotalCases_Run_Reconciliation', 
            @SumSourceCases,
            @SumTargetCases, 
            (@SumSourceCases - @SumTargetCases),
            CASE WHEN (@SumSourceCases - @SumTargetCases) = 0 THEN 'PASS' ELSE 'FAIL' END,
            CASE WHEN (@SumSourceCases - @SumTargetCases) = 0 THEN 'COMMIT_LOAD' ELSE 'FORCE_ROLLBACK' END
        );

        -- Safe Commit Evaluation Block
        IF (@SumSourceCases - @SumTargetCases) = 0
        BEGIN
            COMMIT TRANSACTION;
        END
        ELSE
        BEGIN
            IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
            RAISERROR('Reconciliation Mismatch. Fact metrics vary from clean staging totals.', 16, 1);
        END

    END TRY
    BEGIN CATCH
        -- Ensure engine locks clean up seamlessly on syntax triggers
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO
