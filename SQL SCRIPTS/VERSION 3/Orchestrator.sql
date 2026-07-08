USE MLanding1;
GO

ALTER PROCEDURE dbo.SP_Orchestrate_Malaria_Pipeline
 @SourceTableName NVARCHAR(100),
 @ReportingYear INT
AS
BEGIN
 SET NOCOUNT ON;
 
 DECLARE @BatchID UNIQUEIDENTIFIER = NEWID();
 DECLARE @RowsWritten INT = 0;
 -- Explicit string conversion to prevent engine substitution crashes
 DECLARE @BatchIDStr VARCHAR(50) = CAST(@BatchID AS VARCHAR(50));

 -- Initialize lineage logger
 INSERT INTO PipelineExecutionLogs (BatchID, TaskName, TargetTable, Status, StartTime)
 VALUES (@BatchID, 'E2E_Modular_Pipeline', 'Multiple', 'PROCESSING', GETDATE());

 BEGIN TRY
     -- Step 1: Bronze to Silver Staging Transformation
     EXEC dbo.SP_ETL_Stage1_Bronze_To_Silver @SourceTableName, @ReportingYear, @BatchID;

     -- Step 2: Conformed Dimension Synchronization Flight
     EXEC dbo.SP_ETL_Stage2_Sync_Dimensions @BatchID;

     -- Step 3: Verified Silver to Gold Kimball Fact Processing
     EXEC dbo.SP_ETL_Stage3_Silver_To_Gold_Fact @BatchID, @RowsWritten = @RowsWritten OUTPUT;

     -- Log Clean Execution Metric
     UPDATE PipelineExecutionLogs 
     SET EndTime = GETDATE(), Status = 'SUCCESS', RowsWritten = @RowsWritten 
     WHERE BatchID = @BatchID;

     -- Fixed Placeholder Format: Safely passing string representation
     RAISERROR('Pipeline Completed Successfully. Batch ID: %s. Rows Written: %d', 0, 1, @BatchIDStr, @RowsWritten) WITH NOWAIT;

 END TRY
 BEGIN CATCH
     -- Handle and close transaction cascades cleanly
     IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;

     -- Log Error Parameters to Internal History Tables
     UPDATE PipelineExecutionLogs 
     SET EndTime = GETDATE(), Status = 'FAILED', ErrorMessage = ERROR_MESSAGE()
     WHERE BatchID = @BatchID;
     
     -- Streamlined diagnostic text block for your SQL Agent Notepad logger
     PRINT '==================================================';
     PRINT 'PIPELINE AUTOMATION FAILURE CRASH DETECTED!';
     PRINT 'Batch Tracking ID : ' + @BatchIDStr;
     PRINT 'Engine Error Msg  : ' + ERROR_MESSAGE();
     PRINT 'Failed Line No    : ' + CAST(ERROR_LINE() AS VARCHAR(10));
     PRINT '==================================================';

     -- Standard error escalation route for automated alert hooks
     THROW;
 END CATCH;
END;
GO


SELECT * FROM DimGeography;
SELECT * FROM DimGender;
SELECT * FROM  DimAgeGroup;
SELECT * FROM Stg_Malaria_Permanent;
SELECT * FROM Fact_Malaria;

SELECT * FROM DataQualityCheckLogs;
SELECT * FROM PipelineExecutionLogs;