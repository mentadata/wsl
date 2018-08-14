	SELECT ItemID, ScanCode, ItemOrIng, ItemIngName, VPN, AInCase, CaseOrder, CaseCost, QtyOrder,
	TotalUnit, TotalCost, OUnitCost, CostPerUnit
	FROM xx_PurchaseOrderDetail_tbl 
	WHERE UPPER(InvoiceNumber) = UPPER('AUT-6611912018-08-03 00:06:38')
	AND Status in('RCV', 'RCVDIR', 'RCV-MOD', 'RCVDIR-MOD')

	use posdb
	go


	execute xx_spWSPurchaseOrderReceive 661191

	execute xx_log_file_processed_details 'asdf', '661191', 50

	select * from xx_PurchaseOrderDetail_tbl where vpn = 'C00031'

select VendPartNumber,QtyOnHand from xx_iteminfo where VendPartNumber = 'C00031'
	
select VendPartNumber,QtyOnHand from iteminfo where VendPartNumber = 'C00031'

create table dbo.xx_runningstatus (sts int,rcvd_count int)

drop table xx_runningstatus

select * from xx_receiveditemslog

delete from xx_receiveditemslog

drop table ItemInfo

select * into xx_iteminfo from ItemInfo

select * into iteminfo from xx_ItemInfo


     

update xx_runningstatus set sts = 1

insert into xx_runningstatus (sts,rcvd_count) values (0,0)

select * from xx_runningstatus

use POSDB
go



select b.vendPartNumber,b.qtyonhand before_qty,c.CaseOrder,c.AInCase,a.QtyOnHand after_qty, a.QtyOnHand - (b.qtyonhand + (c.CaseOrder * c.AInCase)) diff
from xx_iteminfo b,
     iteminfo a,
	 PurchaseOrderDetail c
where a.VendPartNumber = b.VendPartNumber
and c.VPN = b.VendPartNumber
and c.InvoiceNumber = 'AUT-6611912018-08-10 19:35:18'


use posdb
go

