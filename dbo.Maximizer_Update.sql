USE [OnyxToMSCRM_STAGE]
GO
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[Maximizer_Update]') AND type in (N'P', N'PC'))
BEGIN
	DROP PROCEDURE [dbo].[Maximizer_Update]
END
GO
CREATE PROCEDURE [dbo].[Maximizer_Update]
(
	@LogId UNIQUEIDENTIFIER = NULL
)
AS

/*
** ObjectName:	Maximizer_Update
** Description:	For migrated CRM Contacts where the only Opportunity is the Maximizer Opportunity, 
**				the Contact will be deactivated and the Maximizer Opportunity will be closed (if it wasn’t already) 
**				with Status = Lost / Status Reason = Lost. TT# BUG16927
**
** Revision History
** --------------------------------------------------------------------------
** Date				Name			Description
** --------------------------------------------------------------------------
** 2013-04-19		CMurphy			Initial Creation
** 2013-04-22		CMurphy			Set State and Status Reason of Opportunity to Lost/Lost when Status = Open, Type = Training and 
**									Owner = (Deb Doe, Sarah Doe, Susan Doe, Anna Doe, Jen Doe, Emily Doe, Amy Doe)
*/

BEGIN
	SET NOCOUNT ON
	
		
	DECLARE	@Success		BIT,
			@RowId			UNIQUEIDENTIFIER,
			@ErrorId		NVARCHAR(50),
			@ErrorMessage	NVARCHAR(2000),
			@RowsProcessed	INT

	-- Log Row - Start
	SELECT	@Success	= 1,
			@LogId		= ISNULL(@LogId,NEWID())
	EXEC OnyxToMSCRM_STAGE.dbo.DataMigrationLog_RowStart @LogId,'Maximizer_Update',@RowId OUTPUT

	--Run Sproc Logic
	BEGIN TRY
		--Declare Variables
		
		

--Individual has NO other incidents except Maximizer 

IF OBJECT_ID('tempdb..#tmpMaximizerUpdate') IS NOT NULL 
            BEGIN DROP TABLE #tmpMaximizerUpdate END

CREATE TABLE #tmpMaximizerUpdate ( incidentid int, icontactid INT )
     
INSERT  INTO #tmpMaximizerUpdate
     
SELECT  iIncidentId, iContactId
FROM  RIP_ONYX.dbo.Incident C 
WHERE  c.tiRecordStatus = 1
AND c.iIncidentCategory = 3
AND C.chInsertBy LIKE '%Maximizer%'
AND c.iContactId NOT IN  
	(SELECT DISTINCT iContactId FROM RIP_ONYX.dbo.Incident
	WHERE chInsertBy NOT LIKE '%Maximizer%' 
	AND iIncidentCategory IN (1,2,3,4,5) 
	AND tiRecordStatus = 1)

--SELECT * FROM #tmpMaximizerUpdate	
 
--Set State and Status Reason of Opportunity to Lost/Lost when Contact only has Maximizers incident(s)
UPDATE DataMigration_MSCRM.dbo.OpportunityBase
SET StateCode = 2,StatusCode = 908600010
from DataMigration_MSCRM.dbo.OpportunityBase O
INNER JOIN DataMigration_MSCRM.dbo.OpportunityExtensionBase E
ON O.OpportunityId = E.OpportunityId
WHERE E.MTB_ID_Search IN 
(SELECT incidentid FROM #tmpMaximizerUpdate)


--Inactivate Contact record when Contact only has Maximizers incident(s)
UPDATE DataMigration_MSCRM.dbo.ContactBase
SET StateCode = 1,StatusCode = 2 
from DataMigration_MSCRM.dbo.ContactBase C
INNER JOIN DataMigration_MSCRM.dbo.ContactExtensionBase B
ON C.ContactId = B.ContactId
WHERE B.MTB_ID_Search IN 
(SELECT icontactid FROM #tmpMaximizerUpdate)

/*
Set State and Status Reason of Opportunity to Lost/Lost when Status = Open, Type = Training and 
Owner = (Deb Doe, Sarah Doe, Susan Doe, Anna Doe, Jen Doe, Emily Doe, Amy Doe).  
*/
UPDATE DataMigration_MSCRM.dbo.OpportunityBase
SET StateCode = 2,StatusCode = 908600010
from DataMigration_MSCRM.dbo.OpportunityBase O
INNER JOIN DataMigration_MSCRM.dbo.OpportunityExtensionBase E
ON O.OpportunityId = E.OpportunityId
WHERE E.MTB_type = 908600003 --Training
AND StateCode = 0 --Status is Open
AND OwnerId IN 

(SELECT OwnerId FROM DataMigration_MSCRM.dbo.OwnerBase WHERE name IN 
('Amy Doe','Anna Doe', 'Deb Doe','Jen Doe', 'Emily Doe','Susan Doe', 'Sarah Doe'))
	
		END TRY
	BEGIN CATCH
		-- Log Row - ERROR
		SELECT	@Success		= 0,
				@ErrorId		= ERROR_NUMBER(),
				@ErrorMessage	= ERROR_MESSAGE()
		EXEC OnyxToMSCRM_STAGE.dbo.DataMigrationLog_RowError @LogId,@RowId,@ErrorId,@ErrorMessage
	END CATCH


	RETURN @Success
END

GO
GRANT EXEC ON dbo.Maximizer_Update TO DEVELOPER

GO