SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[DataMigrationLog_RowError]
(
	@LogId				UNIQUEIDENTIFIER,
	@RowId				UNIQUEIDENTIFIER,
	@SystemErrorCode	NVARCHAR(50),
	@SystemErrorMessage NVARCHAR(4000)
)
AS
/*
** ObjectName: DataMigrationLog_RowError
** 
** Description: Update the specified row with the provided error
**
** Revision History
** --------------------------------------------------------------------------
** Date				Name			Description
** --------------------------------------------------------------------------
** cmurphy		2012-06-05			Initial Creation
*/
BEGIN
	SET NOCOUNT ON
	
	UPDATE	[CRMStaging].dbo.DataMigrationLog SET
			ErrorId			= @SystemErrorCode,
			ErrorMessage	= @SystemErrorMessage
	WHERE	LogId			= @LogId
			AND RowId		= @RowId
END
GO
GRANT EXECUTE ON  [dbo].[DataMigrationLog_RowError] TO [Developer]
GO
