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
USE [POSDB]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Anil Menta
-- Create date: 7/23/2018
-- Description:	<Description,,>
-- =============================================

IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.ROUTINES 
           WHERE ROUTINE_NAME = 'xx_spWSInsertPOSummary' 
             AND ROUTINE_SCHEMA = 'dbo' 
             AND ROUTINE_TYPE = 'PROCEDURE')
  DROP PROCEDURE dbo.xx_spWSInsertPOSummary
GO
CREATE PROCEDURE [dbo].[xx_spWSInsertPOSummary]  
	-- Add the parameters for the stored procedure here
	@InvoiceNumber		varchar(30)
AS

DECLARE


@GUID uniqueidentifier,
@date_inserted		datetime,
@PODate		datetime,
@RcvDate	datetime,
@EmpID		int,
@SalesID	int,
@VendorID	int,
@PONumber	varchar(20),
@TotalAmnt	money,
@NoOfItems	int,
@Notes		varchar(200)


BEGIN

	SET NOCOUNT ON;

	DECLARE po_summ_cur CURSOR FOR
	select PONumber,sum(TotalCost) totalcost,count(1) no_of_items
	from PurchaseOrderDetail
	where InvoiceNumber = @InvoiceNumber
	group by PONumber
	
	SET @date_inserted = GETDATE()
	SET @PODate = GETDATE()
	SET @RcvDate = GETDATE()
	SET @EmpID = 204
	SET @SalesID = 0
	SET @VendorID = 0
	SET @GUID = NEWID()

	OPEN po_summ_cur
	FETCH NEXT FROM po_summ_cur INTO @PONumber,@TotalAmnt,@NoOfItems
	CLOSE po_summ_cur

	
	
			INSERT INTO PurchaseOrderSummary (PONumber, InvoiceNumber, PODate, RcvDate, EmpID, 
			SalesID, NoOfItems, TotalAmnt,Notes, Status, VendorID, LastUpdateDate,UnqId) 
			VALUES(@PONumber, @InvoiceNumber, @PODate, @PODate, @EmpID, @SalesID, 
			@NoOfItems, @TotalAmnt, @Notes, 'RECEIVED', @VendorID,@PODate,@GUID)

	DEALLOCATE po_summ_cur

    
END
