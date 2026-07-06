USE MLanding1;
GO

CREATE PROCEDURE dbo.SP_ETL_Stage3_Silver_To_Gold_Fact
    @BatchID UNIQUEIDENTIFIER,
    @RowsWritten INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @SumSourceCases BIGINT = 0, @SumTargetCases BIGINT = 0;

    BEGIN TRANSACTION;
    BEGIN TRY
        
        -- Transfer verified records into the Fact Table
        INSERT INTO Fact_Malaria (BatchID, FacilityKey, DateKey, GenderKey, AgeKey, ConfirmedCases, TreatedCases, PregnantCases, TotalCases)
        SELECT 
            @BatchID, fac.FacilityKey, d.DateKey, gen.GenderKey, age.AgeKey,
            ISNULL(stg.ConfirmedCases, 0), ISNULL(stg.TreatedCases, 0), ISNULL(stg.PregnancyCases, 0), ISNULL(stg.TotalCasesRecorded, 0)
        FROM Stg_Malaria_Permanent stg
        INNER JOIN DimFacility fac  ON fac.Source_FacilityID = stg.FacilityID AND fac.IsCurrent = 1
        INNER JOIN DimDate d       ON d.DateKey = (stg.Year*10000 + stg.Month*100 + 1)
        INNER JOIN DimAgeGroup age ON age.AgeGroup = stg.AgeGroup
        INNER JOIN DimGender gen   ON gen.Gender = stg.Gender
        WHERE stg.BatchID = @BatchID AND stg.DataQualityFlag IN ('VALID_ENTRY', 'Reported_Zero_Cases');
        
        SET @RowsWritten = @@ROWCOUNT;

        -- Run final mathematical balancing check
        SELECT @SumSourceCases = ISNULL(SUM(TotalCasesRecorded), 0) FROM Stg_Malaria_Permanent WHERE BatchID = @BatchID;
        SELECT @SumTargetCases = ISNULL(SUM(TotalCases), 0) FROM Fact_Malaria WHERE BatchID = @BatchID;

        INSERT INTO DataQualityCheckLogs (BatchID, TargetTable, MetricName, SourceValue, TargetValue, Variance, CheckResult, ActionTaken)
        VALUES (@BatchID, 'Fact_Malaria', 'TotalCases_Run_Reconciliation', @SumSourceCases, @SumTargetCases, (@SumSourceCases - @SumTargetCases),
                CASE WHEN (@SumSourceCases - @SumTargetCases) = 0 THEN 'PASS' ELSE 'FAIL' END,
                CASE WHEN (@SumSourceCases - @SumTargetCases) = 0 THEN 'COMMIT_LOAD' ELSE 'FORCE_ROLLBACK' END);

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
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO
