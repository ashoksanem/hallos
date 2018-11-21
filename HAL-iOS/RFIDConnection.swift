//
//  RFIDConnection.swift
//  HAL-iOS
//
//  Created by Pranitha Kota on 10/22/18.
//  Copyright © 2018 macys. All rights reserved.
//

import Foundation
import rfid_ios_fw

class RFIDConnection: NSObject, RfidSDKDelegate
{
    var rfidClient: RfidSDK? = RfidSDK.shared()
    var isLocating = false;
    var isLocatingSessionOpen = false;
    var isInventorySessionOpen = false;
    
    func getBatteryLevel() -> String {
        return String(rfidClient?.getReaderStatus()?.batteryLevel ?? 0);
    }
    
    func EventInventoryLocalTagCountDidChange(localTagCount: Int) {
        if(isInventorySessionOpen)
        {
        let data = [
            "type": "InventoryLocalTagCount",
            "localTagCount": localTagCount
            ] as [String : Any]
        updateRfidData(data: data)
        }
    }
    func EventInventoryTotalTagCountDidChange(totalTagCount: Int) {
        let data = [
            "type": "inventoryTotalTagCount",
            "totalTagCount": totalTagCount
            ] as [String : Any]
        updateRfidData(data: data)
    }
    //
    func EventInventoryUserCountChange(userCount: Int) {
        let data = [
            "type": "inventoryUserCount",
            "userCount": userCount
            ] as [String : Any]
        updateRfidData(data: data)
    }
    
    func updateRfidData(data: [String : Any])
    {
        let jsonData = try! JSONSerialization.data(withJSONObject: data, options: [])
        let  rfidData = String(data: jsonData, encoding: String.Encoding.utf8) ?? ""
        print("pranitha "+rfidData)
        if let viewController:ViewController = UIApplication.shared.keyWindow?.rootViewController as? ViewController
        {
            viewController.updateRfidData(rfidData:rfidData);
        }
    }
    func updateBarcodeData(barcode: String)
    {
        if let viewController:ViewController = UIApplication.shared.keyWindow?.rootViewController as? ViewController
        {
            viewController.updateBarcodeData(barcode: barcode)
        }
    }
    
    func enableRFID() -> String
    {
        var result = rfidClient?.establishConnection()
        rfidClient?.addDelegate(self)
        if(result == RFID_RESULT.SUCCESS)
        {
            RfidUtils.setRFIDScannerConnected(enabled: true)
        }
        return RfidUtils.TranslateResultToStringResult(result ?? RFID_RESULT.FAILURE);
    }
    
    func enableScanner() -> Bool
    {
        var scannerEnabled = isLocatingSessionOpen || isInventorySessionOpen || RfidUtils.isRFIDEScannerConnected()
        if(!scannerEnabled)
        {
            var enableRFIDResult = enableRFID();
            if(enableRFIDResult == "SUCCESS")
            {
                scannerEnabled = true;
            }
        }
        print(rfidClient?.getReaderStatus()?.deviceId);
        print(rfidClient?.getReaderStatus()?.isConnected);
        rfidClient?.enableBarcodeReader(enable: true)
        RfidUtils.setRFIDScannerEnabled(enabled: scannerEnabled)
        return scannerEnabled;
    }
    
    func disableScanner() -> Bool
    {
        //rfidClient?.enableBarcodeReader(enable: false)
        RfidUtils.setRFIDScannerEnabled(enabled: false)
        //RfidUtils.setRFIDScannerConnected(enabled: false)
        return true;
    }
    
    func changeSessionMode(data: NSDictionary) -> String
    {
        let mode = (data["mode"] as? String) ?? "";
        let invWorkerInstance = rfidClient?.getInventoryWorkerInstance();
        if(invWorkerInstance != nil)
        {
            if(mode == RfidUtils.autoPlayMode )
            {
                var result = INVENTORY_RESULT.FAILURE;
                result =  (invWorkerInstance?.startInventory())!;
                if(result == INVENTORY_RESULT.SUCCESS)
                {
                    RfidUtils.setInventorySessionMode(mode: RfidUtils.autoPlayMode)
                }
                return RfidUtils.TranslateResultToStringResult(result)
            }
            else if(mode == RfidUtils.triggerMode )
            {
                RfidUtils.setInventorySessionMode(mode: RfidUtils.triggerMode)
                return RfidUtils.TranslateResultToStringResult(INVENTORY_RESULT.SUCCESS)
            }
            else
            {
                return "INVALID_INPUT";
            }
        }
        else
        {
            return RfidUtils.TranslateResultToStringResult(INVENTORY_RESULT.NO_OPEN_SESSION)
        }
    }
    
    func startInventorySession(data:NSDictionary) -> String{
        isLocatingSessionOpen = false;
        rfidClient?.addDelegate(self)
        let server = (data["rfidServer"] as? String) ?? "";
        let port = (data["port"] as? Int) ?? -1;
        let storeID = (data["storeID"] as? String) ?? "";
        let tableName = (data["tableName"] as? String) ?? "";
        if(server != "" && port != -1 && storeID != "" && tableName != "")
        {
             rfidClient?.EstablishComm(hostname: server, port: port, completion: {response -> Void in
                print(response)
             })
            rfidClient?.setReaderSession(READER_SESSION.S2)
            var result = rfidClient?.getInventoryWorkerInstance()?.openInventorySession(withTableName: tableName)
            RfidUtils.setInventorySessionMode(mode: RfidUtils.triggerMode)
            if(result == INVENTORY_RESULT.SUCCESS)
            {
                isInventorySessionOpen = true;
            }
            return RfidUtils.TranslateResultToStringResult(result ?? INVENTORY_RESULT.FAILURE)
        }
        else
        {
            return "INVALID_INPUT";
        }
    }
    
    func EventTriggerNotify(pressed: Bool) {
        if(isLocatingSessionOpen)
        {
            if pressed {
                startTagLocating()
            }
            else{
                stopTagLocating()
            }
        }
        else if(isInventorySessionOpen && RfidUtils.getInventorySessionMode() == RfidUtils.triggerMode)
        {
            if pressed {
                 rfidClient?.getInventoryWorkerInstance()?.startInventory()
                
            }
            else {
                rfidClient?.getInventoryWorkerInstance()?.stopInventory()
            }
        }
        else if(RfidUtils.isRFIDEScannerConnected() && RfidUtils.isRFIDEScannerEnabled())
        {
            if pressed {
                //var r1 = rfidClient?.enableBarcodeReader(enable: true)
                var r1 = rfidClient?.startScanningBarcode()
                print(r1)
            }
            else{
                //rfidClient?.enableBarcodeReader(enable: false)
                rfidClient?.stopScanningBarcode()
            }
        }
    }
    //save rfid session
    func closeRfidSession() -> String{
        if(isLocatingSessionOpen)
        {
            return closeLocatingSession()
        }
        else
        {
            return closeInventorySession()
        }
    }
    
    func closeInventorySession() -> String{
        isInventorySessionOpen = false;
        var result = rfidClient?.getInventoryWorkerInstance()?.stopInventory();
        result = rfidClient?.getInventoryWorkerInstance()?.commitInventorySession();
        result = rfidClient?.getInventoryWorkerInstance()?.clearTags();
        if(result == INVENTORY_RESULT.SUCCESS)
        {
            result = rfidClient?.getInventoryWorkerInstance()?.closeInventorySession();
        }
        return RfidUtils.TranslateResultToStringResult(result ?? INVENTORY_RESULT.FAILURE)
    }
    func clearRfidSession() -> String{
        let result = rfidClient?.getInventoryWorkerInstance()?.clearTags();
        return RfidUtils.TranslateResultToStringResult(result ?? INVENTORY_RESULT.FAILURE)
    }
    func cancelRfidSession() -> String{
        rfidClient?.getInventoryWorkerInstance()
        var result = rfidClient?.getInventoryWorkerInstance()?.stopInventory();
        result = rfidClient?.getInventoryWorkerInstance()?.clearTags();
        result = rfidClient?.getInventoryWorkerInstance()?.closeInventorySession();
        return RfidUtils.TranslateResultToStringResult(result ?? INVENTORY_RESULT.FAILURE)
    }
    func disableRFID()
    {
        RfidUtils.setRFIDScannerConnected(enabled: false)
        RfidUtils.setRFIDScannerEnabled(enabled: false)
        rfidClient?.removeDelegate(self)
    }
    func EventInventorySessionDidOpen(withSessionId: String, isSessionOwner: Bool)
    {
        let data = [
            "type": "sessionID",
            "sessionID": withSessionId
            ] as [String : Any]
        updateRfidData(data: data)
    }
    func EventInventoryDidReadTag(_ epc: String)
    {
        let data = [
            "type": "epc",
            "epc": epc
            ] as [String : Any]
        updateRfidData(data: data)
    }
    
    func EventInventorySessionDidCommit()
    {
    }
    
    func EventInventorySessionDidClose()
    {
    }
    
    //find product changes here
    func openLocatingSession(data: NSDictionary)-> String{
        let upcList = (data["upcList"] as? [String]) ?? [];
        
        let result = rfidClient?.getFindProductWorkerInstance()?.openFindProductSession(upcList)
        if(result == FIND_PRODUCT_RESULT.SUCCESS)
        {
            isLocatingSessionOpen = true
            isInventorySessionOpen = false
            rfidClient?.enableBarcodeReader(enable: false)
        }
        return RfidUtils.TranslateResultToStringResult(result ?? FIND_PRODUCT_RESULT.FAILURE)
    }
    
    func closeLocatingSession()-> String{
        isLocatingSessionOpen = false;
        let result = rfidClient?.getFindProductWorkerInstance()?.closeFindProductSession()
        if(result == FIND_PRODUCT_RESULT.SUCCESS)
        {
            rfidClient?.enableBarcodeReader(enable: true)
        }
        return RfidUtils.TranslateResultToStringResult(result ?? FIND_PRODUCT_RESULT.FAILURE)
    }
    
    func findNextTag()-> String{
        let result = rfidClient?.getFindProductWorkerInstance()?.findNextTag()
        return RfidUtils.TranslateResultToStringResult(result ?? FIND_PRODUCT_RESULT.FAILURE)
    }
    
    func startTagLocating(){
        let result = rfidClient?.getFindProductWorkerInstance()?.startFindProduct()
        if result == FIND_PRODUCT_RESULT.SUCCESS{
            isLocating = true;
        }
    }
    func stopTagLocating(){
        rfidClient?.getFindProductWorkerInstance()?.stopFindProduct()
        isLocating = false;
    }
    
    func EventScannerBarcode(_ barcode: String, barcodeType: String) {
        updateBarcodeData(barcode: barcode)
    }
    
    func EventFindProductDidLocateTag(tag: TagInfo, proximityPercent: Int) {
        if isLocating{
            let data = [
                "type": "tag",
                "epc": tag.epc,
                "upc": tag.upc,
                "proximityPercent": proximityPercent
                ] as [String : Any]
            updateRfidData(data: data)
        }
    }
}
