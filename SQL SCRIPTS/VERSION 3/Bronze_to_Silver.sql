USE MLanding1;


USE MLanding1;
GO

ALTER PROCEDURE dbo.SP_ETL_Stage1_Bronze_To_Silver
 @SourceTableName NVARCHAR(100),
 @ReportingYear INT,
 @BatchID UNIQUEIDENTIFIER
AS
BEGIN
 SET NOCOUNT ON;

 DELETE FROM Stg_Malaria_Permanent 
 WHERE Year = @ReportingYear;
 
 DECLARE @DynamicSQL NVARCHAR(MAX) = '';
 DECLARE @cross_apply_values NVARCHAR(MAX) = '';
 
 -- 1. FIXED HEADER STRING AGGREGATION PATTERN
 -- Maps raw python columns cleanly into unpivot value tuple matrices
 SELECT @cross_apply_values = STRING_AGG(
    '(''' + COLUMN_NAME + ''', ' + CAST(QUOTENAME(COLUMN_NAME) AS NVARCHAR(MAX)) + ')' , 
 ',')
 FROM MLanding1.INFORMATION_SCHEMA.COLUMNS
 WHERE TABLE_NAME = @SourceTableName
   AND (COLUMN_NAME LIKE '105-EP01c%' OR COLUMN_NAME LIKE '105-EP01d%' 
     OR COLUMN_NAME LIKE '105-MC04%' OR COLUMN_NAME LIKE '105-EP01b%');

 -- 2. FIXED DYNAMIC TEMPLATE STRING GENERATOR
 SET @DynamicSQL = '
 WITH RawUnpivoted AS (
     SELECT
         organisationunitid AS FacilityID,
         LTRIM(RTRIM(orgunitlevel2)) AS Region,
         LTRIM(RTRIM(organisationunitname)) AS District,
         ColName,
         TRY_CAST(Value AS INT) AS Value
     -- Added critical separating space dot here
     FROM [MLanding1].dbo.' + QUOTENAME(@SourceTableName) + '
     -- Added separating keyword space here
     CROSS APPLY (
         VALUES ' + @cross_apply_values + '
     ) AS unpiv(ColName, [Value])
 ),
 AggregatedStaging AS (
     SELECT 
         FacilityID, Region, District,
         ' + CAST(@ReportingYear AS VARCHAR(4)) + ' AS Year,
         CASE
             WHEN UPPER(ColName) LIKE ''%JANUARY%'' THEN 1
             WHEN UPPER(ColName) LIKE ''%FEBRUARY%'' THEN 2
             WHEN UPPER(ColName) LIKE ''%MARCH%'' THEN 3
             WHEN UPPER(ColName) LIKE ''%APRIL%'' THEN 4
             WHEN UPPER(ColName) LIKE ''%MAY%'' THEN 5
             WHEN UPPER(ColName) LIKE ''%JUNE%'' THEN 6
             WHEN UPPER(ColName) LIKE ''%JULY%'' THEN 7
             WHEN UPPER(ColName) LIKE ''%AUGUST%'' THEN 8
             WHEN UPPER(ColName) LIKE ''%SEPTEMBER%'' THEN 9
             WHEN UPPER(ColName) LIKE ''%OCTOBER%'' THEN 10
             WHEN UPPER(ColName) LIKE ''%NOVEMBER%'' THEN 11
             WHEN UPPER(ColName) LIKE ''%DECEMBER%'' THEN 12
         END AS Month,
         CASE 
             WHEN ColName LIKE ''105-EP01c%'' THEN ''ConfirmedCases''
             WHEN ColName LIKE ''105-EP01d%'' THEN ''TreatedCases''
             WHEN ColName LIKE ''105-MC04%'' THEN ''PregnancyCases''
             WHEN ColName LIKE ''105-EP01b%'' THEN ''TotalCasesRecorded''
         END AS CaseType,
         CASE
             WHEN UPPER(ColName) LIKE ''%0-28DYS%'' THEN ''0-28Dys''
             WHEN UPPER(ColName) LIKE ''%29DYS-4YRS%'' THEN ''29Days-4yrs''
             WHEN UPPER(ColName) LIKE ''%5-9YRS%'' THEN ''5-9yrs''
             WHEN UPPER(ColName) LIKE ''%10-19YRS%'' THEN ''10-19yrs''
             WHEN UPPER(ColName) LIKE ''%20+YRS%'' THEN ''20+''
         END AS AgeGroup,
         CASE 
             WHEN UPPER(ColName) LIKE ''%FEMALE%'' THEN ''Female''
             WHEN UPPER(ColName) LIKE ''%MALE%'' THEN ''Male''
         END AS Gender,
         Value
     FROM RawUnpivoted
 ),
 PivotPayload AS (
     SELECT 
         FacilityID, Region, District, Year, Month, AgeGroup, Gender,
         SUM(CASE WHEN CaseType = ''ConfirmedCases'' THEN Value END) AS ConfirmedCases,
         SUM(CASE WHEN CaseType = ''TreatedCases'' THEN Value END) AS TreatedCases,
         SUM(CASE WHEN CaseType = ''PregnancyCases'' THEN Value END) AS PregnancyCases,
         SUM(CASE WHEN CaseType = ''TotalCasesRecorded'' THEN Value END) AS TotalCasesRecorded
     FROM AggregatedStaging
     GROUP BY FacilityID, Region, District, Year, Month, AgeGroup, Gender
 )
 
 INSERT INTO [MLanding1].dbo.Stg_Malaria_Permanent (
     BatchID, FacilityID, Region, District, Year, Month, AgeGroup, Gender, 
     ConfirmedCases, TreatedCases, PregnancyCases, TotalCasesRecorded, DataQualityFlag
 )
 SELECT 
     ''' + CAST(@BatchID AS VARCHAR(50)) + ''', FacilityID, Region, District, Year, Month, 
     AgeGroup, Gender, ConfirmedCases, TreatedCases, PregnancyCases, TotalCasesRecorded,
     CASE 
         WHEN Gender = ''Male'' AND (PregnancyCases IS NOT NULL OR TotalCasesRecorded IS NOT NULL) THEN ''VALID_ENTRY''
         WHEN ConfirmedCases IS NULL AND TreatedCases IS NULL AND PregnancyCases IS NULL AND TotalCasesRecorded IS NULL THEN ''NotReported''
         WHEN ISNULL(ConfirmedCases,0) = 0 AND ISNULL(TreatedCases,0) = 0 AND ISNULL(PregnancyCases,0) = 0 AND ISNULL(TotalCasesRecorded,0) = 0 THEN ''Reported_Zero_Cases''
         ELSE ''VALID_ENTRY''
     END AS DataQualityFlag
 FROM PivotPayload;';

 EXEC sp_executesql @DynamicSQL;
END;
GO




