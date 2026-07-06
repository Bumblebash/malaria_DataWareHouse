USE MLanding1;
GO

CREATE PROCEDURE dbo.SP_Orchestrate_Malaria_Pipeline
    @SourceTableName NVARCHAR(100),
    @ReportingYear INT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @BatchID UNIQUEIDENTIFIER = NEWID();
    DECLARE @RowsWritten INT = 0;

    INSERT INTO PipelineExecutionLogs (BatchID, TaskName, TargetTable, Status, StartTime)
    VALUES (@BatchID, 'E2E_Modular_Pipeline', 'Multiple', 'PROCESSING', GETDATE());

    BEGIN TRY
        -- Step 1: Transform, unpivot, and run your data quality routing rules
        EXEC dbo.SP_ETL_Stage1_Bronze_To_Silver @SourceTableName, @ReportingYear, @BatchID;

        -- Step 2: Dynamically calculate reporting dates and synchronize lookups
        EXEC dbo.SP_ETL_Stage2_Sync_Dimensions @BatchID;

        -- Step 3: Populate your fact tables and execute macro-level verification checks
        EXEC dbo.SP_ETL_Stage3_Silver_To_Gold_Fact @BatchID, @RowsWritten = @RowsWritten OUTPUT;

        -- Log successful pipeline execution
        UPDATE PipelineExecutionLogs 
        SET EndTime = GETDATE(), Status = 'SUCCESS', RowsWritten = @RowsWritten 
        WHERE BatchID = @BatchID;

        PRINT 'Pipeline Executed Successfully. Batch ID: ' + CAST(@BatchID AS VARCHAR(50));

    END TRY
    BEGIN CATCH
        -- Catch and document execution failures automatically
        UPDATE PipelineExecutionLogs 
        SET EndTime = GETDATE(), Status = 'FAILED', ErrorMessage = ERROR_MESSAGE() 
        WHERE BatchID = @BatchID;
        
        PRINT 'Pipeline Failure. Review PipelineExecutionLogs for debugging diagnostics.';
    END CATCH;
END;
GO
