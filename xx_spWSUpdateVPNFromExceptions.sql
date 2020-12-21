-- ================================================
-- Template generated from Template Explorer using:
-- Create Procedure (New Menu).SQL
--
-- Use the Specify Values for Template Parameters 
-- command (Ctrl-Shift-M) to fill in the parameter 
-- values below.
--
-- This block of comments will not be included in
-- the definition of the procedure.
-- ================================================
-- =============================================

-- =============================================
USE [POSDB]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.ROUTINES 
           WHERE ROUTINE_NAME = 'xx_spWSUpdateVPNFromExceptions' 
             AND ROUTINE_SCHEMA = 'dbo' 
             AND ROUTINE_TYPE = 'PROCEDURE')
  DROP PROCEDURE dbo.xx_spWSUpdateVPNFromExceptions
GO

CREATE PROCEDURE [dbo].[xx_spWSUpdateVPNFromExceptions]
	-- Add the parameters for the stored procedure here
	@vpn VARCHAR(30),
	@scanid varchar(35)

AS

DECLARE

@ItemID INT,
@ScanCode VARCHAR(20),
@ItemOrIng VARCHAR(15),
@ItemName VARCHAR(60),
@ISize VARCHAR(20),
@AInCase MONEY,
@TotalUnit MONEY,
@CostPerUnit MONEY,
@OUnitCost MONEY,
@SoldLast30 MONEY,
@SoldLast60 MONEY,
@SoldLast90 MONEY,
@LastCost1 MONEY,
@LastCost2 MONEY,
@LastCost3 MONEY,
@Status varchar(30),
@UnqID varchar(80),
@rn INT,
@LastCost MONEY,
@GUID uniqueidentifier,
@ZeroCostTotalAmount MONEY, 
@ZeroCStatus varchar(30)


BEGIN

    SET NOCOUNT ON;
    
    UPDATE ItemInfo
    SET    vendpartnumber = @vpn
    WHERE  ItemScanID = @scanid
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	


END
