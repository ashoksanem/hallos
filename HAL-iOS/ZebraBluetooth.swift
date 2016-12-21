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
                if(sled.btConnectedDevices.count==1)
                {
                    CommonUtils.setPrinterMACAddress(value: address)
                    return true
                }
                else{
                    return false
                }
            }
            catch
            {
                print(error)
                return false
            }
        }
        return false;
    }
    class func printData(receiptMarkUp:String) -> Bool {
        let zplConnector:ZPLConnector = ZPLConnector()
        let delegate = UIApplication.shared.delegate as? AppDelegate
        let sled=delegate?.getSled() as? DTDevices
        let zb =  ZebraBluetooth.init(address: CommonUtils.getPrinterMACAddress())
        if(zb.getCurrentStatus()=="Available"){
            /*zplConnector.printStuff("<Center/><H3>Macy's \n </H3>Birchwood \n LORAIN 322 TEST TEST \n 219 SHEFFIELD CENTER TEST \n LORAIN TEST, MN 55402 \n 898-989-8989 \n <H3><H3>NOT A VALID RECEIPT</H3></H3> \n \n <Left/><B>   322-1799-0003 \n </B>   71234561  1799  2:01 PM 11/17/2016      \n Code: 01 \n Term: 1799 \n Tran: 0003 \n <Center/><H3>SUSPENDED</H3> \n <Left/> \n <Barcode>L21013221799201611170003</Barcode><Center/>21013221799201611170003 <Left/># Items: 1 \n <Left/>Total: 40.00 \n <Left/>(Total may not include tax and/or fees) \n  <H3>\n <Center/><H3>NOT A VALID RECEIPT</H3></H3> <Cut/>", withSled: sled, isCPCL: CommonUtils.isCPCLPrinter());*/
            zplConnector.printStuff(receiptMarkUp, withSled: sled, isCPCL: CommonUtils.isCPCLPrinter());
            return true;
        }
        else
        {
            return false
        }
        
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
            }
            if(sled.btConnectedDevices.count==0)
            {
                return true;
            }
            else
            {
                return false;
            }
        }
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
            if(sled.btConnectedDevices.count==1)
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
                            CommonUtils.setCPCLPrinter(value: false)
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
            if(sled.btConnectedDevices.count==1){
                do{
                    var rawData:[CChar]=[ 0x1b, Int8(Int(("h" as UnicodeScalar).value))];
                    try sled.btWrite(&rawData, length: 2)
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
                            CommonUtils.setCPCLPrinter(value: true)
                        }
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
