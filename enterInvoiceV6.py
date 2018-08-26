# -*- coding: utf-8 -*-
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


server = 'WHQPC-L31249\SQLEXPRESS'
database = 'POSDB'
username = 'poc'
password = 'Welcome@123'


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

def insertPODetail(df):
    
    sNo = 0
    exceptCount = 0 
    
    c = None
    e = None
    
    for row in df.itertuples():
    
        QtyOrder = 0
        caseCost = 0
        caseOrder = 0
        extendedPrice = 0
        unitCost = 0
        totalCost = 0
        qty = 0

        vpn = ''
        vpn = r.sub('',row.ProductNumber)
        
        if vendor in ["Republic National Dist - CO","Southern Glazer's Wine & Spirits of CO"]:
            vpn = vpn.lstrip('0')
        
        vpn = prefix + vpn
        
        #vpn = 'C00031'
        
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
            
            try:
                
                exceptParams =[str(InvoiceNumber),vendor,row.InvoiceDate,InvoiceAmount,int(row.InvoiceItemCount),
                           str(vpn),row.ProductDescription,qty,row.UnitCost,row.UnitOfMeasure,extendedPrice,row.PPC,row.PackUPC]
                
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
            '''    
            except:
                
                print("Error Occurred when VPN NOT Found - {0}")
            '''    

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
            params = [str(vpn),str(InvoiceNumber),sNo,PoNumber,QtyOrder,caseOrder,caseCost,totalCost,unitCost]
            
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
        return [1,c,str(InvoiceNumber),exceptCount]
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

def logFileProcessed(file_name,inv_number,rcvd_count):
    
    try:
        
        log_cur = cursor.execute("{call xx_log_file_processed_details(?,?,?)}",file_name,inv_number,rcvd_count)
    
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
    
    #Returned to vendor or out of stock ones come as -ve or 0 qty
    tdf = df[df.Quantity > 0].copy(deep=True)
    
 
    #clean up currency columns. It comes with '$' symbol
    tdf['ExtendedPrice'] = tdf['ExtendedPrice'].apply(lambda x: re.sub(r'[^0-9'+decimal_point_char+r']+', '', str(x)))
    tdf['InvoiceAmount'] = tdf['InvoiceAmount'].apply(lambda x: re.sub(r'[^0-9'+decimal_point_char+r']+', '', str(x)))
    tdf['TotalAdjustments'] = tdf['TotalAdjustments'].apply(lambda x: re.sub(r'[^0-9'+decimal_point_char+r']+', '', str(x)))
    tdf['TotalDisc'] = tdf['TotalDisc'].apply(lambda x: re.sub(r'[^0-9'+decimal_point_char+r']+', '', str(x)))
    
    cols_grouped = ['VendorName',
                     'RetailerName',
                     'RetailerVendorId',
                     'VendorStoreNumber',
                     'RetailerStoreNumber',
                     'RetailerRelationshipID',
                     'FintechProcessDate',
                     'InvoiceDate',
                     'InvoiceDueDate',
                     'InvoiceNumber',
                     'InvoiceAmount',
                     'InvoiceItemCount',
                     'PONumber',
                     'PODate',
                     'ReferenceInvoiceNumber',
                     'ProductNumber',
                     'UnitOfMeasure',
                     'UPCNumber',
                     'ProductDescription',
                     'PPC',
                     'PackUPC',
                     'GLCode']
    
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
        processDate = groupdf['FintechProcessDate'].unique()[0]
        InvNum = key[1]
        Vendorname = key[0][0:30]
        
        groupdf.to_csv(str(datetime.strftime(datetime.strptime(processDate,'%m/%d/%Y'),'%d%b%Y'))+Vendorname+str(InvNum)+'.csv')
    
    shutil.move(source_dir + downloaded_file, download_archive+downloaded_file)

################ MAIN CODE STARTS HERE ###########################

source_dir = "C:/Anil/Projects/wsl/InvoiceAutomation/input/"
dest_dir = "C:/Anil/Projects/wsl/InvoiceAutomation/processed/"
download_archive = "C:/Anil/Projects/wsl/InvoiceAutomation/download_archive/"

os.chdir(source_dir)

#####################REGEXP CLEANUP#############################
r = re.compile('[^0-9]')
decimal_point_char = locale.localeconv()['decimal_point']
###############################################################

if __name__ == "__main__":
    
    downloaded_file = glob.glob('*.csv')
    
    fulldf = pd.read_csv(downloaded_file[0])
    
    generate = True #TEMPERORY
    
    if generate == True:
        generate_input_files(fulldf,downloaded_file[0])
    
    for file in glob.glob('*.csv'):
        
        print("Processing FILE {0}".format(file))
        tempdf = pd.read_csv(file)
        
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
            if vendor == "Coors Distributing Company":
                prefix = 'C'
            elif vendor == "Anheuser-Busch Sales - Littleton":
                prefix = 'AA0'
            elif vendor == "Republic National Dist - CO":
                prefix = 'N'
            elif vendor == "Beverage Distributors Company dba Breakthru Bev":
                prefix = 'BDC'
            elif vendor == "Elite Brands of Colorado":
                prefix = 'ELITE'
            elif vendor == "Synergy Fine Wines Dominico Distribution":
                prefix = 'SYN'
            elif vendor == "Classic Wines, LLC":
                prefix = 'CW'
            elif vendor == "Southern Glazer's Wine & Spirits of CO":
                prefix = 'SW'
        
        
            PoNumber = get_po_number()
        
        
            poDetailStatus = insertPODetail(df)
            
                
            if poDetailStatus[0] == 1:
                
                print('Insert PO Detail - SUCCESSFUL!!!!!!')
                
                poSummStatus = insertPOSummary(poDetailStatus[2])
                
                if poSummStatus[0] == 1:
                    
                    print('Insert PO SUMAARY - SUCCESSFUL!!!!!!')
                    
                    #print('passing Invoice number to recevie {0}'.format(poDetailStatus[2]))
                    '''
                    print('PO Detail cursor commited')
                    poSummStatus[1].commit()
                    print('PO Summary cursor commited')
                    #poReceive[1].commit()
                    print('PO Receive cursor commited')
                    poSummStatus[1].close()
                    
                    print('Closing PO Summ connection')
            
                    '''
                    poReceive = receivePO(poDetailStatus[2])
                    
                    if poReceive[0] == 1:
                        
                        print('Receive SUCCESSFUL!!!!')
                        
                        poLog = logFileProcessed(file,poDetailStatus[2],poReceive[2])
                        
                        if poLog ==1:
                            
                            poDetailStatus[1].commit()
                        
                            print('PO Detail cursor commited')
                            poSummStatus[1].commit()
                            print('PO Summary cursor commited')
                            poReceive[1].commit()
                            print('PO Receive cursor commited')
                            #poSummStatus[1].close()
                            
                            #print('Closing PO Summ connection')
                            
                            shutil.move(source_dir + file, dest_dir+file)
            elif poDetailStatus[0] == 2:
                shutil.move(source_dir + file, dest_dir+file)
                print("Nothing to process in file {0}".format(file))
                poDetailStatus[1].commit()
        else:
            print("DF is empty when processing file {0}".format(file))
            shutil.move(source_dir + file, dest_dir+file)                
    cursor.close()
                        
