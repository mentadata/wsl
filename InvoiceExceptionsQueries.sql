
  

 select VendPartNumber,
       case v.name
	   when 'COORS' then SUBSTRING(VendPartNumber,2,10)
       when  'Anheuser-Busch Sales - Littleton' then SUBSTRING(VendPartNumber,4,15)
       when  'Republic National Dist - CO' then SUBSTRING(VendPartNumber,2,15)
       when  'BEVERAGE DIST' then SUBSTRING(VendPartNumber,4,15)
       when 'ELITE' then SUBSTRING(VendPartNumber,6,20)
       when 'Synergy Fine Wines Dominico Distribution' then SUBSTRING(VendPartNumber,4,20)
       when 'Western Distributing Company, Inc' then SUBSTRING(VendPartNumber,4,20)
	   when 'SOUTHERN WINE' then SUBSTRING(VendPartNumber,3,20)
	   when 'CLASSIC WINES' then SUBSTRING(VendPartNumber,3,20)
      end as vpn1, 
       v.Name
 from ItemInfo i,
      [ItemVendor] v
 where i.VendorID = v.ID
 and  VendPartNumber like '%SW923537%'

select distinct name from [dbo].[ItemVendor]
order by name



select VendPartNumber,replace(VendPartNumber,'*','') d from ItemInfo

--SUBSTRING(VendPartNumber, (PATINDEX('%[A-Z]-[0-9][0-9][0-9][0-9][0-9]%',VendPartNumber)),7)

select VendPartNumber,
	   SUBSTRING(VendPartNumber, (PATINDEX('%[0-9]%',VendPartNumber)),10) s,
	   PATINDEX('%[0-9]%',VendPartNumber) p from ItemInfo
where( VendPartNumber is not null or VendPartNumber <> '')

select *
from xx_invoice_entry_exceptions 
where CONVERT(date, date_inserted) = '2019-02-25'



select SUBSTRING(vpn, (PATINDEX('%[0-9]%',vpn)),10) s,PATINDEX('%[0-9]%',vpn) p
 from xx_invoice_entry_exceptions e,
      ItemInfo i
 where SUBSTRING(VendPartNumber, (PATINDEX('%[0-9]%',VendPartNumber)),10) = SUBSTRING(vpn, (PATINDEX('%[0-9]%',vpn)),10) 
 and   CONVERT(date, date_inserted) = '2019-02-25'
 order by date_inserted desc

 select e.*
 from xx_invoice_entry_exceptions e,
      ItemInfo i
 where e.item_description = i.ItemName
 and   CONVERT(date, date_inserted) = '2019-02-25'
 order by date_inserted desc

 select * from iteminfo