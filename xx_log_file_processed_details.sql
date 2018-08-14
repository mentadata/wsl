SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

USE POSDB
GO

-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.ROUTINES 
           WHERE ROUTINE_NAME = 'xx_log_file_processed_details' 
             AND ROUTINE_SCHEMA = 'dbo' 
             AND ROUTINE_TYPE = 'PROCEDURE')
  DROP PROCEDURE dbo.xx_log_file_processed_details
GO

CREATE PROCEDURE xx_log_file_processed_details 
	-- Add the parameters for the stored procedure here
	@file_name varchar(50),
	@InvoiceNumber varchar(30),
	@rcvd_count int

AS
DECLARE

@dateprocessed datetime,
@NoOfItems int,
@TotalAmnt money

BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	DECLARE file_log_cur CURSOR FOR
	select NoOfItems,TotalAmnt
	from PurchaseOrderSummary
	where InvoiceNumber = @InvoiceNumber

	OPEN file_log_cur
	FETCH NEXT FROM file_log_cur INTO @NoOfItems,@TotalAmnt
	CLOSE file_log_cur

	SET @dateprocessed = GETDATE()
	

    -- Insert statements for procedure here
	INSERT INTO xx_log_file_processed_tbl (inputfile,invoice_number,itemseligible,rcvd_count,totalamt,dateprocessed)
	VALUES (@file_name,@InvoiceNumber,@NoOfItems,@rcvd_count,@TotalAmnt,@dateprocessed)

	DEALLOCATE file_log_cur
END
GO
