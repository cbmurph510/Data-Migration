SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[DataMigrationLog_RowStop]
(
	@LogId			UNIQUEIDENTIFIER,
	@RowId			UNIQUEIDENTIFIER,
	@Success		BIT,
	@RowsProcessed	INT = NULL,
	@Notes			NVARCHAR(2000) = NULL
)
AS
/*
** ObjectName:	DataMigrationLog_RowStop
** 
** Description:	Update the specified log row with
**					- End Time
**					- Run Time
**					- Indicate whether or not the described step was successful
**					- Number of Rows Processed
**					- Any Additional Notes 
**
** Revision History
** --------------------------------------------------------------------------
** Date				Name			Description
** --------------------------------------------------------------------------
** cmurphy		2012-06-05			Initial Creation
*/
BEGIN
	SET NOCOUNT ON
	
	DECLARE	@dtEndTime	DATETIME
	SELECT	@dtEndTime	= GETDATE()
	
	UPDATE	CRMStaging.dbo.DataMigrationLog	SET
			DataMigrationLog.EndTime			= @dtEndTime,
			DataMigrationLog.RunTime			= RIGHT('00' + CAST(((DATEDIFF(SECOND,StartTime,@dtEndTime) / 60) / 60) % 60 AS NVARCHAR),2)
												  + ':'
												  + RIGHT('00' + CAST((DATEDIFF(SECOND,StartTime,@dtEndTime) / 60) % 60 AS NVARCHAR),2)
												  + ':'
												  + RIGHT('00' + CAST(DATEDIFF(SECOND,StartTime,@dtEndTime) % 60 AS NVARCHAR),2)
												  + ' (HH:MM:SS)',
			DataMigrationLog.Success			= @Success,
			--DataMigrationLog.Success			= CASE WHEN (ISNULL(ErrorId,0)<1 AND ISNULL(ErrorMessage,'') = '') THEN 1 ELSE 0 END
			DataMigrationLog.RowsProcessed		= @RowsProcessed,
			DataMigrationLog.Notes				= @Notes
	WHERE	DataMigrationLog.LogId				= @LogId
			AND DataMigrationLog.RowId			= @RowId
END
GO
GRANT EXECUTE ON  [dbo].[DataMigrationLog_RowStop] TO [Developer]
GO
