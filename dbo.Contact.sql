USE [OnyxToMSCRM_STAGE]
GO
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[Contact_Import]') AND type in (N'P', N'PC'))
BEGIN
	DROP PROCEDURE [dbo].[Contact_Import]
END
GO
CREATE PROCEDURE [dbo].[Contact_Import]
(
	@LogId UNIQUEIDENTIFIER = NULL
)
AS


/*
** ObjectName:	Contact_Import
** Description:	Insert/Update Products from Onyx Individual table into MSCRM ContactBase 
**
** Revision History
** --------------------------------------------------------------------------
** Date				Name			Description
** --------------------------------------------------------------------------
** 2012-06-12		CMurphy			Initial Creation
**/


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
	EXEC OnyxToMSCRM_STAGE.dbo.DataMigrationLog_RowStart @LogId,'Contact_Import',@RowId OUTPUT

	--Run Sproc Logic
	BEGIN TRY
		--Declare Variables

DECLARE	
				@DefaultUoMScheduleId				NVARCHAR(255),
				@OrganizationId						NVARCHAR(255),
				@DefaultUoMId						NVARCHAR(255),
				@CreatedBy							NVARCHAR(255),
				@ModifiedBy							NVARCHAR(255),
				@ExchangeRate						NVARCHAR(255),
				@OwningBusinessUnit					NVARCHAR(255),
				@TransactionCurrencyId				NVARCHAR(255),
				@OwnerIdType						INT,
				@UnassignedTeam						NVARCHAR(255),
				@UnassignedTeamINC					UNIQUEIDENTIFIER,
				@UnassignedTeamLTD					UNIQUEIDENTIFIER,
				@CompanySiteINC						UNIQUEIDENTIFIER,
				@CompanySiteLTD						UNIQUEIDENTIFIER

		--Get DEFAULT values
		SELECT	@DefaultUoMScheduleId				= (SELECT TOP 1 FIELD_VALUE FROM OnyxToMSCRM_STAGE.dbo.Default_Values WITH (NOLOCK) WHERE Field_ID = 'UoMScheduleId'),
				@OrganizationId						= (SELECT TOP 1 FIELD_VALUE FROM OnyxToMSCRM_STAGE.dbo.Default_Values WITH (NOLOCK) WHERE Field_ID = 'OrganizationId'),
				@DefaultUoMId						= (SELECT TOP 1 FIELD_VALUE FROM OnyxToMSCRM_STAGE.dbo.Default_Values WITH (NOLOCK) WHERE Field_ID = 'UoMid'),
				@CreatedBy							= (SELECT TOP 1 FIELD_VALUE FROM OnyxToMSCRM_STAGE.dbo.Default_Values WITH (NOLOCK) WHERE Field_ID = 'CreatedBy'),
				@ModifiedBy							= (SELECT TOP 1 FIELD_VALUE FROM OnyxToMSCRM_STAGE.dbo.Default_Values WITH (NOLOCK) WHERE Field_ID = 'ModifiedBy'),
				@ExchangeRate						= (SELECT TOP 1 FIELD_VALUE FROM OnyxToMSCRM_STAGE.dbo.Default_Values WITH (NOLOCK) WHERE Field_ID = 'ExchangeRate'),
				@OwningBusinessUnit					= (SELECT TOP 1 FIELD_VALUE FROM OnyxToMSCRM_STAGE.dbo.Default_Values WITH (NOLOCK) WHERE Field_ID = 'OwningBusinessUnit'),
				@TransactionCurrencyId				= (SELECT TOP 1 FIELD_VALUE FROM OnyxToMSCRM_STAGE.dbo.Default_Values WITH (NOLOCK) WHERE Field_ID = 'TransactionCurrencyId'),
				@OwnerIdType						= 9, --Contacts are owned by Teams
				@UnassignedTeam						= (SELECT TOP 1 FIELD_VALUE FROM OnyxToMSCRM_STAGE.dbo.Default_Values WITH (NOLOCK) WHERE Field_ID = 'UnassignedTeam'),
				@UnassignedTeamINC					= (SELECT TOP 1 FIELD_VALUE FROM OnyxToMSCRM_STAGE.dbo.Default_Values WITH (NOLOCK) WHERE Field_ID = 'UnassignedTeamINC'),
				@UnassignedTeamLTD					= (SELECT TOP 1 FIELD_VALUE FROM OnyxToMSCRM_STAGE.dbo.Default_Values WITH (NOLOCK) WHERE Field_ID = 'UnassignedTeamLTD'),
				@CompanySiteINC						= (SELECT TOP 1 SiteId FROM DataMigration_MSCRM.dbo.SiteBase WITH (NOLOCK) WHERE Name = 'INC'),
				@CompanySiteLTD						= (SELECT TOP 1 SiteId FROM DataMigration_MSCRM.dbo.SiteBase WITH (NOLOCK) WHERE Name = 'LTD')
				

--Clear out the staging table

		TRUNCATE TABLE OnyxToMSCRM_STAGE.dbo.Contact
INSERT INTO OnyxToMSCRM_STAGE.dbo.Contact(
	  
	   [DefaultPriceLevelId]
      ,[CustomerSizeCode]
      ,[CustomerTypeCode]
      ,[PreferredContactMethodCode]
      ,[LeadSourceCode]
      ,[OriginatingLeadId]
      ,[OwningBusinessUnit]
      ,[PaymentTermsCode]
      ,[ShippingMethodCode]
      ,[ParticipatesInWorkflow]
      ,[IsBackofficeCustomer]
      ,[Salutation]
      ,[JobTitle]
      ,[FirstName]
      ,[Department]
      ,[NickName]
      ,[MiddleName]
      ,[LastName]
      ,[Suffix]
      ,[YomiFirstName]
      ,[FullName]
      ,[YomiMiddleName]
      ,[YomiLastName]
      ,[Anniversary]
      ,[BirthDate]
      ,[GovernmentId]
      ,[YomiFullName]
      ,[Description]
      ,[EmployeeId]
      ,[GenderCode]
      ,[AnnualIncome]
      ,[HasChildrenCode]
      ,[EducationCode]
      ,[WebSiteUrl]
      ,[FamilyStatusCode]
      ,[FtpSiteUrl]
      ,[EMailAddress1]
      ,[SpousesName]
      ,[AssistantName]
      ,[EMailAddress2]
      ,[AssistantPhone]
      ,[EMailAddress3]
      ,[DoNotPhone]
      ,[ManagerName]
      ,[ManagerPhone]
      ,[DoNotFax]
      ,[DoNotEMail]
      ,[DoNotPostalMail]
      ,[DoNotBulkEMail]
      ,[DoNotBulkPostalMail]
      ,[AccountRoleCode]
      ,[TerritoryCode]
      ,[IsPrivate]
      ,[CreditLimit]
      ,[CreatedOn]
      ,[CreditOnHold]
      ,[CreatedBy]
      ,[ModifiedOn]
      ,[ModifiedBy]
      ,[NumberOfChildren]
      ,[ChildrensNames]
      ,[VersionNumber]
      ,[MobilePhone]
      ,[Pager]
      ,[Telephone1]
      ,[Telephone2]
      ,[Telephone3]
      ,[Fax]
      ,[Aging30]
      ,[StateCode]
      ,[Aging60]
      ,[StatusCode]
      ,[Aging90]
      ,[PreferredSystemUserId]
      ,[PreferredServiceId]
      ,[MasterId]
      ,[PreferredAppointmentDayCode]
      ,[PreferredAppointmentTimeCode]
      ,[DoNotSendMM]
      ,[Merged]
      ,[ExternalUserIdentifier]
      ,[SubscriptionId]
      ,[PreferredEquipmentId]
      ,[LastUsedInCampaign]
      ,[TransactionCurrencyId]
      ,[OverriddenCreatedOn]
      ,[ExchangeRate]
      ,[ImportSequenceNumber]
      ,[TimeZoneRuleVersionNumber]
      ,[UTCConversionTimeZoneCode]
      ,[AnnualIncome_Base]
      ,[CreditLimit_Base]
      ,[Aging60_Base]
      ,[Aging90_Base]
      ,[Aging30_Base]
      ,[OwnerId]
      ,[CreatedOnBehalfBy]
      ,[IsAutoCreate]
      ,[ModifiedOnBehalfBy]
      ,[ParentCustomerId]
      ,[ParentCustomerIdType]
      ,[ParentCustomerIdName]
      ,[OwnerIdType]
      ,[ParentCustomerIdYomiName]
      ,[MTB_AuthorAAP]
      ,[MTB_BillingFax]
      ,[MTB_BillingMainPhone]
      ,[MTB_CustomerSubTypeCode]
      ,[MTB_DonotallowNewsletter]
      ,[MTB_DonotallowProductAlertsTrainingAnnoun]     
      ,[MTB_EmailStatus]
      ,[MTB_ID]
      ,[MTB_ID_Search]
      ,[MTB_InstructorLecturer]
      ,[MTB_IsTrainer]
      ,[MTB_ITContact]
      ,[MTB_KnowledgeableResource]
      ,[MTB_LanguagePreference]
      ,[MTB_MailStatus]
      ,[MTB_MTBActivated]
      ,[MTB_MTBStatisticalSoftwareUsed2]
      ,[MTB_PrimaryPhone]
      ,[MTB_ProfileComplete]
      ,[MTB_PurchasingAgent]
      ,[MTB_QualityCompanionActivated]
      ,[MTB_QualityCompanionUsed2]
      ,[MTB_QualityTrainerUsed2]
      ,[MTB_SendToGPINC]
      ,[MTB_SendToGPLTD]
      ,[MTB_SendToGPPTY]
      ,[MTB_SendToGPSARL]
      ,[MTB_TrainingCalendarColor]
      ,[MTB_VOIPPhone]
      ,[MTB_WorkshopCoordinator]
      ,[MTB_CampaignId]
      ,[MTB_SiteId]
      ,[MTB_AddressValid]
      ,[MTB_PendingAccountName]
      ,[dnb_dnbinitialassociationdate]
	  ,[dnb_dnbinitialassociationstatus]
	  ,[dnb_DBCompanyId]
	  ,[dnb_dbcontactid]
	  ,[MTB_overriderequiredfields]
      ,[MTB_FlexAdminLetter]
      ,[MTB_consultant]
      ,[MTB_Spam]
      ,[RowAction]
) 


select	
		'PriceLevelId'					= NULL --Set to null per TT#15370
		,'CustomerSizeCode'				= 1
		,'CustomerTypeCode'				= CASE WHEN Company.iCompanyTypeCode IN (102331,102430) THEN AccountBase.CustomerTypeCode --Company of Type = ILR or Reseller, then migrate Type/SubType same as linked to Channel Account Type/SubType
											   WHEN I.vchUser6 = 102368 THEN 101443 --if Sales team = CRS1 then set type as Channel
											   ELSE (LTRIM(RTRIM(iUserTypeId))) END
		,'PreferredContactMethodCode'	= 1 --Any
		,'LeadSourceCode'				= NULL
		,'OriginatingLeadId'			= NULL
		,'OwningBusinessUnit'			= ISNULL(CreatedBy.BusinessUnitId,@OwningBusinessUnit)
		,'PaymentTermsCode'				= NULL
		,'ShippingMethodCode'			= NULL
		,'ParticipatesInWorkflow'		= 0
		,'IsBackofficeCustomer'			= 0
		,'Salutation'					= CASE WHEN LTRIM(RTRIM(I.vchSalutation)) = '' THEN NULL ELSE LTRIM(RTRIM(I.vchSalutation)) END
		,'JobTitle'						= CASE WHEN LTRIM(RTRIM(I.vchTitleDesc)) = '' THEN NULL ELSE LTRIM(RTRIM(I.vchTitleDesc)) END
		,'FirstName'					= CASE WHEN LTRIM(RTRIM(I.vchFirstName)) = '' THEN NULL ELSE LTRIM(RTRIM(I.vchFirstName)) END
		,'Department'					= CASE WHEN LTRIM(RTRIM(I.vchDepartmentDesc)) = '' THEN NULL ELSE LTRIM(RTRIM(I.vchDepartmentDesc)) END
		,'NickName'						= NULL
		,'MiddleName'					= CASE WHEN LTRIM(RTRIM(I.vchMiddleName)) = '' THEN NULL ELSE LTRIM(RTRIM(I.vchMiddleName)) END
		,'LastName'						= CASE WHEN LTRIM(RTRIM(I.vchLastName)) = '' THEN NULL ELSE LTRIM(RTRIM(I.vchLastName)) END
		,'Suffix'						= CASE WHEN LTRIM(RTRIM(I.vchSuffix)) = '' THEN NULL ELSE LTRIM(RTRIM(I.vchSuffix)) END
		,'YomiFirstName'				= null
		,'FullName'						= CASE WHEN I.vchfirstname = '' THEN LTRIM(RTRIM(I.vchLastName))
											   ELSE 	LTRIM(RTRIM(REPLACE(REPLACE(REPLACE(ISNULL(I.vchFirstName,''),CHAR(9),''),CHAR(10),''),CHAR(13),'')))
											+ ' '+LTRIM(RTRIM(REPLACE(REPLACE(REPLACE(ISNULL(I.vchLastName,''),CHAR(9),''),CHAR(10),''),CHAR(13),'')))
												END
		,'YomiMiddleName'				= NULL
		,'YomiLastName'					= NULL
		,'Anniversary'					= NULL
		,'BirthDate'					= NULL
		,'GovernmentId'					= NULL
		,'YomiFullName'					= NULL
		,'Description'					= CASE WHEN LTRIM(RTRIM(I.vchUser2)) = '' THEN NULL ELSE LTRIM(RTRIM(I.vchUser2)) END --Comments
		,'EmployeeId'					= NULL
		,'GenderCode'					= CASE	WHEN I.chGender = 'M' THEN 1
														WHEN I.chGender = 'F' THEN 2
														ELSE NULL
												  END
		,'AnnualIncome'					= NULL
		,'HasChildrenCode'				= NULL
		,'EducationCode'				= NULL
		,'WebSiteUrl'					= CASE WHEN LTRIM(RTRIM(I.vchurl)) = '' THEN NULL ELSE LTRIM(RTRIM(I.vchurl)) END
		,'FamilyStatusCode'				= NULL
		,'FtpSiteUrl'					= NULL
		,'EMailAddress1'				= CASE WHEN LTRIM(RTRIM(I.vchEmailAddress)) = '' THEN NULL ELSE LTRIM(RTRIM(I.vchEmailAddress)) END
		,'SpousesName'					= NULL
		,'AssistantName'				= NULL
		,'EMailAddress2'				= NULL
		,'AssistantPhone'				= NULL
		,'EMailAddress3'				= NULL
		,'DoNotPhone'					= 0 --Per "Data Migration and Contact Methods" email 8/23
		,'ManagerName'					= NULL
		,'ManagerPhone'					= CASE	WHEN (I.iPhoneTypeId = 102328) THEN (CASE WHEN LTRIM(RTRIM(I.vchPhoneNumber)) = '' THEN NULL ELSE LTRIM(RTRIM(I.vchPhoneNumber)) END)
															ELSE (CASE WHEN LTRIM(RTRIM(CustomerPhone_FaxAlt.vchPhoneNumber)) = '' THEN NULL ELSE LTRIM(RTRIM(CustomerPhone_FaxAlt.vchPhoneNumber)) END) END
		,'DoNotFax'						= 1
		,'DoNotEMail'					= CASE WHEN iIndividualid in (SELECT iownerid FROM RIP_Onyx.dbo.CustomerCampaign WHERE iTrackingId = 1163 AND tiRecordStatus = 1) THEN 1 --when marked as spam then do not allow 
													ELSE 0 END  --Per "Data Migration and Contact Methods" email 8/23
		,'DoNotPostalMail'				= 0 --Per "Data Migration and Contact Methods" email 8/23
		,'DoNotBulkEMail'				= CASE WHEN iIndividualid in (SELECT iownerid FROM RIP_Onyx.dbo.CustomerCampaign WHERE iTrackingId = 1163 AND tiRecordStatus = 1) THEN 1 --when marked as spam then do not allow 
													ELSE 0 END 
		,'DoNotBulkPostalMail'			= 0
		,'AccountRoleCode'				= NULL
		,'TerritoryCode'				= 1
		,'IsPrivate'					= 0
        ,'CreditLimit'					= NULL
		,'CreatedOn'					= LTRIM(RTRIM(I.dtInsertDate))
		,'CreditOnHold'					= 0
		,'CreatedBy'					= ISNULL(LTRIM(RTRIM(CreatedBy.SystemUserId)),@CreatedBy)
	    ,'ModifiedOn'					= LTRIM(RTRIM(I.dtUpdateDate))
	    ,'ModifiedBy'					= ISNULL(LTRIM(RTRIM(ModifiedBy.SystemUserId)),@ModifiedBy)
        ,'NumberOfChildren'				= NULL	
        ,'ChildrensNames'				= NULL
        ,'VersionNumber'				= NULL
        ,'MobilePhone'					= CASE	WHEN (I.iPhoneTypeId = 103) THEN (CASE WHEN LTRIM(RTRIM(I.vchPhoneNumber)) = '' THEN NULL ELSE LTRIM(RTRIM(I.vchPhoneNumber)) END)
															ELSE (CASE WHEN LTRIM(RTRIM(CustomerPhone_Mobile.vchPhoneNumber)) = '' THEN NULL ELSE LTRIM(RTRIM(CustomerPhone_Mobile.vchPhoneNumber)) END) END								
        ,'Pager'						= CASE	WHEN (I.iPhoneTypeId = 339) THEN (CASE WHEN LTRIM(RTRIM(I.vchPhoneNumber)) = '' THEN NULL ELSE LTRIM(RTRIM(I.vchPhoneNumber)) END)
															ELSE (CASE WHEN LTRIM(RTRIM(CustomerPhone_Pager.vchPhoneNumber)) = '' THEN NULL ELSE LTRIM(RTRIM(CustomerPhone_Pager.vchPhoneNumber)) END) END
        ,'Telephone1'					= CASE	WHEN (I.iPhoneTypeId = 100136) THEN (CASE WHEN LTRIM(RTRIM(I.vchPhoneNumber)) = '' THEN NULL ELSE LTRIM(RTRIM(I.vchPhoneNumber)) END)
															ELSE (CASE WHEN LTRIM(RTRIM(CustomerPhone_Main.vchPhoneNumber)) = '' THEN NULL ELSE LTRIM(RTRIM(CustomerPhone_Main.vchPhoneNumber)) END) END
        ,'Telephone2'					= CASE	WHEN (I.iPhoneTypeId = 102327) THEN (CASE WHEN LTRIM(RTRIM(I.vchPhoneNumber)) = '' THEN NULL ELSE LTRIM(RTRIM(I.vchPhoneNumber)) END)
															ELSE (CASE WHEN LTRIM(RTRIM(CustomerPhone_MainAlt.vchPhoneNumber)) = '' THEN NULL ELSE LTRIM(RTRIM(CustomerPhone_MainAlt.vchPhoneNumber)) END) END
        ,'Telephone3'					= CASE	WHEN (I.iPhoneTypeId = 119) THEN (CASE WHEN LTRIM(RTRIM(I.vchPhoneNumber)) = '' THEN NULL ELSE LTRIM(RTRIM(I.vchPhoneNumber)) END)
															ELSE (CASE WHEN LTRIM(RTRIM(CustomerPhone_Home.vchPhoneNumber)) = '' THEN NULL ELSE LTRIM(RTRIM(CustomerPhone_Home.vchPhoneNumber)) END) END
        ,'Fax'							= CASE	WHEN (I.iPhoneTypeId = 115) THEN (CASE WHEN LTRIM(RTRIM(I.vchPhoneNumber)) = '' THEN NULL ELSE LTRIM(RTRIM(I.vchPhoneNumber)) END)
															ELSE (CASE WHEN LTRIM(RTRIM(CustomerPhone_Fax.vchPhoneNumber)) = '' THEN NULL ELSE LTRIM(RTRIM(CustomerPhone_Fax.vchPhoneNumber)) END) END
													
	    ,'Aging30'						= NULL
	    ,'StateCode'					= CASE WHEN I.istatusid = 329 THEN 1 ELSE 0 END --when Individual record is inactive in Onyx set to inactive in CRM
        ,'Aging60'						= NULL
        ,'StatusCode'					= CASE WHEN I.istatusid = 329 THEN 2 ELSE 1 END --when Individual record is inactive in Onyx set to inactive in CRM
        ,'Aging90'						= NULL
        ,'PreferredSystemUserId'		= NULL
        ,'PreferredServiceId'			= NULL
        ,'MasterId'						= NULL
        ,'PreferredAppointmentDayCode'	= NULL
        ,'PreferredAppointmentTimeCode' = 1
        ,'DoNotSendMM'					= 0
        ,'Merged'						= 0 --tracked post migration
        ,'ExternalUserIdentifier'		= NULL
        ,'SubscriptionId'				= NULL
        ,'PreferredEquipmentId'			= NULL
        ,'LastUsedInCampaign'			= NULL
        ,'TransactionCurrencyId'		= CASE WHEN I.vchUser7 = 102423 THEN (SELECT TransactionCurrencyId FROM DataMigration_MSCRM.dbo.TransactionCurrencyBase WHERE ISOCurrencyCode = 'USD') 
											   WHEN I.vchUser7 = 102425 THEN (SELECT TransactionCurrencyId FROM DataMigration_MSCRM.dbo.TransactionCurrencyBase WHERE ISOCurrencyCode = 'EUR') 
											   WHEN I.vchUser7 = 103741 THEN (SELECT TransactionCurrencyId FROM DataMigration_MSCRM.dbo.TransactionCurrencyBase WHERE ISOCurrencyCode = 'AUD') 
									    	   WHEN I.vchUser7 = 102424 AND I.chCountryCode = 'GB' THEN (SELECT TransactionCurrencyId FROM DataMigration_MSCRM.dbo.TransactionCurrencyBase WHERE ISOCurrencyCode = 'GBP') 
											   WHEN I.vchUser7 = 102424 AND I.chCountryCode <> 'GB' THEN (SELECT TransactionCurrencyId FROM DataMigration_MSCRM.dbo.TransactionCurrencyBase WHERE ISOCurrencyCode = 'EUR') 
											ELSE LTRIM(RTRIM(@TransactionCurrencyId)) END
        ,'OverriddenCreatedOn'			= NULL
        ,'ExchangeRate'					= LTRIM(RTRIM(@ExchangeRate))
        ,'ImportSequenceNumber'			= NULL
        ,'TimeZoneRuleVersionNumber'	= NULL
        ,'UTCConversionTimeZoneCode'	= NULL
        ,'AnnualIncome_Base'			= NULL
        ,'CreditLimit_Base'				= NULL
        ,'Aging60_Base'					= NULL
        ,'Aging90_Base'					= NULL
        ,'Aging30_Base'					= NULL
        ,'OwnerId'						= COALESCE(TB.SystemUserId,GBTeam.SystemUserId, USTeam.SystemUserId, OtherTeam.SystemUserId, CASE MTBCountry.MTBCompany WHEN 102423 THEN @UnassignedTeamINC WHEN 102424 THEN @UnassignedTeamLTD ELSE @UnassignedTeam END)
        ,'CreatedOnBehalfBy'			= NULL
        ,'IsAutoCreate'					= 0
        ,'ModifiedOnBehalfBy'			= NULL
        ,'ParentCustomerId'				= CASE WHEN LTRIM(RTRIM(Account.AccountId)) = '' THEN NULL ELSE LTRIM(RTRIM(Account.AccountId)) END
        ,'ParentCustomerIdType'			= 1
        ,'ParentCustomerIdName'			= CASE WHEN LTRIM(RTRIM(AccountBase.Name)) = '' THEN NULL ELSE LTRIM(RTRIM(AccountBase.Name)) END
        ,'OwnerIdType'					= @OwnerIdType         
        ,'ParentCustomerIdYomiName'		= NULL
        ,'MTB_AuthorAAP'			= CASE WHEN exists (SELECT DISTINCT icontactid FROM rip_onyx.dbo.Contact N WHERE N.iContactId = I.iIndividualid 
											AND iContactTypeID = 95 and N.tirecordstatus = 1 )  THEN 1 ELSE 0 END

        ,'MTB_BillingFax'			= CASE	WHEN (I.iPhoneTypeId = 102711) THEN (CASE WHEN LTRIM(RTRIM(I.vchPhoneNumber)) = '' THEN NULL ELSE LTRIM(RTRIM(I.vchPhoneNumber)) END)
															ELSE (CASE WHEN LTRIM(RTRIM(CustomerPhone_BillingFax.vchPhoneNumber)) = '' THEN NULL ELSE LTRIM(RTRIM(CustomerPhone_BillingFax.vchPhoneNumber)) END) END

        ,'MTB_BillingMainPhone'		= CASE	WHEN (I.iPhoneTypeId = 102710) THEN (CASE WHEN LTRIM(RTRIM(I.vchPhoneNumber)) = '' THEN NULL ELSE LTRIM(RTRIM(I.vchPhoneNumber)) END)
															ELSE (CASE WHEN LTRIM(RTRIM(CustomerPhone_BillingMain.vchPhoneNumber)) = '' THEN NULL ELSE LTRIM(RTRIM(CustomerPhone_BillingMain.vchPhoneNumber)) END) END

		,'MTB_CustomerSubTypeCode'	= CASE WHEN Company.iCompanyTypeCode IN (102331,102430) THEN Account.MTB_CustomerSubTypeCode --Company of Type = ILR or Reseller, then migrate Type/SubType same as linked to Channel Account Type/SubType
											   WHEN I.vchUser6 = 102368 THEN NULL --if Sales team = CRS1 then Sub Type to NULL
											   ELSE (LTRIM(RTRIM(I.iUserSubTypeId))) END

		,'MTB_DonotallowNewsletter' = CASE WHEN (SELECT Q.vchResponseText
															FROM rip_onyx.dbo.CustomerProfile P
															LEFT OUTER  JOIN rip_onyx.dbo.CustomerProfileQuestion Q
															ON P.iProfileId = Q.iProfileID
															WHERE P.iOwnerid = I.iIndividualid
															AND iQuestionId IN (745)AND isurveyid = 76
															AND P.tiRecordStatus = 1
															AND Q.tiRecordStatus = 1) = 'Yes' THEN 0 ELSE 1 END 
															
												
		
		,'MTB_DonotallowProductAlertsTrainingAnnoun' =  CASE WHEN (SELECT Q.vchResponseText
																	FROM rip_onyx.dbo.CustomerProfile P
																	LEFT OUTER  JOIN rip_onyx.dbo.CustomerProfileQuestion Q
																	ON P.iProfileId = Q.iProfileID
																	WHERE P.iOwnerid = I.iIndividualid
																	AND iQuestionId IN (746)AND isurveyid = 76
																	AND P.tiRecordStatus = 1
																	AND Q.tiRecordStatus = 1) = 'Yes' THEN 0 ELSE 1 END
																
										
	        
  		,'MTB_EmailStatus'			= CASE WHEN I.vchuser4 = 102395 THEN 102395 
											   WHEN I.vchuser4 = 104187 THEN 104187 	
												ELSE NULL END
      
        ,'MTB_ID'					= LTRIM(RTRIM(I.iIndividualId))
		,'MTB_ID_Search'			= LTRIM(RTRIM(I.iIndividualId))
		,'MTB_InstructorLecturer'	= CASE WHEN exists (SELECT DISTINCT icontactid FROM rip_onyx.dbo.Contact N WHERE N.iContactId = I.iIndividualid 
												AND iContactTypeID = 98 and N.tirecordstatus = 1 )  THEN 1 ELSE 0 END
       	,'MTB_IsTrainer'			= 0
		,'MTB_ITContact'			= CASE WHEN exists (SELECT DISTINCT icontactid FROM rip_onyx.dbo.Contact N WHERE N.iContactId = I.iIndividualid 
												AND iContactTypeID = 314 and N.tirecordstatus = 1 )  THEN 1 ELSE 0 END
		,'MTB_KnowledgeableResource'= CASE WHEN exists (SELECT DISTINCT icontactid FROM rip_onyx.dbo.Contact N WHERE N.iContactId = I.iIndividualid 
												AND iContactTypeID = 219 and N.tirecordstatus = 1 )  THEN 1 ELSE 0 END
		,'MTB_LanguagePreference'	= CASE WHEN LTRIM(RTRIM(I.vchuser8)) = '' THEN NULL ELSE LTRIM(RTRIM(I.vchuser8)) END
		,'MTB_MailStatus'			= NULL
		,'MTB_MTBActivated'		= CASE WHEN exists(SELECT DISTINCT vchProductId FROM rip_onyx.dbo.Incident N WHERE N.iContactId = I.iIndividualid AND N.iIncidentTypeId = 103738 
											and	N.tirecordstatus = 1 AND (N.vchProductid LIKE '%MTB%' OR N.vchProductid LIKE '%MTB%'))  THEN 1 ELSE 0 END
		,'MTB_MTBStatisticalSoftwareUsed2' = CASE WHEN (SELECT Q.vchResponseText
															FROM rip_onyx.dbo.CustomerProfile P
															LEFT OUTER  JOIN rip_onyx.dbo.CustomerProfileQuestion Q
															ON P.iProfileId = Q.iProfileID
															WHERE P.iOwnerid = I.iIndividualid
															AND iQuestionId IN (742)AND isurveyid = 75
															AND P.tiRecordStatus = 1
															AND Q.tiRecordStatus = 1) = 'Yes' THEN '908600000' 
															WHEN (SELECT Q.vchResponseText
															FROM rip_onyx.dbo.CustomerProfile P
															LEFT OUTER  JOIN rip_onyx.dbo.CustomerProfileQuestion Q
															ON P.iProfileId = Q.iProfileID
															WHERE P.iOwnerid = I.iIndividualid
															AND iQuestionId IN (742)AND isurveyid = 75
															AND P.tiRecordStatus = 1
															AND Q.tiRecordStatus = 1) = 'No' THEN '908600001' ELSE NULL END
																											
        ,'MTB_PrimaryPhone'			= CASE WHEN LTRIM(RTRIM(I.iPhoneTypeId)) = '' THEN NULL ELSE LTRIM(RTRIM(I.iPhoneTypeId)) END
		,'MTB_ProfileComplete'		= CASE WHEN I.vchUser1 IS null THEN 0
											   WHEN I.vchUser1 = 102228 THEN 0
											   			   ELSE 1 END
		,'MTB_PurchasingAgent'		= 0
		,'MTB_QualityCompanionActivated'= CASE WHEN EXISTS (SELECT DISTINCT vchProductId FROM rip_onyx.dbo.Incident N WHERE N.iContactId = I.iIndividualid AND N.iIncidentTypeId = 103738 
											and	N.tirecordstatus = 1 AND (N.vchProductid LIKE '%Companion%'))  THEN 1 ELSE 0 END
		,'MTB_QualityCompanionUsed2'= CASE WHEN (SELECT Q.vchResponseText
															FROM rip_onyx.dbo.CustomerProfile P
															LEFT OUTER  JOIN rip_onyx.dbo.CustomerProfileQuestion Q
															ON P.iProfileId = Q.iProfileID
															WHERE P.iOwnerid = I.iIndividualid
															AND iQuestionId IN (743)AND isurveyid = 75
															AND P.tiRecordStatus = 1
															AND Q.tiRecordStatus = 1) = 'Yes' THEN '908600000' 
												WHEN (SELECT Q.vchResponseText
															FROM rip_onyx.dbo.CustomerProfile P
															LEFT OUTER  JOIN rip_onyx.dbo.CustomerProfileQuestion Q
															ON P.iProfileId = Q.iProfileID
															WHERE P.iOwnerid = I.iIndividualid
															AND iQuestionId IN (743)AND isurveyid = 75
															AND P.tiRecordStatus = 1
															AND Q.tiRecordStatus = 1) =	'No' THEN '908600001' ELSE NULL END
															
 		,'MTB_QualityTrainerUsed2'	= CASE WHEN (SELECT Q.vchResponseText
															FROM rip_onyx.dbo.CustomerProfile P
															LEFT OUTER  JOIN rip_onyx.dbo.CustomerProfileQuestion Q
															ON P.iProfileId = Q.iProfileID
															WHERE P.iOwnerid = I.iIndividualid
															AND iQuestionId IN (744)AND isurveyid = 75
															AND P.tiRecordStatus = 1
															AND Q.tiRecordStatus = 1) = 'Yes' THEN '908600000' 
												WHEN (SELECT Q.vchResponseText
															FROM rip_onyx.dbo.CustomerProfile P
															LEFT OUTER  JOIN rip_onyx.dbo.CustomerProfileQuestion Q
															ON P.iProfileId = Q.iProfileID
															WHERE P.iOwnerid = I.iIndividualid
															AND iQuestionId IN (744)AND isurveyid = 75
															AND P.tiRecordStatus = 1
															AND Q.tiRecordStatus = 1) = 'No' THEN '908600001' ELSE NULL  END			
											
		,'MTB_SendToGPINC'			= CASE WHEN I.vchUser5 LIKE '%INC%' THEN 1 ELSE 0 END
		,'MTB_SendToGPLTD'			= CASE WHEN I.vchUser5 LIKE '%LTD%' THEN 1 ELSE 0 END
		,'MTB_SendToGPPTY'			= CASE WHEN I.vchUser5 LIKE '%PTY%' THEN 1 ELSE 0 END
		,'MTB_SendToGPSARL'			= CASE WHEN I.vchUser5 LIKE '%SARL%' THEN 1 ELSE 0 END
		,'MTB_TrainingCalendarColor'= NULL
		,'MTB_VOIPPhone'			= NULL
		,'MTB_WorkshopCoordinator'	= CASE WHEN exists (SELECT DISTINCT icontactid FROM rip_onyx.dbo.Contact N WHERE N.iContactId = I.iIndividualid 
												AND iContactTypeID = 106 and N.tirecordstatus = 1 )  THEN 1 ELSE 0 END
		,'MTB_CampaignId'			=NULL
		,'MTB_SiteId'				= case WHEN I.vchUser7 = 102423 THEN (SELECT SiteId FROM DataMigration_MSCRM.dbo.SiteBase WHERE Name = 'INC') 
											   WHEN I.vchUser7 = 102424 THEN (SELECT SiteId FROM DataMigration_MSCRM.dbo.SiteBase WHERE Name = 'LTD') 
											   WHEN I.vchUser7 = 102425 THEN (SELECT SiteId FROM DataMigration_MSCRM.dbo.SiteBase WHERE Name = 'SARL')
											   WHEN I.vchUser7 = 103741 THEN (SELECT SiteId FROM DataMigration_MSCRM.dbo.SiteBase WHERE Name = 'PTY') 
											   ELSE NULL END
		
		,'MTB_AddressValid'			= CASE WHEN LTRIM(RTRIM(I.bValidAddress)) = '' THEN NULL ELSE LTRIM(RTRIM(I.bValidAddress)) END
		,'MTB_PendingAccountName'	= CASE WHEN I.icompanyid = 0 THEN NULLIF(I.vchCompanyName,'') ELSE NULL END --2012-08-22 CAM Added NULLIF
		,'dnb_dnbinitialassociationdate' = null
		,'dnb_dnbinitialassociationstatus' = null
		,'dnb_DBCompanyId'                 = null
		,'dnb_dbcontactid'				   = null
		,'MTB_overriderequiredfields'  = 0
		,'MTB_FlexAdminLetter'		= CASE WHEN Detail.chproductnumber in ('Global_ES_Flex_Admin',
												'Global_Flex_Admin','Global_FR_Flex_Admin','Global_PT_Flex_Admin') THEN 1
												ELSE 0 END
		,'MTB_consultant'			   = 	CASE WHEN exists (SELECT DISTINCT icontactid FROM rip_onyx.dbo.Contact N WHERE N.iContactId = I.iIndividualid 
												AND iContactTypeID = 97 and N.tirecordstatus = 1 )  THEN 1 --Set Consultant field to yes if the Onyx individual has an ECT of “Consultant
												WHEN I.vchUser6 = 102368 THEN 1 --if Sales team = CRS1 then set as consultant
												ELSE 0 END
		
		
		,'MTB_Spam'					   = CASE WHEN iIndividualid in (SELECT iownerid FROM RIP_Onyx.dbo.CustomerCampaign WHERE iTrackingId = 1163 AND tiRecordStatus = 1) THEN 1
													ELSE 0 END 
		,'RowAction'					   = 'INSERT'


from	rip_onyx.dbo.Individual I
		
					
--Created By / Updated By
			LEFT OUTER JOIN OnyxToMSCRM_STAGE.dbo.UsersMap AS CreatedBy WITH (NOLOCK)
				ON CreatedBy.OnyxId = CASE WHEN (ISNULL(I.chInsertBy,'')='') THEN '#####' ELSE I.chInsertBy END COLLATE Latin1_General_CI_AI
			LEFT OUTER JOIN OnyxToMSCRM_STAGE.dbo.UsersMap AS ModifiedBy WITH (NOLOCK)
				ON ModifiedBy.OnyxId = CASE WHEN (ISNULL(I.chUpdateBy,'')='') THEN '#####' ELSE I.chUpdateBy END COLLATE Latin1_General_CI_AI
		
									
					
--Individual Phone Numbers

				LEFT OUTER JOIN rip_onyx.dbo.CustomerPhone AS CustomerPhone_Mobile WITH (NOLOCK)
					ON CustomerPhone_Mobile.iOwnerID = I.iIndividualId
					AND CustomerPhone_Mobile.iSiteId = I.iSiteId
					AND CustomerPhone_Mobile.iPhoneTypeId = 103
					AND CustomerPhone_Mobile.tiRecordStatus = 1
				LEFT OUTER JOIN rip_onyx.dbo.CustomerPhone AS CustomerPhone_Pager WITH (NOLOCK)
					ON CustomerPhone_Pager.iOwnerID = I.iIndividualId
					AND CustomerPhone_Pager.iSiteId = I.iSiteId
					AND CustomerPhone_Pager.iPhoneTypeId = 339
					AND CustomerPhone_Pager.tiRecordStatus = 1
				LEFT OUTER JOIN rip_onyx.dbo.CustomerPhone AS CustomerPhone_Main WITH (NOLOCK)
					ON CustomerPhone_Main.iOwnerID = I.iIndividualId
					AND CustomerPhone_Main.iSiteId = I.iSiteId
					AND CustomerPhone_Main.iPhoneTypeId = 100136
					AND CustomerPhone_Main.tiRecordStatus = 1
				LEFT OUTER JOIN rip_onyx.dbo.CustomerPhone AS CustomerPhone_MainAlt WITH (NOLOCK)
					ON CustomerPhone_MainAlt.iOwnerID = I.iIndividualId
					AND CustomerPhone_MainAlt.iSiteId = I.iSiteId
					AND CustomerPhone_MainAlt.iPhoneTypeId = 102327
					AND CustomerPhone_MainAlt.tiRecordStatus = 1
				LEFT OUTER JOIN rip_onyx.dbo.CustomerPhone AS CustomerPhone_Home WITH (NOLOCK)
					ON CustomerPhone_Home.iOwnerID = I.iIndividualId
					AND CustomerPhone_Home.iSiteId = I.iSiteId
					AND CustomerPhone_Home.iPhoneTypeId = 119
					AND CustomerPhone_Home.tiRecordStatus = 1
				LEFT OUTER JOIN rip_onyx.dbo.CustomerPhone AS CustomerPhone_Fax WITH (NOLOCK)
					ON CustomerPhone_Fax.iOwnerID = I.iIndividualId
					AND CustomerPhone_Fax.iSiteId = I.iSiteId
					AND CustomerPhone_Fax.iPhoneTypeId = 115
					AND CustomerPhone_Fax.tiRecordStatus = 1
				LEFT OUTER JOIN rip_onyx.dbo.CustomerPhone AS CustomerPhone_FaxAlt WITH (NOLOCK)
					ON CustomerPhone_FaxAlt.iOwnerID = I.iIndividualId
					AND CustomerPhone_FaxAlt.iSiteId = I.iSiteId
					AND CustomerPhone_FaxAlt.iPhoneTypeId = 102328
					AND CustomerPhone_FaxAlt.tiRecordStatus = 1	
				LEFT OUTER JOIN rip_onyx.dbo.CustomerPhone AS CustomerPhone_BillingMain WITH (NOLOCK)
					ON CustomerPhone_BillingMain.iOwnerID = I.iIndividualId
					AND CustomerPhone_BillingMain.iSiteId = I.iSiteId
					AND CustomerPhone_BillingMain.iPhoneTypeId = 102710
					AND CustomerPhone_BillingMain.tiRecordStatus = 1
				LEFT OUTER JOIN rip_onyx.dbo.CustomerPhone AS CustomerPhone_BillingFax WITH (NOLOCK)
					ON CustomerPhone_BillingFax.iOwnerID = I.iIndividualId
					AND CustomerPhone_BillingFax.iSiteId = I.iSiteId
					AND CustomerPhone_BillingFax.iPhoneTypeId = 102711
					AND CustomerPhone_BillingFax.tiRecordStatus = 1					

--Company
				LEFT OUTER JOIN rip_onyx.dbo.Company 
					ON I.icompanyid = Company.icompanyid
					
--OFS Order Header and Order Detail to find if contact has received FlexAdmin Letter
				LEFT outer JOIN rip_onyx.dbo.OrderHeader Header 
					on I.iindividualid = Header.iownerid AND Header.tirecordstatus = 1
					AND iorderid in 
                ( SELECT    MAX(Header.iOrderId) AS MaxOrderId 
                  FROM      rip_onyx.dbo.OrderHeader Header
                            INNER JOIN rip_onyx.dbo.OrderDetail Detail ON Header.iOrderId = Detail.iOrderId
                  WHERE     chproductnumber IN ( 'Global_ES_Flex_Admin',
                                                 'Global_Flex_Admin',
                                                 'Global_FR_Flex_Admin',
                                                 'Global_PT_Flex_Admin' )
                            AND Header.tiRecordStatus = 1
                            AND Detail.tiRecordStatus = 1 
						GROUP BY  Header.iOwnerId
                )
				LEFT OUTER JOIN rip_onyx.dbo.OrderDetail Detail
					ON Header.iorderid = Detail.iorderid 
					AND Detail.tirecordstatus = 1
					
			
/*--Team--*/			
			 LEFT OUTER JOIN rip_onyx.dbo.ReferenceParameters RP WITH (NOLOCK) 
				ON I.vchUser6 = RP.iParameterId
			LEFT OUTER JOIN [OnyxToMSCRM_STAGE].[dbo].[UsersMap] TB WITH (NOLOCK)
				ON RP.vchParameterDesc = TB.OnyxId COLLATE Latin1_General_CI_AI
			--GB
			LEFT OUTER JOIN (SELECT DISTINCT chCountryCode, vchPostCode, chCategory, chTerritory FROM rip_onyx.dbo.CSuTerritoryAssignmentLTD WITH (NOLOCK)) AS TerrLTD
				ON  TerrLTD.chCountryCode = I.chCountryCode 
					AND TerrLTD.vchPostCode = LEFT(I.vchPostCode,2) 
					AND TerrLTD.chCategory = (CASE I.iusertypeid WHEN 101970 THEN 'Academic' WHEN 101971 THEN 'Commercial' END)
					AND I.chCountryCode = 'GB'
			LEFT OUTER JOIN [OnyxToMSCRM_STAGE].[dbo].[UsersMap] GBTeam WITH (NOLOCK)
				ON TerrLTD.chTerritory = GBTeam.OnyxId COLLATE Latin1_General_CI_AI 
			-- US/Canada
			LEFT OUTER JOIN rip_onyx.dbo.CSuTerritoryAssignment USTerr WITH (NOLOCK)
				ON USTerr.chCountryCode = I.chCountryCode 
					AND USTerr.chRegionCode = I.chRegionCode 
					AND USTerr.chCategory = (CASE I.iusertypeid WHEN 101970 THEN 'Academic' WHEN 101971 THEN 'Commercial' END)
					AND I.chCountryCode IN ('US','CA')
			LEFT OUTER JOIN [OnyxToMSCRM_STAGE].[dbo].[UsersMap] USTeam WITH (NOLOCK)
				ON USTerr.chTerritory = USTeam.OnyxId COLLATE Latin1_General_CI_AI 
			-- Other
			LEFT OUTER JOIN (SELECT DISTINCT chCountryCode, chCategory, chTerritory FROM rip_onyx.dbo.CSuTerritoryAssignment WITH (NOLOCK)) AS Territory
				ON Territory.chCountryCode =  I.chCountryCode  
					AND Territory.chCategory = (CASE I.iusertypeid WHEN 101970 THEN 'Academic' WHEN 101971 THEN 'Commercial' END)
					AND I.chCountryCode NOT IN ('GB','US','CA')
			LEFT OUTER JOIN [OnyxToMSCRM_STAGE].[dbo].[UsersMap] OtherTeam WITH (NOLOCK)
				ON Territory.chTerritory = OtherTeam.OnyxId COLLATE Latin1_General_CI_AI  
			--Unassigned Team
			LEFT OUTER JOIN Enterprise.dbo.MTBCountry AS MTBCountry WITH (NOLOCK)
				ON Company.chCountryCode = MTBCountry.[ISO2-Worldtax]

--Parent Account
				LEFT OUTER JOIN DataMigration_MSCRM.dbo.AccountExtensionBase AS Account WITH (NOLOCK)
					ON Account.MTB_ID_Search = I.iCompanyid 
				LEFT OUTER JOIN DataMigration_MSCRM.dbo.AccountBase AS AccountBase WITH (NOLOCK)
					ON Account.AccountId = AccountBase.AccountId
WHERE I.tiRecordStatus = 1 
AND I.icompanyid NOT IN 
	(SELECT iCompanyId FROM rip_onyx.dbo.Company
	WHERE tiRecordStatus = 0)
	
--Add 'John Doe' as a Trainer
UPDATE OnyxToMSCRM_STAGE.dbo.Contact
SET MTB_IsTrainer = 1
WHERE FullName = 'John Doe'


--Bug# 15515
--BUG# 15340
--3/1/2013
--BUG# 16539

--Home to main
UPDATE  OnyxToMSCRM_STAGE.dbo.Contact
SET     Telephone1 = Telephone3 ,
        Telephone3 = NULL ,
        MTB_PrimaryPhone = 100136
WHERE   Telephone1 IS NULL
        AND MTB_PrimaryPhone = 119
        
UPDATE  OnyxToMSCRM_STAGE.dbo.Contact
SET     MTB_PrimaryPhone = 100136
WHERE   MTB_PrimaryPhone = 119

--Main alt to Main
UPDATE  OnyxToMSCRM_STAGE.dbo.Contact
SET     Telephone1 = Telephone2 ,
        Telephone2 = NULL ,
        MTB_PrimaryPhone = 100136
WHERE   Telephone1 IS NULL
        AND Telephone2 IS NOT NULL
        AND MTB_PrimaryPhone = 102327
        
UPDATE  OnyxToMSCRM_STAGE.dbo.Contact
SET     Telephone1 = Telephone2 ,
        Telephone2 = NULL
WHERE   Telephone1 IS NOT NULL
        AND Telephone2 IS NOT NULL  
          
UPDATE  OnyxToMSCRM_STAGE.dbo.Contact
SET     Telephone1 = Telephone2 ,
        Telephone2 = NULL ,
        MTB_PrimaryPhone = 100136
WHERE   Telephone1 IS NOT NULL
        AND Telephone2 IS NOT NULL
        AND MTB_PrimaryPhone = 102327   
   
UPDATE  OnyxToMSCRM_STAGE.dbo.Contact
SET     MTB_PrimaryPhone = NULL
WHERE   MTB_PrimaryPhone = 102327  

--fax alt to fax
UPDATE  OnyxToMSCRM_STAGE.dbo.Contact
SET     Fax = ManagerPhone ,
        ManagerPhone = NULL ,
        MTB_PrimaryPhone = 115
WHERE   fax IS NULL
        AND ManagerPhone IS NOT NULL
        AND MTB_PrimaryPhone = 102328
        
UPDATE  OnyxToMSCRM_STAGE.dbo.Contact
SET     Fax = ManagerPhone ,
        ManagerPhone = NULL
WHERE   fax IS NULL
        AND ManagerPhone IS NOT NULL 

UPDATE  OnyxToMSCRM_STAGE.dbo.Contact
SET     MTB_PrimaryPhone = 115
WHERE   Fax IS NOT NULL
        AND MTB_PrimaryPhone = 102328

UPDATE  OnyxToMSCRM_STAGE.dbo.Contact
SET     MTB_PrimaryPhone = 100136
WHERE   MTB_PrimaryPhone = 339

UPDATE  OnyxToMSCRM_STAGE.dbo.Contact
SET     MTB_PrimaryPhone = 100136
WHERE   MTB_PrimaryPhone = 102

--Bug 16468
UPDATE  [OnyxToMSCRM_STAGE].[dbo].[Contact]
SET     ManagerPhone = dbo.filternondigit(managerphone) ,
        MobilePhone = dbo.filternondigit(mobilephone) ,
        Pager = dbo.filternondigit(pager) ,
        Telephone1 = dbo.filternondigit(telephone1) ,
        Fax = dbo.filternondigit(fax),
        MTB_BillingFax = dbo.filternondigit(MTB_BillingFax),
        MTB_BillingMainPhone  = dbo.filternondigit(MTB_BillingMainPhone)

--BUG 16950
UPDATE OnyxToMSCRM_STAGE.dbo.Contact
SET OwnerId		= CASE MTB_SiteId WHEN @CompanySiteINC THEN @UnassignedTeamINC ELSE @UnassignedTeamLTD END 
WHERE OwnerId = @UnassignedTeam
	AND MTB_SiteId IN (@CompanySiteINC, @CompanySiteLTD)


--Insert data into BASE table
		
		INSERT INTO DataMigration_MSCRM.dbo.ContactBase
		(
		   [ContactId],
		   [DefaultPriceLevelId]
		  ,[CustomerSizeCode]
		  ,[CustomerTypeCode]
		  ,[PreferredContactMethodCode]
		  ,[LeadSourceCode]
		  ,[OriginatingLeadId]
		  ,[OwningBusinessUnit]
		  ,[PaymentTermsCode]
		  ,[ShippingMethodCode]
		  ,[ParticipatesInWorkflow]
		  ,[IsBackofficeCustomer]
		  ,[Salutation]
		  ,[JobTitle]
		  ,[FirstName]
		  ,[Department]
		  ,[NickName]
		  ,[MiddleName]
		  ,[LastName]
		  ,[Suffix]
		  ,[YomiFirstName]
		  ,[FullName]
		  ,[YomiMiddleName]
		  ,[YomiLastName]
		  ,[Anniversary]
		  ,[BirthDate]
		  ,[GovernmentId]
		  ,[YomiFullName]
		  ,[Description]
		  ,[EmployeeId]
		  ,[GenderCode]
		  ,[AnnualIncome]
		  ,[HasChildrenCode]
		  ,[EducationCode]
		  ,[WebSiteUrl]
		  ,[FamilyStatusCode]
		  ,[FtpSiteUrl]
		  ,[EMailAddress1]
		  ,[SpousesName]
		  ,[AssistantName]
		  ,[EMailAddress2]
		  ,[AssistantPhone]
		  ,[EMailAddress3]
		  ,[DoNotPhone]
		  ,[ManagerName]
		  --,[ManagerPhone]
		  ,[DoNotFax]
		  ,[DoNotEMail]
		  ,[DoNotPostalMail]
		  ,[DoNotBulkEMail]
		  ,[DoNotBulkPostalMail]
		  ,[AccountRoleCode]
		  ,[TerritoryCode]
		  ,[IsPrivate]
		  ,[CreditLimit]
		  ,[CreatedOn]
		  ,[CreditOnHold]
		  ,[CreatedBy]
		  ,[ModifiedOn]
		  ,[ModifiedBy]
		  ,[NumberOfChildren]
		  ,[ChildrensNames]
		  ,[MobilePhone]
		  --,[Pager]
		  ,[Telephone1]
		  --,[Telephone2]
		  --,[Telephone3]
		  ,[Fax]
		  ,[Aging30]
		  ,[StateCode]
		  ,[Aging60]
		  ,[StatusCode]
		  ,[Aging90]
		  ,[PreferredSystemUserId]
		  ,[PreferredServiceId]
		  ,[MasterId]
		  ,[PreferredAppointmentDayCode]
		  ,[PreferredAppointmentTimeCode]
		  ,[DoNotSendMM]
		  ,[Merged]
		  ,[ExternalUserIdentifier]
		  ,[SubscriptionId]
		  ,[PreferredEquipmentId]
		  ,[LastUsedInCampaign]
		  ,[TransactionCurrencyId]
		  ,[OverriddenCreatedOn]
		  ,[ExchangeRate]
		  ,[ImportSequenceNumber]
		  ,[TimeZoneRuleVersionNumber]
		  ,[UTCConversionTimeZoneCode]
		  ,[AnnualIncome_Base]
		  ,[CreditLimit_Base]
		  ,[Aging60_Base]
		  ,[Aging90_Base]
		  ,[Aging30_Base]
		  ,[OwnerId]
		  ,[CreatedOnBehalfBy]
		  ,[IsAutoCreate]
		  ,[ModifiedOnBehalfBy]
		  ,[ParentCustomerId]
		  ,[ParentCustomerIdType]
		  ,[ParentCustomerIdName]
		  ,[OwnerIdType]
		)
		SELECT	[ContactId],
		   [DefaultPriceLevelId]
		  ,[CustomerSizeCode]
		  ,[CustomerTypeCode]
		  ,[PreferredContactMethodCode]
		  ,[LeadSourceCode]
		  ,[OriginatingLeadId]
		  ,[OwningBusinessUnit]
		  ,[PaymentTermsCode]
		  ,[ShippingMethodCode]
		  ,[ParticipatesInWorkflow]
		  ,[IsBackofficeCustomer]
		  ,[Salutation]
		  ,[JobTitle]
		  ,[FirstName]
		  ,[Department]
		  ,[NickName]
		  ,[MiddleName]
		  ,[LastName]
		  ,[Suffix]
		  ,[YomiFirstName]
		  ,[FullName]
		  ,[YomiMiddleName]
		  ,[YomiLastName]
		  ,[Anniversary]
		  ,[BirthDate]
		  ,[GovernmentId]
		  ,[YomiFullName]
		  ,[Description]
		  ,[EmployeeId]
		  ,[GenderCode]
		  ,[AnnualIncome]
		  ,[HasChildrenCode]
		  ,[EducationCode]
		  ,[WebSiteUrl]
		  ,[FamilyStatusCode]
		  ,[FtpSiteUrl]
		  ,[EMailAddress1]
		  ,[SpousesName]
		  ,[AssistantName]
		  ,[EMailAddress2]
		  ,[AssistantPhone]
		  ,[EMailAddress3]
		  ,[DoNotPhone]
		  ,[ManagerName]
		  --,[ManagerPhone]
		  ,[DoNotFax]
		  ,[DoNotEMail]
		  ,[DoNotPostalMail]
		  ,[DoNotBulkEMail]
		  ,[DoNotBulkPostalMail]
		  ,[AccountRoleCode]
		  ,[TerritoryCode]
		  ,[IsPrivate]
		  ,[CreditLimit]
		  ,[CreatedOn]
		  ,[CreditOnHold]
		  ,[CreatedBy]
		  ,[ModifiedOn]
		  ,[ModifiedBy]
		  ,[NumberOfChildren]
		  ,[ChildrensNames]
		  ,[MobilePhone]
		  --,[Pager]
		  ,[Telephone1]
		  --,[Telephone2]
		  --,[Telephone3]
		  ,[Fax]
		  ,[Aging30]
		  ,[StateCode]
		  ,[Aging60]
		  ,[StatusCode]
		  ,[Aging90]
		  ,[PreferredSystemUserId]
		  ,[PreferredServiceId]
		  ,[MasterId]
		  ,[PreferredAppointmentDayCode]
		  ,[PreferredAppointmentTimeCode]
		  ,[DoNotSendMM]
		  ,[Merged]
		  ,[ExternalUserIdentifier]
		  ,[SubscriptionId]
		  ,[PreferredEquipmentId]
		  ,[LastUsedInCampaign]
		  ,[TransactionCurrencyId]
		  ,[OverriddenCreatedOn]
		  ,[ExchangeRate]
		  ,[ImportSequenceNumber]
		  ,[TimeZoneRuleVersionNumber]
		  ,[UTCConversionTimeZoneCode]
		  ,[AnnualIncome_Base]
		  ,[CreditLimit_Base]
		  ,[Aging60_Base]
		  ,[Aging90_Base]
		  ,[Aging30_Base]
		  ,[OwnerId]
		  ,[CreatedOnBehalfBy]
		  ,[IsAutoCreate]
		  ,[ModifiedOnBehalfBy]
		  ,[ParentCustomerId]
		  ,[ParentCustomerIdType]
		  ,[ParentCustomerIdName]
		  ,[OwnerIdType]
		FROM	OnyxToMSCRM_STAGE.dbo.Contact
		WHERE	Contact.RowAction = 'INSERT'
		
		--Insert data into EXTENSION table
		
		INSERT INTO DataMigration_MSCRM.dbo.ContactExtensionBase
		(
				[ContactId]
			  ,[MTB_AuthorAAP]
			  ,[MTB_BillingFax]
			  ,[MTB_BillingMainPhone]
			  ,[MTB_CustomerSubTypeCode]
			  ,[MTB_DonotallowNewsletter]
			  ,[MTB_DonotallowProductAlertsTrainingAnnoun]
			  ,[MTB_EmailStatus]
			  ,[MTB_ID]
			  ,[MTB_ID_Search]
			  ,[MTB_InstructorLecturer]
			  ,[MTB_IsTrainer]
			  ,[MTB_ITContact]
			  ,[MTB_KnowledgeableResource]
			  ,[MTB_LanguagePreference]
			  ,[MTB_MailStatus]
			  ,[MTB_MTBActivated]
			  ,[MTB_MTBStatisticalSoftwareUsed2]
			  ,[MTB_PrimaryPhone]
			  ,[MTB_ProfileComplete]
			  ,[MTB_PurchasingAgent]
			  ,[MTB_QualityCompanionActivated]
			  ,[MTB_QualityCompanionUsed2]
			  ,[MTB_QualityTrainerUsed2]
			  ,[MTB_SendToGPINC]
			  ,[MTB_SendToGPLTD]
			  ,[MTB_SendToGPPTY]
			  ,[MTB_SendToGPSARL]
			  ,[MTB_TrainingCalendarColor]
			  ,[MTB_VOIPPhone]
			  ,[MTB_WorkshopCoordinator]
			  ,[MTB_CampaignId]
			  ,[MTB_SiteId]
			  ,[MTB_AddressValid]
			  ,[MTB_PendingAccountName]
			  ,[dnb_dnbinitialassociationdate]
			  ,[dnb_dnbinitialassociationstatus]
			  ,[dnb_DBCompanyId]
			  ,[dnb_dbcontactid]
			  ,[MTB_overriderequiredfields]
			  ,[MTB_FlexAdminLetter]
			  ,[MTB_consultant]
			  ,[MTB_Spam]
		)
		SELECT	[ContactId]
			  ,[MTB_AuthorAAP]
			  ,[MTB_BillingFax]
			  ,[MTB_BillingMainPhone]
			  ,[MTB_CustomerSubTypeCode]
			  ,[MTB_DonotallowNewsletter]
			  ,[MTB_DonotallowProductAlertsTrainingAnnoun]
			  ,[MTB_EmailStatus]
			  ,[MTB_ID]
			  ,[MTB_ID_Search]
			  ,[MTB_InstructorLecturer]
			  ,[MTB_IsTrainer]
			  ,[MTB_ITContact]
			  ,[MTB_KnowledgeableResource]
			  ,[MTB_LanguagePreference]
			  ,[MTB_MailStatus]
			  ,[MTB_MTBActivated]
			  ,[MTB_MTBStatisticalSoftwareUsed2]
			  ,[MTB_PrimaryPhone]
			  ,[MTB_ProfileComplete]
			  ,[MTB_PurchasingAgent]
			  ,[MTB_QualityCompanionActivated]
			  ,[MTB_QualityCompanionUsed2]
			  ,[MTB_QualityTrainerUsed2]
			  ,[MTB_SendToGPINC]
			  ,[MTB_SendToGPLTD]
			  ,[MTB_SendToGPPTY]
			  ,[MTB_SendToGPSARL]
			  ,[MTB_TrainingCalendarColor]
			  ,[MTB_VOIPPhone]
			  ,[MTB_WorkshopCoordinator]
			  ,[MTB_CampaignId]
			  ,[MTB_SiteId]
			  ,[MTB_AddressValid]
			  ,[MTB_PendingAccountName]
			  ,[dnb_dnbinitialassociationdate]
			  ,[dnb_dnbinitialassociationstatus]
			  ,[dnb_DBCompanyId]
			  ,[dnb_dbcontactid]
			  ,0
			  ,[MTB_FlexAdminLetter]
			  ,[MTB_consultant]
			  ,[MTB_Spam]
		FROM	OnyxToMSCRM_STAGE.dbo.Contact
		WHERE	Contact.RowAction = 'INSERT'



	END TRY
	BEGIN CATCH
		-- Log Row - ERROR
		SELECT	@Success		= 0,
				@ErrorId		= ERROR_NUMBER(),
				@ErrorMessage	= ERROR_MESSAGE()
		EXEC OnyxToMSCRM_STAGE.dbo.DataMigrationLog_RowError @LogId,@RowId,@ErrorId,@ErrorMessage
	END CATCH

	-- Log Row - Stop
	SELECT @RowsProcessed = COUNT(1) FROM OnyxToMSCRM_STAGE.dbo.Contact WITH (NOLOCK)
	EXEC OnyxToMSCRM_STAGE.dbo.DataMigrationLog_RowStop @LogId,@RowId,@Success,@RowsProcessed,NULL

	RETURN @Success
END

GO
GRANT EXEC ON dbo.Contact_Import TO DEVELOPER

GO
