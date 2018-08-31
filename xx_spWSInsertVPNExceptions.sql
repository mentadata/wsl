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
           WHERE ROUTINE_NAME = 'xx_spWSInsertVPNExceptions' 
             AND ROUTINE_SCHEMA = 'dbo' 
             AND ROUTINE_TYPE = 'PROCEDURE')
  DROP PROCEDURE dbo.xx_spWSInsertVPNExceptions
GO

CREATE PROCEDURE [dbo].[xx_spWSInsertVPNExceptions]  
	-- Add the parameters for the stored procedure here
	@invoice_number		varchar(20),
	@vendor				varchar(100),
	@invoice_date		datetime,
	@invoice_amount		money,
	@invoice_item_count	int,
	@vpn				varchar(20),
	@item_description	varchar(200),
	@quantity			int,
	@unit_cost			money,
	@unit_of_measure	varchar(5),
	@etended_price		money,
	@ppc				varchar(25),
	@scancode			varchar(25)
	
AS

DECLARE


@GUID uniqueidentifier,
@date_inserted		datetime

BEGIN


	
	SET @date_inserted = GETDATE()
	
	
	INSERT INTO xx_invoice_entry_exceptions (invoice_number, vendor, invoice_date, invoice_amount, 
			invoice_item_count, vpn, item_description,quantity, unit_cost, unit_of_measure, etended_price,ppc,scancode,date_inserted
			)
	VALUES (@invoice_number, @vendor, @invoice_date, @invoice_amount, 
			@invoice_item_count, @vpn, @item_description,@quantity, @unit_cost, @unit_of_measure, @etended_price,@ppc,@scancode,@date_inserted)


    
END
