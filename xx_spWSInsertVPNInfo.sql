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
-- Author:		Anil Menta
-- Create date: 7/23/2018
-- Description:	<Description,,>
-- =============================================
USE [POSDB]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.ROUTINES 
           WHERE ROUTINE_NAME = 'xx_spWSInsertVPNInfo' 
             AND ROUTINE_SCHEMA = 'dbo' 
             AND ROUTINE_TYPE = 'PROCEDURE')
  DROP PROCEDURE dbo.xx_spWSInsertVPNInfo
GO

CREATE PROCEDURE [dbo].[xx_spWSInsertVPNInfo]
	-- Add the parameters for the stored procedure here
	@vpn VARCHAR(30),
	@InvoiceNumber varchar(35),
	@SLNo INT,
	@PONumber INT,
	@QtyOrder MONEY,
	@CaseOrder MONEY,
	@CaseCost MONEY,
	@TotalCost MONEY,
	@unitCost MONEY
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


	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    DECLARE vpn_info_CUR CURSOR FOR
	SELECT ItemID,
            ItemScanID,
            'ITEM' as itemoring,
            ItemName,
            VendPartNumber,
            AmntInCase,
			ISize
     FROM    ItemInfo
     WHERE VendPartNumber = @vpn

	 DECLARE soldlast30_cur CURSOR FOR
	 --SOLD LAST 30
		select sum(b.qty)
		FROM 	[POSDB].[dbo].PermItemTran b,
				[POSDB].[dbo].[ItemInfo] item 
		WHERE b.ItemID = item.ItemID
		AND   item.VendPartNumber = @vpn
		--AND b.Status = 'ORDER'   
		AND convert(DATE,b.time) between dateadd(month,-1,GETDATE()) + 1 and GETDATE()

	 DECLARE soldlast60_cur CURSOR FOR
	 --SOLD LAST 30
		select sum(b.qty)
		FROM 	[POSDB].[dbo].PermItemTran b,
				[POSDB].[dbo].[ItemInfo] item 
		WHERE b.ItemID = item.ItemID
		AND   item.VendPartNumber = @vpn
		--AND b.Status = 'ORDER'   
		AND convert(DATE,b.time) between dateadd(month,-2,GETDATE()) + 1 and GETDATE()
		
	 DECLARE soldlast90_cur CURSOR FOR
	 --SOLD LAST 30
		select sum(b.qty)
		FROM 	[POSDB].[dbo].PermItemTran b,
				[POSDB].[dbo].[ItemInfo] item 
		WHERE b.ItemID = item.ItemID
		AND   item.VendPartNumber = @vpn
		--AND b.Status = 'ORDER'   
		AND convert(DATE,b.time) between dateadd(month,-3,GETDATE()) + 1 and GETDATE()		
		
	DECLARE last_costs_cur CURSOR FOR
	SELECT top 3 ROW_NUMBER() over (partition by vpn order by ponumber desc) rn ,
			CostPerUnit
	FROM PurchaseOrderDetail
	where vpn = @vpn
	order by PONumber desc	

	OPEN vpn_info_CUR
	FETCH NEXT FROM vpn_info_CUR INTO @ItemID, @ScanCode, @ItemOrIng, @ItemName, @VPN, 
	@AInCase,@ISize

	OPEN soldlast30_cur
	FETCH NEXT FROM soldlast30_cur INTO @SoldLast30
	CLOSE soldlast30_cur
	DEALLOCATE soldlast30_cur

	OPEN soldlast60_cur
	FETCH NEXT FROM soldlast60_cur INTO @SoldLast60
	CLOSE soldlast60_cur
	DEALLOCATE soldlast60_cur

	OPEN soldlast90_cur
	FETCH NEXT FROM soldlast90_cur INTO @SoldLast90
	CLOSE soldlast90_cur
	DEALLOCATE soldlast90_cur

	OPEN last_costs_cur
	FETCH NEXT FROM last_costs_cur INTO @rn, @LastCost
	WHILE (@@FETCH_STATUS = 0)
	BEGIN
		IF @rn = 1 
			SET @LastCost1 = @LastCost
		else IF @rn = 2
			SET  @LastCost2 = @LastCost
		else IF @rn = 3
			SET @LastCost3 = @LastCost

		FETCH NEXT FROM last_costs_cur INTO @rn, @LastCost
	END
	CLOSE last_costs_cur
	
	
	IF @CaseOrder > 0
		
	BEGIN
		SET @TotalUnit = @CaseOrder * @AInCase
		--PRINT @TotalUnit
		--PRINT @TotalUnit
		SET @CostPerUnit = (@TotalCost/@TotalUnit)
		--PRINT @CostPerUnit
		SET @OUnitCost = @CostPerUnit
	END

	ELSE

		IF @QtyOrder > 0

		BEGIN
			SET @TotalUnit = @QtyOrder    
			SET @CostPerUnit = @unitCost
			SET @OUnitCost = @CostPerUnit
		END

	
	SET @GUID = NEWID()

	
	
	INSERT INTO PurchaseOrderDetail (PONumber, InvoiceNumber, SLNo, ItemID, 
			ScanCode, ItemOrIng, ItemIngName, VPN, ISize, AInCase,CaseOrder,CaseCost,QtyOrder,TotalUnit, TotalCost, CostPerUnit, OUnitCost,
			SoldLast30, SoldLast60, SoldLast90,LastCost1, LastCost2, LastCost3,Status,UnqID,ZeroCostTotalAmount,ZeroCStatus)
	VALUES (@PONumber, @InvoiceNumber, @SLNo, @ItemID, @ScanCode, @ItemOrIng, 
			@ItemName, @VPN, @ISize, @AInCase,@CaseOrder, @CaseCost,@QtyOrder,@TotalUnit,@TotalCost, @CostPerUnit, @OUnitCost,
			@SoldLast30, @SoldLast60, @SoldLast90,@LastCost1, @LastCost2, @LastCost3,'RCVDIR',@GUID,@ZeroCostTotalAmount,@ZeroCStatus)

    CLOSE vpn_info_CUR
	DEALLOCATE vpn_info_CUR
	DEALLOCATE last_costs_cur
    /*
	INSERT INTO xx_PurchaseOrderDetail_tbl (PONumber, InvoiceNumber, SLNo, ItemID, 
			ScanCode, ItemOrIng, ItemIngName, VPN, ISize, AInCase,CaseOrder,QtyOrder)
	VALUES (@PONumber, @InvoiceNumber, @SLNo, @ItemID, @ScanCode, @ItemOrIng, 
			@ItemName, @VPN, @ISize, @AInCase,@CaseOrder,@QtyOrder)

	--, @CaseOrder, @CaseCost, @QtyOrder, @TotalUnit, @TotalCost, @OUnitCost, @UnitCost
	
	*/
END
