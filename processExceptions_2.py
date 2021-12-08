# -*- coding: utf-8 -*-
"""
Created on Thu Nov 19 19:15:21 2020

@author: YYYP914
"""

import pyodbc
import pandas as pd
import glob
import re
import locale
import sys
import datetime
import shutil
import os
from datetime import datetime


server = 'WHQPC-L31249\SQLEXPRESS'
database = 'POSDB'
username = 'poc'
password = 'Welcome@123'


conn = pyodbc.connect('DRIVER={ODBC Driver 13 for SQL Server};SERVER='+server+';DATABASE='+database+';UID='+username+';PWD='+ password)
cursor = conn.cursor()





def updateVPNonExceptions(df):
    
    df['source'] = '' #placeholder to capture source of exception
    
    fail_df = df[df['vendor'] == 'xx']
    success_df = df[df['vendor'] == 'xx']
    
    
    
    
    for idx,row in df.iterrows():
        
        row['source'] = 'vpnupdate' #Source identification when VPN update is not successful
        
        cur = cursor.execute("SELECT 1 FROM ItemInfo WHERE ItemScanID = ?",row.pos_scancode)
        dbrow = cur.fetchone()
        
        if dbrow is None: #Didn't find the item
            
            
            fail_df = fail_df.append(row)
            print ("{0} does not exist".format(row.pos_scancode))
            
            
        else: #Item found
            
            
            
            try:
                
                print ("{0} EXISTS".format(row.pos_scancode))
                
                s = cursor.execute("{call xx_spWSUpdateVPNFromExceptions (?,?)}",row.vpn,row.pos_scancode)
                
                success_df = success_df.append(row)
                    
            except pyodbc.DatabaseError as dberr:
                    
                
                fail_df = fail_df.append(row)
                
                print ("Database error {0}".format(dberr))
                try:
                    s
                except NameError:
                    
                    print("PO SUMMARY DB Error and cursor does not exist - Good")
                else:
                    
                    s.close()
                    
                sys.exit()
                
            except pyodbc.Error as err:
                
                fail_df = fail_df.append(row)
                
                print ("Database error {0}".format(err))
                try:
                    s
                except NameError:
                    print("General Error and cursor does not exist - Good")
                else:
                    print("Closing c at 2")
                    s.close()
    
                sys.exit()
                
                
    return [1,fail_df,success_df]
   
def get_po_number():
    
    po_cur = cursor.execute("SELECT MAX(PONumber) as MaxPo FROM PurchaseOrderDetail")
    porow = po_cur.fetchone()
    
    
    if porow is not None:
        return (porow.MaxPo + 1)
    else:
        return 9999  
       
def insertPODetail(df,fail_df):
    
    sNo = 0
    exceptCount = 0 
    
    c = None
    e = None
    
    for idx,row in df.iterrows():
    
        row['source'] = 'receiveprocess'
        
        QtyOrder = 0
        caseCost = 0
        caseOrder = 0
        extendedPrice = 0
        unitCost = 0
        totalCost = 0
        qty = 0

        vpn = row.ProductNumber
        #vpn = r.sub('',row.ProductNumber)
        
        print('Processing {0}'.format(vpn))
        
        ###   Check if ITEM EXISTS
        cur = cursor.execute("SELECT 1 FROM ItemInfo WHERE VendPartNumber = ?",vpn)
        dbrow = cur.fetchone()
        ###        
       
        try:
            qty = int(row.Quantity)
        
            extendedPrice = re.sub(r'[^0-9'+decimal_point_char+r']+', '', str(row.ExtendedPrice))
            InvoiceAmount = re.sub(r'[^0-9'+decimal_point_char+r']+', '', str(row.InvoiceAmount))
            #r.sub("0",row.ExtendedPrice)

        except ValueError:
            print ("Its a Value error")
            
            conn.close()
        
        
        
        #print (dbrow[0])
        if dbrow is None:
            print("Item does not exist")
            
            exceptCount = exceptCount + 1
            
            fail_df = fail_df.append(row)    

        elif qty > 0:    ##IF ITEM EISTS
            
            
            
            sNo = sNo + 1


            unitCost = (float(extendedPrice) / qty) #This Unit Cost is at CASE LEVEL
            
            if row.UnitOfMeasure == 'CA':
                
                caseOrder = qty
                caseCost = unitCost
                        
            else:
                
                QtyOrder = qty
                
            totalCost = extendedPrice
            
            ## CALL Stored Procedure to INSERT PO DETAIL for the VPN
            params = [str(vpn),row.InvoiceNumber,sNo,PoNumber,QtyOrder,caseOrder,caseCost,totalCost,unitCost]
            
            try:
                
                c = cursor.execute("{call xx_spWSInsertVPNInfo (?,?,?,?,?,?,?,?,?)}",params)
                
            except pyodbc.DatabaseError as dberr:
                
                print ("Database error {0}".format(dberr))
                try:
                    c
                except NameError:
                    print("PO DETAIL DB Error and cursor does not exist - Good")
                else:
                    print("Closing c at 1")
                    c.close()
                
                sys.exit()
            
            except pyodbc.Error as err:
                
                print ("Database error {0}".format(err))
                try:
                    c
                except NameError:
                    print("General Error and cursor does not exist - Good")
                else:
                    print("Closing c at 2")
                    c.close()
    
                sys.exit()
        
            print('Loaded {0}'.format(vpn))        
        #break
    
    
    
    if c is not None:
        return [1,c,row.InvoiceNumber,fail_df]
    elif e is not None: #Scenario - If only one item exists in file and that does not exists in POS. If a file has atleast one item that is in POS, "c" will be NOT None and above will be returned
        return [2,e]
    
def insertPOSummary(InvNumber):
    
      
    try:
        
        print('Invoice Number passed to Summary {0}'.format(InvNumber))
        
        s = cursor.execute("{call xx_spWSInsertPOSummary (?)}",str(InvNumber))
            
    except pyodbc.DatabaseError as dberr:
            
        print ("Database error {0}".format(dberr))
        try:
            s
        except NameError:
            
            print("PO SUMMARY DB Error and cursor does not exist - Good")
        else:
            
            s.close()
            
        sys.exit()
        
    return [1,s,InvNumber]   

def receivePO(InvNumber):
    
      
    try:
        
        print('Receive invoce number {0} '.format(InvNumber))
        
        r = cursor.execute("{call xx_spWSPurchaseOrderReceive (?)}",InvNumber)
        
        #time.sleep(1)
        
        if r is None:
            
            print ('r is None')
            
            return [0,]
        
        else:

            while 1:
                
                wait_cur = cursor.execute('select sts,rcvd_count from xx_runningstatus').fetchone()
                
                #recs = wait_cur.fetchone()
                print ('stts back {0}'.format(wait_cur[0]))
                
                if wait_cur[0] == 1:
                    
                    break
                
           
    except pyodbc.DatabaseError as dberr:
            
        print ("Database error {0}".format(dberr))
        try:
            r
        except NameError:
            
            print("PO RECEIVE Error and cursor does not exist - Good")
        else:
            
            r.close()
            
        sys.exit()
        
    return [1,r,wait_cur[1]] 
    
###############################################   MAIN CODE   #######################################################################


#####################REGEXP CLEANUP#############################
r = re.compile('[^0-9]')
decimal_point_char = locale.localeconv()['decimal_point']
###############################################################        
    
    
if __name__ == "__main__":
    
    query = "select e.*,\
       replace(fintech.upc,'-','') fintech_full_barcode,\
	   pos.pos_scancode,\
	   fintech.glcode \
        from  dbo.xx_invoice_entry_exceptions_test e \
        \
        left join [dbo].['xx_Fintech_Product_Catalog'] fintech ON RTRIM(LTRIM(e.item_description)) = RTRIM(LTRIM(fintech.description)) \
        \
        left join POSDB.dbo.xx_sue_file_pos_scancodes_to_full_barcodes pos ON replace(fintech.upc,'-','') = pos.full_scan_code \
        "
    cols = ['InvoiceNumber',
             'vendor',
             'InvoiceDate',
             'InvoiceAmount',
             'InvoiceItemCount',
             'ProductNumber',
             'ProductDescription',
             'Quantity',
             'UnitCost',
             'UnitOfMeasure',
             'ExtendedPrice',
             'PPC',
             'PackUPC',
             'date_inserted',
             'fintech_full_barcode',
             'pos_scancode',
             'glcode',
             'source']
    
    df = pd.read_sql(query,conn,columns = cols)

    ret_sts = updateVPNonExceptions(df)
    
    ret_sts[1].columns = cols   ##fail df
    ret_sts[2].columns = cols   ##success df
    
    if ret_sts[0] == 1:
        
        #recv_sts = receiveExceptions(ret_sts[2]) #pass df of exceptions for which VPN was updated successfully!
        
        
        PoNumber = get_po_number()
        
        poDetailStatus = insertPODetail(ret_sts[2],ret_sts[1])
        
        if poDetailStatus[0] == 1:
            
            print('Insert PO Detail - SUCCESSFUL!!!!!!')
            
            poSummStatus = insertPOSummary(poDetailStatus[2])
                
            if poSummStatus[0] == 1:
                
                print('Insert PO SUMAARY - SUCCESSFUL!!!!!!')
                
                poReceive = receivePO(poDetailStatus[2])
                    
                if poReceive[0] == 1:
                    
                    print('Receive SUCCESSFUL!!!!')
                    
                    poDetailStatus[1].commit()
                    print('PO Detail cursor commited')
                    poSummStatus[1].commit()
                    print('PO Summary cursor commited')
                    poReceive[1].commit()
                    print('PO Receive cursor commited')
        elif poDetailStatus[0] == 2:
                
                
                poDetailStatus[1].commit()

            
            
    cursor.close()

    
    

print ("Total Exception record count: {0}".format(df.shape[0]))
print ("LOADED record count: {0}".format(ret_sts[2].shape[0]))
print ("FAILED record count: {0}".format(ret_sts[1].shape[0]))





            
            