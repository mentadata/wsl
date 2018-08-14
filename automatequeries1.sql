SELECT DISTINCT
       o.name AS Object_Name,
       o.type_desc
  FROM sys.sql_modules m
       INNER JOIN
       sys.objects o
         ON m.object_id = o.object_id
 WHERE m.definition Like '%\[spWSInsertPurchaseOrderSummary]%' ESCAPE '\'

 SELECT DISTINCT
       o.name AS Object_Name,
       o.type_desc
  FROM sys.sql_modules m
       INNER JOIN
       sys.objects o
         ON m.object_id = o.object_id
 WHERE m.definition Like '%LAST30%' ESCAPE '\'

 use posdb
 go


 SELECT 1 FROM ItemInfo WHERE VendPartNumber = '04825'

  

 SELECT 1 FROM ItemInfo WHERE VendPartNumber = 'C04825'

 select * from PurchaseOrderDetail where VPN = 'C04825' 
 order by PONumber desc

 select distinct ZeroCostTotalAmount from PurchaseOrderDetail where QtyOrder > 0 
 order by PONumber desc

 select * from PurchaseOrderDetail order by PONumber desc

 select * from PurchaseOrdersummary order by PONumber desc

 select ItemID,
		ItemScanID,
		'ITEM',
		ItemName,
		VendPartNumber,
		ISize,
		AmntInCase,
		'CaseOrder' = 'get from invoice',
		'CaseCost' = 'get from invoice',
		'QtyOrder' = 'get from invoice - null if case order is not null',
		'TotalUnit' = 'get from invoice',
		'TotalCost' = 'get from invoice',
		'CostPerUnit' = 'get from invoice',
		'OUnitCost' = 'same as CostPerUnit',
		'SoldLast30' = 'calculated',
		'SoldLast60' = 'calculated',
		'SoldLast90' = 'calculated',
		'LastCost1' = 'calculated',
		'LastCost2' = 'calculated',
		'LastCost3' = 'calculated',
		 'Status' = 'RCVDIR',
		 'ZeroCostTotalAmount' = 'need to check',
		 'ZeroCStatus' = 'need to check'
		   

from    ItemInfo
where VendPartNumber = 'C04825'

select ItemID,
                            ItemScanID,
                            'ITEM' as itemoring,
                            ItemName,
                            VendPartNumber,
                            ISize,
                            AmntInCase
            from    ItemInfo
            where VendPartNumber = 'C04825'

select VendPartNumber,count(1) as c
from ItemInfo
group by VendPartNumber
order by c desc

select * from ItemInfo
where VendPartNumber = 'BDC9254144'


SELECT * FROM sys.objects 
      WHERE type='P' AND name like '%xx_spWSInsertVPNInfo%'

select * into xx_PurchaseOrderDetail_tbl_3 from xx_PurchaseOrderDetail_tbl_2 where 1=2
           

select * from xx_PurchaseOrderDetail_tbl

INSERT INTO xx_PurchaseOrderDetail_tbl (PONumber, InvoiceNumber, SLNo, ItemID, 
			ScanCode, ItemOrIng, ItemIngName, VPN, ISize, AInCase)
	VALUES (123, 23456, 1, 234, 'asdf', 'i', 
			'j', '686', 2, 2)

select * into xx_PurchaseOrderSummary_tbl from PurchaseOrderSummary where 1=2

select NoOfItems,TotalAmnt
	from PurchaseOrderSummary
	where InvoiceNumber = 'AUT-6611912018-08-10'

	select PONumber,sum(TotalCost) totalcost,count(1) no_of_items
	from PurchaseOrderDetail
	where InvoiceNumber = 'AUT-6611912018-08-10 14:05:32'
	group by PONumber

use POSDB
go

execute xx_spWSInsertPOSummary 'AUT-6611912018-08-10 14:05:32'


select * from iteminfo where VendPartNumber = 'C01906'

select * from PurchaseOrderSummary order by rcvdate desc

select * from PurchaseOrderDetail order by PONumber desc

select * from PurchaseOrderSummary order by rcvdate desc

select * from xx_PurchaseOrderSummary_tbl

select * from xx_invoice_entry_exceptions

select * from xx_receiveditemslog

select * from xx_runningstatus

select * from xx_log_file_processed_tbl

delete from PurchaseOrderDetail where PONumber = 1122

delete from PurchaseOrderSummary where PONumber = 1123

delete from xx_invoice_entry_exceptions

delete from xx_receiveditemslog

delete from xx_runningstatus

delete from xx_log_file_processed_tbl

select * from ItemPriceDetails order by TTime desc

select sts,rcvd_count from xx_runningstatus

insert into xx_runningstatus (sts,rcvd_count) values (0,0)

create table dbo.xx_runningstatus (sts int,rcvd_count int)




create table dbo.xx_invoice_entry_exceptions
(
invoice_number varchar(20),
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
ppc int,
scancode varchar(25),
date_inserted datetime
)

drop table dbo.xx_receiveditemslog

create table dbo.xx_receiveditemslog
(
vpn varchar(20),
invoice_number varchar(40),
qty_received money,
date_received datetime)

drop table xx_log_file_processed_tbl

create table dbo.xx_log_file_processed_tbl 
(inputfile varchar(50),
 invoice_number varchar(30),
 itemseligible int,
 rcvd_count int,
 totalamt money,
 dateprocessed datetime)

execute xx_spWSInsertVPNInfo 'C04825','661191',1,1122,0,2,27.70,55.40,27.70

execute xx_spWSInsertPOSummary '661191'

select * from
(SELECT top 3 ROW_NUMBER,CostPerUnit
 FROM PurchaseOrderDetail
where vpn = 'C04825'
order by PONumber desc) as st

PIVOT
(
max(CostPerUnit )
FOR vpn IN ([0],[1],[2])

) as pivottable



SELECT top 3 ROW_NUMBER() over (partition by vpn order by ponumber desc) rn ,
       CostPerUnit
 FROM PurchaseOrderDetail
where vpn = 'C04825'
order by PONumber desc


select b.time,b.TransDateEnd,convert(DATE,b.time) as mytime2,b.Qty,b.ItemID
FROM 	[POSDB].[dbo].PermItemTran b,
        [POSDB].[dbo].[ItemInfo] item 
WHERE b.ItemID = item.ItemID
AND   item.VendPartNumber = 'C17131'
--AND b.Status = 'ORDER'   
AND convert(DATE,b.time) between dateadd(month,-1,GETDATE()) + 1 and GETDATE()
order by time
--AND SUM(b.StdPrice * b.Qty  - b.Discount) > 0 --Sales > 0 	





--SOLD LAST 30
select sum(b.qty)
FROM 	[POSDB].[dbo].PermItemTran b,
        [POSDB].[dbo].[ItemInfo] item 
WHERE b.ItemID = item.ItemID
AND   item.VendPartNumber = 'C17131'
--AND b.Status = 'ORDER'   
AND convert(DATE,b.time) between dateadd(month,-1,GETDATE()) + 1 and GETDATE() 

SELECT convert(DATEADD(month, -1, GETDATE()),GETDATE());

selk

--SOLD LAST 60
select sum(b.qty)
FROM 	[POSDB].[dbo].PermItemTran b,
        [POSDB].[dbo].[ItemInfo] item 
WHERE b.ItemID = item.ItemID
AND   item.VendPartNumber = 'C17131'
--AND b.Status = 'ORDER'   
AND CONVERT(VARCHAR(10) , b.time,10 ) between '05-26-18' and '07-25-18' 



declare

@todaydate date;

begin

set @todaydate = dateadd(month,-1,GETDATE()) + 1
print @todaydate

end


DECLARE @GUID uniqueidentifier
SET @GUID = NEWID()
print @GUID