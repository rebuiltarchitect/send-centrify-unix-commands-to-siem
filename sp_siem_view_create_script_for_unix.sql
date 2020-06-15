create or alter PROC dbo.sp_siem_view_create_script_for_unix as
BEGIN
SET NOCOUNT ON

DECLARE @ManagementDatabaseName varchar(100) = 'DefaultManagementDatabase' -- DefaultManagementDatabase name set edilir
DECLARE @User varchar(100) = 'siem_user' -- siem sisteminin dataları çekmek için kullandığı user set edilir.
DECLARE @Database varchar(100)
DECLARE @sqlCmd varchar(max)
DECLARE @sqlGrant varchar(max)
DECLARE myCur SCROLL CURSOR FOR
SELECT [Database]  FROM AuditStoreDatabase db, AuditStore st where db.Id=st.ActiveDatabaseId
OPEN myCur
FETCH FROM myCur INTO @Database

IF @@FETCH_STATUS = 0

SET @sqlCmd='
CREATE OR ALTER VIEW [dbo].siem_unix AS 
SELECT  C.ID COMMANDID, S.ID SESSIONID, S.MACHINENAME, S.USERNAME, S.UNIXNAME, S.DISPLAYNAME, 
S.ISADUSER, S.SESSIONTYPE, S.CLIENTNAME, C.COMMAND
, DATEADD(hour, 3, s.StartTime) AS SessionStartTime 
, DATEADD(hour, 3, s.EndTime) AS SessionEndTime 
, DATEADD(hour, 3, c.Time) AS CommandTime FROM 
['+@Database+'].[DBO].[SESSION] S ,['+@Database+'].[DBO].[COMMAND] C  with (nolock) WHERE C.SESSIONID= S.SESSIONID'
PRINT @sqlCmd
EXECUTE (N'USE [' +@ManagementDatabaseName+ ']; EXEC sp_executesql N'''+@sqlCmd+'''')

set @sqlGrant = 'Grant select on [dbo].[siem_unix] to ' + @User  -- protect if required
PRINT @sqlGrant
EXECUTE (N'USE [' +@ManagementDatabaseName+ ']; EXEC sp_executesql N'''+@sqlGrant+'''')

CLOSE myCur
DEALLOCATE myCur
END
