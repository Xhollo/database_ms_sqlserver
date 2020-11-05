IF COL_LENGTH(N'tblInsuree', N'Vulnerability') IS NULL
ALTER TABLE tblInsuree
ADD Vulnerability BIT NOT NULL DEFAULT(0)
GO

IF NOT EXISTS(SELECT 1 FROM tblControls WHERE FieldName = N'Vulnerability')
INSERT INTO tblControls(FieldName, Adjustibility, Usage)
VALUES(N'Vulnerability', N'O', N'Insuree')
GO


