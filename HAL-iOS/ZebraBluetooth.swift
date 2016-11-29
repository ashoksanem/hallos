//
//  ZebraBluetooth.swift
//  HAL-iOS
//
//  Created by Pranitha on 11/10/16.
//  Copyright © 2016 macys. All rights reserved.
//

import Foundation
class ZebraBluetooth
{
    static let pin = "2010072010";
     var receiptWidth = 615;
     var isCPCL = false;
     var printerState = 0;
     var address="";
    init(address: String) {
        self.address = address as String;
        printerState = 0;
        receiptWidth = 615;
        isCPCL = false;
    }
    class func connectToDevice(address:String) -> Bool {
        
        let delegate = UIApplication.shared.delegate as? AppDelegate
        if let sled=delegate?.getSled() as? DTDevices
        {
          if(sled.btConnectedDevices.count==1)
            {
                return true
            }
            do{
                try sled.btConnect(address, pin: ZebraBluetooth.pin)
                
                CommonUtils.setPrinterMACAddress(value: address)
            }
            catch
            {
                print(error)
            }
        }
        return false;
    }
    
    class func disconnectFromDevice() -> Bool {
        
        let delegate = UIApplication.shared.delegate as? AppDelegate
        if let sled=delegate?.getSled() as? DTDevices
        {
            if(sled.btConnectedDevices.count==1)
            {
               
            do{
                try sled.btDisconnect(CommonUtils.getPrinterMACAddress())
            }
            catch
            {
                print(error)
            }
        
            }}
        return true;
    }
    func getCurrentStatus() -> String {
        
        if( isCPCL ){
        return getCurrentStatusCPCL();
        } else
        {
            var rc = "PrinterUnknown";
            rc = getCurrentStatusZPL();
            if( rc == "NoResponse" )
            {
                isCPCL = true;
                rc = getCurrentStatusCPCL();
                isCPCL = ( rc == "NoResponse" ? false : true );
            }
            return rc;
        }
    }
     func getCurrentStatusZPL() -> String {
        var returnCode = "PrinterUnknown";
        let delegate = UIApplication.shared.delegate as? AppDelegate
        if let sled=delegate?.getSled() as? DTDevices
        {
            if(ZebraBluetooth.connectToDevice(address: CommonUtils.getPrinterMACAddress()))
            {
                do{
                    
                    var rawData=[CChar]();
                    memset(&rawData, 0, 5);
                    strncpy(&rawData, "~HQES", 5 );
                    try sled.btWrite(&rawData, length: 5)
                    
                    var resp = [CUnsignedChar](repeating:0x00, count:144)
                    
                    let abc = sled.btRead(&resp, length: Int32(resp.count), timeout: 1,error:nil)
                    returnCode = String(describing: resp)
                    print(abc)
                    if( resp[70] == 0x31 )
                    {
                        let a = resp[88]
                        if( (a&1).hashValue==1 ){
                            returnCode = "NoPaper";}
                        else if( (a&4).hashValue==4 ){
                            returnCode = "LatchOpen";}
                        else if( (a&8).hashValue==8 ){
                            returnCode = "LowBattery";}
                        else{
                        returnCode = "Busy";
                        }
                    }
                    else
                    {
                        if( abc == 0 ){
                            returnCode = "NoResponse";}
                        else{
                            returnCode = "Available";
                        }
                    }

                }
                catch
                {
                    returnCode = error.localizedDescription
                    print(error)
                }
            
            }
        }
        return returnCode;
    }
    func getCurrentStatusCPCL() -> String {
        var returnCode = "PrinterUnknown";
        let delegate = UIApplication.shared.delegate as? AppDelegate
        if let sled=delegate?.getSled() as? DTDevices
        {
            if(ZebraBluetooth.connectToDevice(address: CommonUtils.getPrinterMACAddress()))
            {
                do{
                    
                    //var rawData:[CChar]=[ 0x1b, Int8(Int(("h" as UnicodeScalar).value))];
                    //try sled.btWrite(&rawData, length: 2)
                    var rawData=[CChar]();
                    memset(&rawData, 0, 200);
                   // strncpy(&rawData, "! 0 200 200 210 1 TEXT 4 0 200 100 TEXT TEXT90 4 0 200 100 T90 TEXT180 4 0 200 100 T180 TEXT270 4 0 200 100 T270 FORM \r\nPRINT", 200 );
                    strncpy(&rawData, "! 0 200 200 210 1 TEXT 4 0 10 20 1st line of text 2nd line of text \r\n FORM \r\nPRINT", 200 );
                    try sled.btWrite(&rawData, length: 200)
                
                   var resp = [CUnsignedChar](repeating:0x00, count:1)
                    
                    let abc = sled.btRead(&resp, length: Int32(resp.count), timeout: 1,error:nil)
                    returnCode = String(describing: resp)
                    print(abc)
                    if( abc != 0 )
                    {
                        let x=resp[0].hashValue;
                        
                         if( (x&1).hashValue==1 ){
                            returnCode = "Busy";
                            if( (x&2).hashValue==2 ){
                                returnCode = "NoPaper";}
                            if( (x&4).hashValue==4 ){
                                returnCode = "LatchOpen";}
                            if( (x&8).hashValue==8 ){
                                returnCode = "LowBattery";}
                         }
                        else{
                            returnCode = "Available";
                            var rawData=[CChar]();
                            memset(&rawData, 0, 200);
                            strncpy(&rawData, "! 0 200 200 210 1 \r\n TEXT 4 0 30 40 Hello FDFFFWorld \r\n FORM \r\nPRINT\r\n", 200 );
                            //strncpy(&rawData, "! 0 200 200 210 1 \r\n CONCAT 75 75 425$ \r\n 4 3 0 12 \r\n 4 2 5 34 \r\n ENDCONCAT \r\n FORM \r\n PRINT", 200 );
                            try sled.btWrite(&rawData, length: 200)}
                        
                    }
                    else{
                        returnCode = "NoResponse";
                    }
                
                }
                catch
                {
                    returnCode = error.localizedDescription
                    print(error)
                }
                
            }
        }
        return returnCode;

    }
     }
