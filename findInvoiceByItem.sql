 use posdb
 go

 select * from PurchaseOrderDetail
 where ItemIngName like '%SMIRNOFF%BLUEBERR'
 order by PONumber
 desc


 select rcvd.date_received,po.* 
 from PurchaseOrderDetail po,
      xx_receiveditemslog rcvd
 where po.VPN = rcvd.vpn
 and po.InvoiceNumber = rcvd.invoice_number
 and po.ItemIngName like '%APOTHIC%'
 order by rcvd.date_received
 desc

 select VendPartNumber,ItemName,StdPrice from iteminfo where VendPartNumber = 'BDC9031866' 

 select VendPartNumber,ItemName,StdPrice from iteminfo where ItemName like '%SMIRNOFF%BLUEBERR'

 select * from xx_receiveditemslog where invoice_number = 'AUT-329570265'


 select * from xx_invoice_entry_exceptions 
 where item_description like '%SMIRNOFF%BLUEBERR%'