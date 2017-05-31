SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[DataMigrationLog_RowStart]
(
	@LogId		UNIQUEIDENTIFIER,
	@RowDesc	NVARCHAR(255),
	@RowId		UNIQUEIDENTIFIER OUTPUT
)
AS
/*
** ObjectName: DataMigrationLog_RowStart
** 
** Description: Create a row in the DataMigrationLog table
**
** Revision History
** --------------------------------------------------------------------------
** Date				Name			Description
** --------------------------------------------------------------------------
** cmurphy		2012-06-05			Initial Creation
*/
BEGIN
	SET NOCOUNT ON
	
	SELECT @RowId = NEWID()
	
	INSERT INTO [CRMStaging].dbo.DataMigrationLog
	(
		LogId,
		RowId,
		RowDesc,
		StartTime
	)
	VALUES
	(
		@LogId,
		@RowId,
		@RowDesc,
		GETDATE()
	)
END
GO
GRANT EXECUTE ON  [dbo].[DataMigrationLog_RowStart] TO [Developer]
GO
