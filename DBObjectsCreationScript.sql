--Script to create TABLES

select * into xx_PurchaseOrderDetail_tbl from PurchaseOrderDetail where 1=2

select * into xx_PurchaseOrderSummary_tbl from PurchaseOrderSummary where 1=2

create table POSDB.dbo.xx_invoice_entry_exceptions
(
invoice_number varchar(35),
vendor	varchar(100),
invoice_date datetime,
invoice_amount	money,
invoice_item_count	int,
vpn	varchar(20),
item_description varchar(200),
quantity int,
unit_cost money,
unit_of_measure varchar(5),
etended_price money,
ppc varchar(25),
scancode varchar(25),
date_inserted datetime
)

create table dbo.xx_runningstatus (sts int,rcvd_count int)

insert into xx_runningstatus (sts,rcvd_count) values (0,0)

create table dbo.xx_receiveditemslog
(
vpn varchar(20),
invoice_number varchar(40),
qty_received money,
date_received datetime)

create table dbo.xx_log_file_processed_tbl 
(inputfile varchar(50),
 invoice_number varchar(35),
 itemseligible int,
 rcvd_count int,
 totalamt money,
 dateprocessed datetime,
 posummary_count int)

 CREATE TABLE [dbo].[xx_items_matching_source](
	[filename] [varchar](75) NULL,
	[invoice_number] [varchar](50) NULL,
	[vpn] [varchar](40) NULL,
	[fintech_description] [varchar](150) NULL,
	[pos_description] [varchar](150) NULL,
	[caseupc] [varchar](30) NULL,
	[packupc] [varchar](30) NULL,
	[final_upc] [varchar](30) NULL,
	[glcode] [varchar](20) NULL,
	[source] [varchar](20) NULL,
	[date_inserted] [datetime] NULL
)

--**************** PROCEDURES ****************

C:\Anil\Projects\wsl\InvoiceAutomation\xx_spWSInsertVPNInfo.sql

C:\Anil\Projects\wsl\InvoiceAutomation\xx_spWSInsertPOSummary.sql

C:\Anil\Projects\wsl\InvoiceAutomation\xx_spWSInsertVPNExceptions.sql

C:\Anil\Projects\wsl\InvoiceAutomation\xx_log_file_processed_details.sql

C:\Anil\Projects\wsl\InvoiceAutomation\purchaseOrderreceive.sql

C:\Anil\Projects\wsl\InvoiceAutomation\xx_spWSUpdateVPNFromExceptions.sql


--Temporary one time to fix data in rox store

BEGIN TRANSACTION;
update dbo.ItemInfo set AmntInCase = 6 where VendPartNumber = '9018347'
COMMIT TRANSACTION;

--9317840
--9111378
--9151529
--9018347


