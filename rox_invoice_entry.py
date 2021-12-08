1# -*- coding: utf-8 -*-
"""
Created on Sat Jul 21 15:51:26 2018

@author: anilmenta
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

""" 
server = 'WESTSIDE-SERVER\TIGERPOS'
database = 'POSDB'
username = 'tst'
password = 'Welcome@123'
"""

server = 'WHQPC-L31249\SQLEXPRESS'
database = 'RDLPOSDB'
username = 'poc'
password = 'Pa44word'

scan_count = 0 ## Anil
vpn_count = 0 ##Anil

"""
conn = pyodbc.connect('DRIVER={ODBC Driver 17 for SQL Server};SERVER='+server+';DATABASE='+database+';UID='+username+';PWD='+ password)
cursor = conn.cursor()
"""

conn = pyodbc.connect('DRIVER={ODBC Driver 13 for SQL Server};SERVER='+server+';DATABASE='+database+';UID='+username+';PWD='+ password)
cursor = conn.cursor()

def get_po_number():
    
    po_cur = cursor.execute("SELECT MAX(PONumber) as MaxPo FROM PurchaseOrderDetail")
    porow = po_cur.fetchone()
    
    
    if porow is not None:
        return (porow.MaxPo + 1)
    else:
        return 9999
sNo = 0

def updateVPN(vpn,scancode):
    
    
    
    try:
        
        print('Updating scancode {0} with new vpn {1}'.format(scancode,vpn))
        u = cursor.execute("{call xx_spWSUpdateVPNFromExceptions (?,?)}",vpn,scancode)

    except pyodbc.DatabaseError as dberr:
        
        print ("Database error while updating VPN{0}".format(dberr))
    
        try:
            u
        except NameError:
            
            print("PO SUMMARY DB Error and cursor does not exist - Good")
        else:
            
            u.close()
        
        sys.exit()
    
    except pyodbc.Error as err:
        
        
        print ("Database error {0}".format(err))
        
        try:
            u
        except NameError:
            print("General Error and cursor does not exist - Good")
        else:
            print("Closing u at 2")
            u.close()

        sys.exit()
        
    return u;
        

def insertPODetail(df,file):
    
    sNo = 0
    exceptCount = 0 
    
    c = None
    e = None
    upd_cur = None
    itemeligibleCount = 0
    
    #cols = ['file','invoice_number','vpn','productdescription','caseupc','packupc','final_upc','glcode','source']
    #items_found_df = pd.DataFrame(data=None,columns = cols) #This DF is used to analyze how an item is identified (vpn, direct scanid or sue's file) 
    
    for row in df.itertuples():
    
        QtyOrder = 0
        caseCost = 0
        caseOrder = 0
        extendedPrice = 0
        unitCost = 0
        totalCost = 0
        qty = 0
        

        
        vpn = ''
        if vendor == "Veraison Beverage Distributors":
            vpn = ''.join(e for e in row.ProductNumber if e.isalnum())
        elif vendor == "CTS Distributing INC":
        
            vpn = row.ProductNumber[:row.ProductNumber.index('_')]
            vpn = r.sub('',row.ProductNumber)
        else:
            vpn = r.sub('',str(row.ProductNumber))
        
        
        if vendor in ["Republic National Dist - CO","Southern Glazer's Wine & Spirits of CO","Empire Distributors of Colorado"]:
            vpn = vpn.lstrip('0')
        
        #vpn = prefix + vpn
        
       
        scancode = str(row.UPCNumber).replace("-","")   
        scancode = r.sub('',scancode)
        
        #vpn = 'C00031'
        
        print('Processing {0}'.format(vpn))
        
        ###   Check if ITEM EXISTS
        cur = cursor.execute("SELECT 1 FROM ItemInfo WHERE VendPartNumber = ?",vpn)
        dbrow = cur.fetchone()
        source = 'vpn'  # anil
        ###
        
        ####CHECK IF ITEM IDENTIFIED IN POS START ####
        
        if dbrow is None:  ##Item NOT FOUND through VPN, SO CHECK USING DIRECT SCANID
            
            print('Item NOT found through VPN')
            
            if scancode is not None:
                
                print('Checking the SCANCODE {0}'.format(scancode))
                
                scancode_q = '%'+str(scancode)+'%'
            
                cur = cursor.execute("SELECT ItemScanID FROM ItemInfo WHERE ItemScanID like ?",scancode_q)
                dbrow = cur.fetchone()
                
            
                if dbrow is not None: ##Item FOUND through scancode
                    
                    print('ITEM FOUND THROUGH SCANCODE')
                    
                    source = 'scancode'
                    if prefix != 'XXX':
                        upd_cur = updateVPN(vpn,dbrow[0])
                    
       ####CHECK IF ITEM IDENTIFIED IN POS END ####
        
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
            
            if qty > 0:
                itemeligibleCount += 1
            
            exceptCount = exceptCount + 1
            
            try:
                
                #print ('Descriptiontest - {0}'.format(row.ProductDescription))
                #print ('InvoiceNumberTest - {0}'.format(str(InvoiceNumber)))
                #print ('VPNTest - {0}'.format(str(vpn)))
                
                exceptParams =[str(InvoiceNumber),vendor,row.InvoiceDate,InvoiceAmount,int(row.InvoiceItemCount),
                           str(vpn),row.ProductDescription,qty,row.UnitCost,row.UnitOfMeasure,extendedPrice,row.PPC,scancode]
                
                e = cursor.execute("{call xx_spWSInsertVPNExceptions (?,?,?,?,?,?,?,?,?,?,?,?,?)}",exceptParams)
            
            except pyodbc.DatabaseError as dberr:
                
                print ("Database error {0}".format(dberr))
                
                try:
                    e
                except NameError:
                    print("DB Error and cursor does not exist - Good")
                else:
                    print("Closing e at 1")
                    e.close()
                
                sys.exit()
            
            except pyodbc.Error as err:
                
                print ("Database error {0}".format(err))
                try:
                    e
                except NameError:
                    print("General Error and cursor does not exist - Good")
                else:
                    print("Closing e at 2")
                    e.close()
    
                sys.exit()
   
            
            

        elif qty > 0:    ##IF ITEM EISTS
            
            
            itemeligibleCount += 1
            
            sNo = sNo + 1

            unitCost = (float(extendedPrice) / qty) #This Unit Cost is at CASE LEVEL
            
            if row.UnitOfMeasure == 'CA':
                
                caseOrder = qty
                caseCost = unitCost
                        
            else:
                
                QtyOrder = qty
                
            totalCost = extendedPrice
            
            ## CALL Stored Procedure to INSERT PO DETAIL for the VPN
            params = [str(vpn),str(InvoiceNumber),sNo,PoNumber,QtyOrder,caseOrder,caseCost,totalCost,unitCost,file,row.UPCNumber,row.PackUPC,scancode,'NA',source,row.ProductDescription]
            
            try:
                
                c = cursor.execute("{call xx_spWSInsertVPNInfo (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)}",params)
                
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
        return [1,c,str(InvoiceNumber),exceptCount,upd_cur,itemeligibleCount]
    elif e is not None: #Scenario - If only one item exists in file and that does not exists in POS. If a file has atleast one item that is in POS, "c" will be NOT None and above will be returned
        return [2,e]
        
        
        
        
    print('VPN Count = {0}'.format(vpn_count))
    print('SCAN Count = {0}'.format(scan_count))
    
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
        
        #print('Receive invoce number {0} '.format(InvNumber))
        #print ('InvoiceNumberTestReceive - {0}'.format(str(InvoiceNumber)))
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

def logFileProcessed(file_name,inv_number,rcvd_count,itemseligible_count):
    
    try:
        
        log_cur = cursor.execute("{call xx_log_file_processed_details(?,?,?,?)}",file_name,inv_number,rcvd_count,itemseligible_count)
    
    except pyodbc.DatabaseError as dberr:
            
        print ("Database error {0}".format(dberr))
        
        try:
            log_cur
        except NameError:
            
            print("Logging file processed details cursor does not exist- Good")
            
            cursor.close()
            
        else:
            
            log_cur.close()
            
        sys.exit()
        
    return 1    


def clean_df(df):
    
    #Commented cleaning of Quantity as fintech gives clean numbers 11/30
    df['Quantity'] = df['Quantity'].apply(lambda x: float(re.sub(r'[^0-9'+decimal_point_char+r']+', '', str(x))))
    df['UnitCost'] = df['UnitCost'].apply(lambda x: float(re.sub(r'[^0-9'+decimal_point_char+r']+', '', str(x))))
    
    #Returned to vendor or out of stock ones come as -ve or 0 qty
    tdf = df[df.Quantity > 0].copy(deep=True)
    
 
    #clean up currency columns. It comes with '$' symbol
    tdf['ExtendedPrice'] = tdf['ExtendedPrice'].apply(lambda x: re.sub(r'[^0-9'+decimal_point_char+r']+', '', str(x)))
    tdf['InvoiceAmount'] = tdf['InvoiceAmount'].apply(lambda x: re.sub(r'[^0-9'+decimal_point_char+r']+', '', str(x)))
    tdf['TotalAdjustments'] = tdf['TotalAdjustments'].apply(lambda x: re.sub(r'[^0-9'+decimal_point_char+r']+', '', str(x)))
    tdf['TotalDisc'] = tdf['TotalDisc'].apply(lambda x: re.sub(r'[^0-9'+decimal_point_char+r']+', '', str(x)))
    
    cols_grouped = ['VendorName',
                     'RetailerName',
                     'CustomerID',
                     'StoreID',
                     'ProcessDate',
                     'InvoiceDate',
                     'InvoiceDueDate',
                     'InvoiceNumber',
                     'InvoiceAmount',
                     'InvoiceItemCount',
                     'ReferenceInvoiceNumber', 
                     'ProductNumber',
                     'UnitOfMeasure',
                     'UPCNumber',
                     'ProductDescription',
                     'PPC',
                     'PackUPC',
                     #'GLCode' checked on coors, this is coming as null
                     ]
    
    currency_cols = ['Quantity', 'UnitCost', 'TotalAdjustments', 'TotalDisc', 'ExtendedPrice']
    
    tdf[currency_cols] = tdf[currency_cols].astype(float)
    
    cols_for_agg = {'Quantity':'sum','UnitCost':'sum','TotalAdjustments':'sum','TotalDisc':'sum','ExtendedPrice':'sum'}
    
    #Add quantites for FREE items
    cleaneddf = tdf.groupby(cols_grouped,as_index=False).agg(cols_for_agg)
    
    return cleaneddf
    
    
def generate_input_files(fulldf,downloaded_file):

    groups = fulldf.groupby(['VendorName','InvoiceNumber'])
    #print (downloaded_file)
    
    for key,group in groups:
        
        #print('key = {0}'.format(key[1]))
        groupdf = pd.DataFrame(group)
        processDate = groupdf['ProcessDate'].unique()[0]
        InvNum = key[1]
        Vendorname = key[0][0:30]
        
        groupdf.to_csv(str(datetime.strftime(datetime.strptime(processDate,'%m/%d/%Y'),'%d%b%Y'))+Vendorname+str(InvNum)+'.csv')
    
    shutil.move(source_dir + downloaded_file, download_archive+downloaded_file)

################ MAIN CODE STARTS HERE ###########################

source_dir = "C:/Anil/Projects/wsl/InvoiceAutomation/input/"
dest_dir = "C:/Anil/Projects/wsl/InvoiceAutomation/processed/"
download_archive = "C:/Anil/Projects/wsl/InvoiceAutomation/download_archive/"

'''
source_dir = "C:/wsl/InvoiceAutomation/input/"
dest_dir = "C:/wsl/InvoiceAutomation/processed/"
download_archive = "C:/wsl/InvoiceAutomation/download_archive/"
'''
os.chdir(source_dir)

#####################REGEXP CLEANUP#############################
r = re.compile('[^0-9]')
decimal_point_char = locale.localeconv()['decimal_point']
###############################################################

df_col_headers = ['VendorName',
 'RetailerName',
 'RetailerVendorId',
 'CustomerID',
 'StoreID',
 'RetailerRelationshipID',
 'ProcessDate',
 'InvoiceDate',
 'InvoiceDueDate',
 'InvoiceNumber',
 'InvoiceAmount',
 'InvoiceItemCount',
 'PONumber',
 'PODate',
 'ReferenceInvoiceNumber',
 'ProductNumber',
 'Quantity',
 'UnitCost',
 'UnitOfMeasure',
 'UPCNumber',
 'ProductDescription',
 'TotalAdjustments',
 'TotalDisc',
 'ExtendedPrice',
 'PPC',
 'PackUPC',
 #'GLCode'
 ]

#checked on coors, this is coming as null

if __name__ == "__main__":
    
    scan_count = 0 ## Anil
    vpn_count = 0 ##Anil
    
    downloaded_file = glob.glob('*.csv')
    
    fulldf = pd.read_csv(downloaded_file[0],encoding='cp1252',names=df_col_headers,header=0,dtype={"ProductNumber":"str"},index_col=False)
    #fulldf = fulldf[fulldf["ProductNumber"].astype(str).str[0] == '0']
    
    generate = True #TEMPERORY
    
    if generate == True:
        generate_input_files(fulldf,downloaded_file[0])
    
    for file in glob.glob('*.csv'):
        
        print("Processing FILE {0}".format(file))
        tempdf = pd.read_csv(file,dtype={"ProductNumber":"str"})
        
        df = clean_df(tempdf)
        
        if df.shape[0] > 0:
            
            vendor = df.VendorName.unique()[0]
        
            InvoiceNumber = 'AUT-'+str(df.InvoiceNumber.unique()[0])
            
            cur = cursor.execute("SELECT 1 FROM PurchaseOrderSummary WHERE InvoiceNumber = ?",InvoiceNumber)
            
            inv_cur = cur.fetchone()
            
            if inv_cur is not None:
                
                currDt = datetime.strftime(datetime.now(),"%Y-%m-%d %H:%M:%S")
                
                InvoiceNumber = InvoiceNumber + currDt
                
                
            
            # Check the Distributor Name for prefix
            prefix = 'XXX'
            
            if vendor == "Coors Distributing Company":
                prefix = 'C'
            elif vendor == "Anheuser-Busch Sales of Littleton":
                prefix = 'AA0'
            elif vendor == "Republic National Dist - CO":
                prefix = 'N'
            elif vendor == "Beverage Distributors Company dba Breakthru Bev":
                prefix = 'BDC'
            elif vendor == "Elite Brands of Colorado":
                prefix = 'ELITE'
            elif vendor == "Synergy Fine Wines Dominico Distribution - CO":
                prefix = 'SYN'
            elif vendor == "Classic Wines, LLC":
                prefix = 'CW'
            elif vendor == "Southern Glazer's Wine & Spirits of CO": 
                prefix = 'SW'
            elif vendor == "Western Distributing Company, Inc":
                prefix = 'WDC'
            elif vendor == "Veraison Beverage Distributors":
                prefix = 'VBD'
            elif vendor == "Estate Brands Distributing Company":
                prefix = 'EBDC'   
            elif vendor == "CTS Distributing Inc.":
                prefix = 'CTS'
            elif vendor == "Crooked Stave Artisans":
                prefix = 'CSA'
            elif vendor == "Worldwide Beverage":
                prefix = 'WWB'
            elif vendor == "Empire Distributors of Colorado":
                prefix = 'EDC'
            elif vendor == "E-Corp Inc.":
                prefix = 'EC'
            elif vendor == "Maverick Wine Company of Colorado, LLC":
                prefix = 'MWC'                
            elif vendor == "New Age Beverages Corporation":
                prefix = 'NAB' 
            elif vendor == "Colorado Beverage Team":
                prefix = 'CBT'
            elif vendor == "Colorado Craft Distributors":
                prefix = 'CCD'   
            elif vendor == "Eagle Rock - Littleton":
                prefix = 'ERL'                 
            
            
            
            PoNumber = get_po_number()
        
        

            
            poDetailStatus = insertPODetail(df,file)
            
            if poDetailStatus[0] == 1:
                
                print('Insert PO Detail - SUCCESSFUL!!!!!!')
                
                poSummStatus = insertPOSummary(poDetailStatus[2])
                
                if poSummStatus[0] == 1:
                    
                    print('Insert PO SUMAARY - SUCCESSFUL!!!!!!')
                    
                    #print('passing Invoice number to recevie {0}'.format(poDetailStatus[2]))

                    poReceive = receivePO(poDetailStatus[2])
                    
                    if poReceive[0] == 1:
                        
                        print('Receive SUCCESSFUL!!!!')
                        
                        poLog = logFileProcessed(file,poDetailStatus[2],poReceive[2],poDetailStatus[5])
                        
                        if poLog ==1:
                            
                            poDetailStatus[1].commit()
                        
                            print('PO Detail cursor commited')
                            poSummStatus[1].commit()
                            print('PO Summary cursor commited')
                            poReceive[1].commit()
                            print('PO Receive cursor commited')
                            
                            if poDetailStatus[4] is not None:
                                poDetailStatus[4].commit()
                                print('Update cursor commited')
                            #poSummStatus[1].close()
                            
                            print('Moving file {0} to Processed '.format(file))
                            
                            shutil.move(source_dir + file, dest_dir+file)
            elif poDetailStatus[0] == 2:
                shutil.move(source_dir + file, dest_dir+file)
                print("Nothing to process in file {0}".format(file))
                poDetailStatus[1].commit()
            
        else:
            print("DF is empty when processing file {0}".format(file))
            shutil.move(source_dir + file, dest_dir+file)                
   
    
    cursor.close()
                        
