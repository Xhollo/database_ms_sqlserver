IF COL_LENGTH(N'tblInsuree', N'Vulnerability') IS NULL
ALTER TABLE tblInsuree
ADD Vulnerability BIT NOT NULL DEFAULT(0)
GO

IF NOT EXISTS(SELECT 1 FROM tblControls WHERE FieldName = N'Vulnerability')
INSERT INTO tblControls(FieldName, Adjustibility, Usage)
VALUES(N'Vulnerability', N'O', N'Insuree, Family')
GO

DROP PROCEDURE [dbo].[uspImportOffLineExtract4]
GO

DROP TYPE [dbo].[xInsuree]
GO

CREATE TYPE [dbo].[xInsuree] AS TABLE(
	[InsureeID] [int] NULL,
	[FamilyID] [int] NULL,
	[CHFID] [nvarchar](12) NULL,
	[LastName] [nvarchar](100) NULL,
	[OtherNames] [nvarchar](100) NULL,
	[DOB] [date] NULL,
	[Gender] [char](1) NULL,
	[Marital] [char](1) NULL,
	[IsHead] [bit] NULL,
	[passport] [nvarchar](25) NULL,
	[Phone] [nvarchar](50) NULL,
	[PhotoID] [int] NULL,
	[PhotoDate] [date] NULL,
	[CardIssued] [bit] NULL,
	[ValidityFrom] [datetime] NULL,
	[ValidityTo] [datetime] NULL,
	[LegacyID] [int] NULL,
	[AuditUserID] [int] NULL,
	[Relationship] [smallint] NULL,
	[Profession] [smallint] NULL,
	[Education] [smallint] NULL,
	[Email] [nvarchar](100) NULL,
	[isOffline] [bit] NULL,
	[TypeOfId] [nvarchar](1) NULL,
	[HFID] [int] NULL,
	[CurrentAddress] [nvarchar](200) NULL,
	[CurrentVillage] [int] NULL,
	[GeoLocation] [nvarchar](250) NULL,
	[Vulnerability] [bit]  NULL
)
GO

CREATE PROCEDURE [dbo].[uspImportOffLineExtract4]
	
	@HFID as int = 0,
	@LocationId INT = 0,
	@AuditUser as int = 0 ,
	@xtFamilies dbo.xFamilies READONLY,
	@xtInsuree dbo.xInsuree READONLY,
	@xtPhotos dbo.xPhotos READONLY,
	@xtPolicy dbo.xPolicy READONLY,
	@xtPremium dbo.xPremium READONLY,
	@xtInsureePolicy dbo.xInsureePolicy READONLY,
	@FamiliesIns as bigint = 0 OUTPUT  ,
	@FamiliesUpd as bigint = 0 OUTPUT  ,
	@InsureeIns as bigint = 0 OUTPUT  ,
	@InsureeUpd as bigint  = 0 OUTPUT  ,
	@PhotoIns as bigint = 0 OUTPUT  ,
	@PhotoUpd as bigint  = 0 OUTPUT,
	@PolicyIns as bigint = 0 OUTPUT  ,
	@PolicyUpd as bigint  = 0 OUTPUT , 
	@PremiumIns as bigint = 0 OUTPUT  ,
	@PremiumUpd as bigint  = 0 OUTPUT
	
	
AS
BEGIN
	
BEGIN TRY
	/*
	SELECT * INTO TstFamilies  FROM @xtFamilies
	SELECT * INTO TstInsuree  FROM @xtInsuree
	SELECT * INTO TstPhotos  FROM @xtPhotos
	SELECT * INTO TstPolicy  FROM @xtPolicy
	SELECT * INTO TstPremium  FROM @xtPremium
	SELECT * INTO TstInsureePolicy  FROM @xtInsureePolicy
	RETURN
	**/

	--**S Families**
	SET NOCOUNT OFF
	UPDATE Src SET Src.InsureeID = Etr.InsureeID ,Src.LocationId = Etr.LocationId ,Src.Poverty = Etr.Poverty , Src.ValidityFrom = Etr.ValidityFrom , Src.ValidityTo = Etr.ValidityTo , Src.LegacyID = Etr.LegacyID, Src.AuditUserID = @AuditUser, Src.FamilyType = Etr.FamilyType, Src.FamilyAddress = Etr.FamilyAddress,Src.ConfirmationType = Etr.ConfirmationType FROM tblFamilies Src , @xtFamilies Etr WHERE Src.FamilyID = Etr.FamilyID 
	SET @FamiliesUpd = @@ROWCOUNT
	SET NOCOUNT ON
	
	SET NOCOUNT OFF;
	SET IDENTITY_INSERT [tblFamilies] ON
	
	INSERT INTO tblFamilies ([FamilyID],[InsureeID],[LocationId],[Poverty],[ValidityFrom],[ValidityTo],[LegacyID],[AuditUserID],FamilyType, FamilyAddress,Ethnicity,ConfirmationNo,ConfirmationType) 
	SELECT [FamilyID],[InsureeID],[LocationId],[Poverty],[ValidityFrom],[ValidityTo],[LegacyID],@AuditUser,FamilyType, FamilyAddress,Ethnicity,ConfirmationNo,  ConfirmationType FROM @xtFamilies WHERE [FamilyID] NOT IN 
	(SELECT FamilyID  FROM tblFamilies )
	--AND (DistrictID = @LocationId OR @LocationId = 0) 'To do: Insuree can belong to different district.So his/her family belonging to another district should not be ruled out.
	
	SET @FamiliesIns = @@ROWCOUNT
	SET IDENTITY_INSERT [tblFamilies] OFF
	SET NOCOUNT ON
	--**E Families**
	
	--**S Photos**
	SET NOCOUNT OFF
	UPDATE Src SET Src.InsureeID = Etr.InsureeID , Src.CHFID = Etr.CHFID , Src.PhotoFolder = Etr.PhotoFolder ,Src.PhotoFileName = Etr.PhotoFileName , Src.OfficerID = Etr.OfficerID , Src.PhotoDate = Etr.PhotoDate , Src.ValidityFrom = Etr.ValidityFrom , Src.ValidityTo = Etr.ValidityTo , Src.AuditUserID = @AuditUser  
	FROM @xtPhotos Etr INNER JOIN TblPhotos Src ON Src.PhotoID = Etr.PhotoID INNER JOIN (SELECT Ins.InsureeID FROM @xtInsuree Ins WHERE ValidityTo IS NULL) Ins ON Ins.InsureeID  = Src.InsureeID 
	
	SET @PhotoUpd = @@ROWCOUNT
	SET NOCOUNT ON
	
	SET NOCOUNT OFF;
	SET IDENTITY_INSERT [tblPhotos] ON
	
	
	INSERT INTO tblPhotos (PhotoID,InsureeID, CHFID, PhotoFolder, PhotoFileName, OfficerID, PhotoDate,ValidityFrom, ValidityTo, AuditUserID)
	SELECT PhotoID,P.InsureeID, CHFID, PhotoFolder, PhotoFileName, OfficerID, PhotoDate,ValidityFrom, ValidityTo,@AuditUser 
	FROM @xtPhotos P --INNER JOIN (SELECT Ins.InsureeID FROM @xtInsuree Ins WHERE ValidityTo IS NULL) Ins ON Ins.InsureeID  = P.InsureeID 
	WHERE [PhotoID] NOT IN (SELECT PhotoID FROM tblPhotos )
	--AND InsureeID IN (SELECT InsureeID FROM @xtInsuree WHERE FamilyID IN (SELECT FamilyID FROM tblFamilies))
	
	
	SET @PhotoIns = @@ROWCOUNT
	SET IDENTITY_INSERT [tblPhotos] OFF
	SET NOCOUNT ON
	--**E Photos
	
	--**S insurees**
	SET NOCOUNT OFF
	UPDATE Src SET Src.FamilyID = Etr.FamilyID  ,Src.CHFID = Etr.CHFID ,Src.LastName = Etr.LastName ,Src.OtherNames = Etr.OtherNames ,Src.DOB = Etr.DOB ,Src.Gender = Etr.Gender ,Src.Marital = Etr.Marital ,Src.IsHead = Etr.IsHead ,Src.passport = Etr.passport ,src.Phone = Etr.Phone ,Src.PhotoID = Etr.PhotoID  ,Src.PhotoDate = Etr.PhotoDate ,Src.CardIssued = Etr.CardIssued ,Src.ValidityFrom = Etr.ValidityFrom , Src.ValidityTo = Etr.ValidityTo , Src.LegacyID = Etr.LegacyID, Src.AuditUserID = @AuditUser,Src.Relationship = Etr.Relationship, Src.Profession = Etr.Profession,Src.Education = Etr.Education,Src.Email = Etr.Email , 
	Src.TypeOfId = Etr.TypeOfId, Src.HFID = Etr.HFID, Src.CurrentAddress = Etr.CurrentAddress, Src.GeoLocation = Etr.GeoLocation, Src.Vulnerability = Etr.Vulnerability
	FROM tblInsuree Src , @xtInsuree Etr WHERE Src.InsureeID = Etr.InsureeID 
	SET @InsureeUpd = @@ROWCOUNT
	SET NOCOUNT ON
	
	SET NOCOUNT OFF;
	SET IDENTITY_INSERT [tblInsuree] ON
	
	INSERT INTO tblInsuree ([InsureeID],[FamilyID] ,[CHFID],[LastName],[OtherNames],[DOB],[Gender],[Marital],[IsHead],[passport],[Phone],[PhotoID],[PhotoDate],[CardIssued],[ValidityFrom],[ValidityTo],[LegacyID],[AuditUserID],Relationship,Profession,Education,Email,TypeOfId,HFID, CurrentAddress, GeoLocation, CurrentVillage, Vulnerability)
	SELECT [InsureeID],[FamilyID] ,[CHFID],[LastName],[OtherNames],[DOB],[Gender],[Marital],[IsHead],[passport],[Phone],[PhotoID] ,[PhotoDate],[CardIssued],[ValidityFrom],[ValidityTo],[LegacyID],@AuditUser,Relationship,Profession,Education,Email,TypeOfId,HFID, CurrentAddress, GeoLocation,CurrentVillage, Vulnerability
	FROM @xtInsuree WHERE [InsureeID] NOT IN 
	(SELECT InsureeID FROM tblInsuree)
	AND FamilyID IN (SELECT FamilyID FROM tblFamilies)
	
	SET @InsureeIns = @@ROWCOUNT
	SET IDENTITY_INSERT [tblInsuree] OFF
	SET NOCOUNT ON
	--**E Insurees**
	
	
	--**S Policies**
	SET NOCOUNT OFF
	UPDATE Src SET Src.FamilyID = Etr.FamilyID ,Src.EnrollDate = Etr.EnrollDate ,Src.StartDate = Etr.StartDate ,Src.EffectiveDate = Etr.EffectiveDate ,Src.ExpiryDate = Etr.ExpiryDate ,Src.PolicyStatus = Etr.PolicyStatus ,Src.PolicyValue = Etr.PolicyValue ,Src.ProdID = Etr.ProdID ,Src.OfficerID = Etr.OfficerID,Src.PolicyStage = Etr.PolicyStage , Src.ValidityFrom = Etr.ValidityFrom , Src.ValidityTo = Etr.ValidityTo , Src.LegacyID = Etr.LegacyID, Src.AuditUserID = @AuditUser  FROM tblPolicy Src , @xtPolicy Etr WHERE Src.PolicyID = Etr.PolicyID 
	SET @PolicyUpd = @@ROWCOUNT
	SET NOCOUNT ON
	
	SET NOCOUNT OFF;
	SET IDENTITY_INSERT [tblPolicy] ON
	
	INSERT INTO tblPolicy ([PolicyID],[FamilyID],[EnrollDate],[StartDate],[EffectiveDate],[ExpiryDate],[PolicyStatus],[PolicyValue],[ProdID],[OfficerID],[PolicyStage],[ValidityFrom],[ValidityTo],[LegacyID],[AuditUserID])
	SELECT [PolicyID],[FamilyID],[EnrollDate],[StartDate],[EffectiveDate],[ExpiryDate],[PolicyStatus],[PolicyValue],[ProdID],[OfficerID],[PolicyStage],[ValidityFrom],[ValidityTo],[LegacyID],@AuditUser FROM @xtPolicy WHERE [PolicyID] NOT IN
	(SELECT PolicyID FROM tblPolicy)
	AND FamilyID IN (SELECT FamilyID FROM tblFamilies)
	
	SET @PolicyIns  = @@ROWCOUNT
	SET IDENTITY_INSERT [tblPolicy] OFF
	SET NOCOUNT ON
	--**E Policies	
	
	--**S Premium**
	SET NOCOUNT OFF
	UPDATE Src SET Src.PolicyID = Etr.PolicyID ,Src.PayerID = Etr.PayerID , Src.Amount = Etr.Amount , Src.Receipt = Etr.Receipt ,Src.PayDate = Etr.PayDate ,Src.PayType = Etr.PayType , Src.ValidityFrom = Etr.ValidityFrom , Src.ValidityTo = Etr.ValidityTo , Src.LegacyID = Etr.LegacyID, Src.AuditUserID = @AuditUser, Src.isPhotoFee = Etr.isPhotoFee,Src.ReportingId = Etr.ReportingId  FROM tblPremium Src , @xtPremium Etr WHERE Src.PremiumId = Etr.PremiumId 
	SET @PremiumUpd = @@ROWCOUNT
	SET NOCOUNT ON
	
	SET NOCOUNT OFF;
	SET IDENTITY_INSERT [tblPremium] ON
	
	INSERT INTO tblPremium (PremiumId, PolicyID, PayerID, Amount, Receipt,PayDate,PayType,ValidityFrom, ValidityTo, LegacyID, AuditUserID, isPhotoFee,ReportingId) 
	SELECT PremiumId, PolicyID, PayerID, Amount, Receipt,PayDate,PayType,ValidityFrom, ValidityTo, LegacyID, @AuditUser, isPhotoFee,ReportingId FROM @xtPremium WHERE PremiumId NOT IN 
	(SELECT PremiumId FROM tblPremium)
	AND PolicyID IN (SELECT PolicyID FROM tblPolicy)
	
	SET @PremiumIns = @@ROWCOUNT
	SET IDENTITY_INSERT [tblPremium] OFF
	SET NOCOUNT ON
	--**E Premium
	
	
	--**S InsureePolicy**
	SET NOCOUNT OFF
	UPDATE Src SET Src.InsureeId = Etr.InsureeId, Src.PolicyId = Etr.PolicyId, Src.EnrollmentDate = Etr.EnrollmentDate, Src.StartDate = Etr.StartDate, Src.EffectiveDate = Etr.EffectiveDate, Src.ExpiryDate = Etr.ExpiryDate, Src.ValidityFrom = Etr.ValidityFrom, Src.ValidityTo = Etr.ValidityTo, Src.LegacyId = Etr.LegacyId , Src.AuditUserID = @AuditUser  FROM tblInsureePolicy  Src , @xtInsureePolicy  Etr WHERE Src.InsureePolicyId  = Etr.InsureePolicyId AND Etr.PolicyId IN (Select PolicyID FROM tblPolicy) 
	SET NOCOUNT ON
	
	SET NOCOUNT OFF;
	SET IDENTITY_INSERT [tblInsureePolicy] ON
	
	INSERT INTO tblInsureePolicy (InsureePolicyId, InsureeId, PolicyId,EnrollmentDate,StartDate,EffectiveDate,ExpiryDate,ValidityFrom,ValidityTo,LegacyId,AuditUserId)
	SELECT InsureePolicyId, InsureeId, PolicyId,EnrollmentDate,StartDate,EffectiveDate,ExpiryDate,ValidityFrom,ValidityTo,LegacyId,@AuditUser FROM @xtInsureePolicy  WHERE InsureePolicyId NOT IN
	(SELECT InsureePolicyId FROM tblInsureePolicy) AND PolicyId IN (Select PolicyID FROM tblPolicy) 
	
	SET IDENTITY_INSERT [tblInsureePolicy] OFF
	SET NOCOUNT ON
	--**E InsureePolicy	
END TRY
BEGIN CATCH
	SELECT ERROR_MESSAGE();
END CATCH			
END

GO

ALTER PROCEDURE [dbo].[uspExportOffLineExtract5]
@RegionId INT = 0,
	 @DistrictId INT = 0,
	 @RowID as bigint = 0,
	 
	--updated by Amani 22/09/2017
	@WithInsuree as bit = 0
AS
BEGIN
	SET NOCOUNT ON
	
	
	--**Insurees**
	--SELECT [dbo].[tblInsuree].[InsureeID],[dbo].[tblInsuree].[FamilyID] ,[CHFID],[LastName],[OtherNames],[DOB],[Gender],[Marital],[IsHead],[passport],[Phone],[PhotoID],[PhotoDate],[CardIssued],[dbo].[tblInsuree].[ValidityFrom],[dbo].[tblInsuree].[ValidityTo],[dbo].[tblInsuree].[LegacyID],[dbo].[tblInsuree].[AuditUserID],[Relationship],[Profession],[Education],[Email],TypeOfId,HFId FROM [dbo].[tblInsuree] INNER JOIN tblFamilies ON tblFamilies.FamilyID = tblInsuree.FamilyID WHERE tblInsuree.RowID > @RowID AND (CASE @LocationId  WHEN 0 THEN 0 ELSE [DistrictID]  END) = @LocationId
	;WITH Insurees AS (
	SELECT [dbo].[tblInsuree].[InsureeID],[dbo].[tblInsuree].[FamilyID] ,[CHFID],[LastName],[OtherNames],[DOB],[Gender],[Marital],[IsHead],[passport],[Phone],[PhotoID],[PhotoDate],[CardIssued],[dbo].[tblInsuree].[ValidityFrom],[dbo].[tblInsuree].[ValidityTo],[dbo].[tblInsuree].[LegacyID],[dbo].[tblInsuree].[AuditUserID],[Relationship],[Profession],[Education],[Email],[dbo].[tblInsuree].isOffline,TypeOfId,HFId, CurrentAddress, tblInsuree.CurrentVillage, GeoLocation, Vulnerability
	FROM [dbo].[tblInsuree] INNER JOIN tblFamilies ON tblFamilies.FamilyID = tblInsuree.FamilyID 
	INNER JOIN tblVillages V ON V.VillageID = tblFamilies.LocationId
	INNER JOIN tblWards W ON W.WardId = V.WardId
	INNER JOIN tblDistricts D ON D.DistrictId = W.DistrictId
	WHERE tblInsuree.RowID > @RowID 
	--AND ((CASE @DistrictId  WHEN 0 THEN 0 ELSE D.[DistrictID]  END) = @DistrictId OR D.Region = @RegionId) Commented by Rogers
	AND ((CASE @DistrictId  WHEN 0 THEN 0 ELSE D.[DistrictID]  END) = @DistrictId OR @DistrictId =0)  --added by Rogers 0n 10.11.2017
	AND ((CASE @DistrictId  WHEN 0 THEN  D.Region  ELSE @RegionId END) = @RegionId OR @RegionId =0)
	AND[tblInsuree].[InsureeID] =  CASE WHEN	@WithInsuree=0 THEN NULL ELSE [tblInsuree].[InsureeID] END
	--Amani 22/09/2017 change to this------>AND[tblInsuree].[InsureeID] =  CASE WHEN	@WithInsuree=0 THEN NULL END
	UNION ALL
 	SELECT I.[InsureeID],I.[FamilyID] ,[CHFID],[LastName],[OtherNames],[DOB],[Gender],[Marital],[IsHead],[passport],I.[Phone],[PhotoID],[PhotoDate],[CardIssued],I.[ValidityFrom],I.[ValidityTo],I.[LegacyID],I.[AuditUserID],[Relationship],[Profession],[Education],I.[Email],I.isOffline,TypeOfId,I.HFId, CurrentAddress, I.CurrentVillage, GeoLocation, Vulnerability
	FROM tblFamilies F INNER JOIN tblInsuree I ON F.FamilyId = I.FamilyID
	INNER JOIN tblHF HF ON I.HFId = HF.HfID
	WHERE I.RowID > @RowID 
	AND (CASE @DistrictId  WHEN 0 THEN 0 ELSE HF.[LocationId]  END) = @DistrictId
	AND I.[InsureeID] =  CASE WHEN	@WithInsuree=0 THEN NULL ELSE I.[InsureeID] END
	)
	SELECT * FROM Insurees I
	GROUP BY I.[InsureeID],I.[FamilyID] ,[CHFID],[LastName],[OtherNames],[DOB],[Gender],[Marital],[IsHead],[passport],[Phone],[PhotoID],[PhotoDate],[CardIssued],I.[ValidityFrom],I.[ValidityTo],I.[LegacyID],I.[AuditUserID],[Relationship],[Profession],[Education],[Email],I.isOffline,TypeOfId,HFId, CurrentAddress, I.CurrentVillage, GeoLocation, Vulnerability

END
GO

ALTER PROCEDURE [dbo].[uspCreateEnrolmentXML]
(
	@FamilyExported INT = 0 OUTPUT,
	@InsureeExported INT = 0 OUTPUT,
	@PolicyExported INT = 0 OUTPUT,
	@PremiumExported INT = 0 OUTPUT
)
AS
BEGIN
	SELECT
	(SELECT * FROM (SELECT F.FamilyId,F.InsureeId, I.CHFID , F.LocationId, F.Poverty FROM tblInsuree I 
	INNER JOIN tblFamilies F ON F.FamilyID=I.FamilyID
	WHERE F.FamilyID IN (SELECT FamilyID FROM tblInsuree WHERE isOffline=1 AND ValidityTo IS NULL GROUP BY FamilyID) 
	AND I.IsHead=1 AND F.ValidityTo IS NULL
	UNION
SELECT F.FamilyId,F.InsureeId, I.CHFID , F.LocationId, F.Poverty
	FROM tblFamilies F 
	LEFT OUTER JOIN tblInsuree I ON F.insureeID = I.InsureeID AND I.ValidityTo IS NULL
	LEFT OUTER JOIN tblPolicy PL ON F.FamilyId = PL.FamilyID AND PL.ValidityTo IS NULL
	LEFT OUTER JOIN tblPremium PR ON PR.PolicyID = PL.PolicyID AND PR.ValidityTo IS NULL
	WHERE F.ValidityTo IS NULL 
	AND (F.isOffline = 1 OR I.isOffline = 1 OR PL.isOffline = 1 OR PR.isOffline = 1)	
	GROUP BY F.FamilyId,F.InsureeId,F.LocationId,F.Poverty,I.CHFID) aaa	
	FOR XML PATH('Family'),ROOT('Families'),TYPE),
	
	(SELECT * FROM (
	SELECT I.InsureeID,I.FamilyID,I.CHFID,I.LastName,I.OtherNames,I.DOB,I.Gender,I.Marital,I.IsHead,I.passport,I.Phone,I.CardIssued,NULL EffectiveDate, I.Vulnerability
	FROM tblInsuree I
	LEFT OUTER JOIN tblInsureePolicy IP ON IP.InsureeId=I.InsureeID
	WHERE I.ValidityTo IS NULL AND I.isOffline = 1
	AND IP.ValidityTo IS NULL 
	GROUP BY I.InsureeID,I.FamilyID,I.CHFID,I.LastName,I.OtherNames,I.DOB,I.Gender,I.Marital,I.IsHead,I.passport,I.Phone,I.CardIssued, I.Vulnerability
	)xx
	FOR XML PATH('Insuree'),ROOT('Insurees'),TYPE),

	(SELECT P.PolicyID,P.FamilyID,P.EnrollDate,P.StartDate,P.EffectiveDate,P.ExpiryDate,P.PolicyStatus,P.PolicyValue,P.ProdID,P.OfficerID, P.PolicyStage
	FROM tblPolicy P 
	LEFT OUTER JOIN tblPremium PR ON P.PolicyID = PR.PolicyID
	INNER JOIN tblFamilies F ON P.FamilyId = F.FamilyID
	WHERE P.ValidityTo IS NULL 
	AND PR.ValidityTo IS NULL
	AND F.ValidityTo IS NULL
	AND (P.isOffline = 1 OR PR.isOffline = 1)
	FOR XML PATH('Policy'),ROOT('Policies'),TYPE),
	(SELECT Pr.PremiumId,Pr.PolicyID,Pr.PayerID,Pr.Amount,Pr.Receipt,Pr.PayDate,Pr.PayType
	FROM tblPremium Pr INNER JOIN tblPolicy PL ON Pr.PolicyID = PL.PolicyID
	INNER JOIN tblFamilies F ON F.FamilyId = PL.FamilyID
	WHERE Pr.ValidityTo IS NULL 
	AND PL.ValidityTo IS NULL
	AND F.ValidityTo IS NULL
	AND Pr.isOffline = 1
	FOR XML PATH('Premium'),ROOT('Premiums'),TYPE)
	FOR XML PATH(''), ROOT('Enrolment')
	
	
	SELECT @FamilyExported = ISNULL(COUNT(*),0)	FROM tblFamilies F 	WHERE ValidityTo IS NULL AND isOffline = 1
	SELECT @InsureeExported = ISNULL(COUNT(*),0) FROM tblInsuree I WHERE I.ValidityTo IS NULL AND I.isOffline = 1
	SELECT @PolicyExported = ISNULL(COUNT(*),0)	FROM tblPolicy P WHERE ValidityTo IS NULL AND isOffline = 1
	SELECT @PremiumExported = ISNULL(COUNT(*),0)	FROM tblPremium Pr WHERE ValidityTo IS NULL AND isOffline = 1
END


GO
