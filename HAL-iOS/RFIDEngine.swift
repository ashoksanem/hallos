//
//  RFIDEngine.swift
//  HAL-iOS
//
//  Created by Minh Dang Le on 11/14/18.
//  Copyright © 2018 macys. All rights reserved.
//

import Foundation

import rfid_ios_fw

class RFIDEngine: NSObject, RfidSDKDelegate
{
    var rfidClient = RfidSDK.shared()
    

    
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
    
    func enableRFID() -> String
    {
        var result = rfidClient.establishConnection()
        if result == .SUCCESS{
            rfidClient.addDelegate(self)
        }
        return RfidUtils.TranslateResultToStringResult(result);
        
    }
    
    func disableRFID()
    {
        rfidClient.removeDelegate(self)
    }
    
    
    func EstablishComm(data:NSDictionary) -> String{
        let server = (data["rfidServer"] as? String) ?? "";
        let port = (data["port"] as? Int) ?? -1;
        if(server != "" && port != -1 )
        {
            rfidClient.EstablishComm(hostname: server, port: port, completion: {response -> Void in
                print(response)
            })
        }
        return "INVALID_INPUT";
    }

    
    //MARK: FIND PRODUCT WORKFLOW
    
    //TO BE FILL IN
    
    
    
    //MARK: INVENTORY WORKFLOW
    
    func openInventorySession(data:NSDictionary) -> String{
        let tableName = (data["tableName"] as? String) ?? "";
        if(tableName != "")
        {
            var result = rfidClient.inventoryWorker?.openInventorySession(withTableName: tableName)
            return RfidUtils.TranslateResultToStringResult(result ?? INVENTORY_RESULT.FAILURE)
        }
        else
        {
            return "INVALID_INPUT";
        }
    }

    
    func clearInventorySession() -> String{
        let result = rfidClient.inventoryWorker?.clearTags();
        return RfidUtils.TranslateResultToStringResult(result ?? INVENTORY_RESULT.FAILURE)
    }
    
    func saveInventorySession() -> String{

        var result = rfidClient.inventoryWorker?.commitInventorySession()
        return RfidUtils.TranslateResultToStringResult(result ?? INVENTORY_RESULT.FAILURE)
    }
    
    func startInventory() -> String{
        var result = rfidClient.inventoryWorker?.startInventory()
        return RfidUtils.TranslateResultToStringResult(result ?? INVENTORY_RESULT.FAILURE)
    }
    
    func stopInventory() -> String {
        var result = rfidClient.inventoryWorker?.stopInventory()
        return RfidUtils.TranslateResultToStringResult(result ?? INVENTORY_RESULT.FAILURE)
    }
    
    func closeInventorySession() -> String {
        let result = rfidClient.inventoryWorker?.closeInventorySession()
         return RfidUtils.TranslateResultToStringResult(result ?? INVENTORY_RESULT.FAILURE)
    }
    
    
    
    //MARK: PROTOCOL FUNCTIONS
    
    func EventTriggerNotify(pressed: Bool) {
        let data = [
            "event": "EventTriggerNotify",
            "pressed": pressed
            ] as [String : Any]
        updateRfidData(data: data)
    }

    
    func EventInventorySessionDidOpen(_ isSuccess: Bool, withSessionId: String, isSessionOwner: Bool) {
        let data = [
            "event": "EventInventorySessionDidOpen",
            "status": isSuccess,
            "sessionID": withSessionId,
            "sessionOwner": isSessionOwner
            ] as [String : Any]
        updateRfidData(data: data)
    }
    
    func EventInventoryDidReadTag(_ epc: String)
    {
        let data = [
            "event": "EventInventoryDidReadTag",
            "epc": epc
            ] as [String : Any]
        updateRfidData(data: data)
    }


    func EventInventorySessionDidCommit(_ isSuccess: Bool) {
        let data = [
            "event": "EventInventorySessionDidCommit",
            "status": isSuccess
            ] as [String : Any]
        updateRfidData(data: data)
    }
 
    func EventInventorySessionDidClose(_ isSuccess: Bool) {
        let data = [
            "event": "EventInventorySessionDidClose",
            "status": isSuccess
            ] as [String : Any]
        updateRfidData(data: data)
    }
    
    func EventScannerBarcode(_ barcode: String, barcodeType: String) {
        let data = [
            "event": "EventScannerBarcode",
            "barcode": barcode,
            "barcodeType": barcodeType
            ] as [String : Any]
        updateRfidData(data: data)
    }

    func EventFindProductDidLocateTag(tag: TagInfo, proximityPercent: Int) {
        let data = [
            "event": "EventFindProductDidLocateTag",
            "tag": tag,
            "proximity": proximityPercent
            ] as [String : Any]
        updateRfidData(data: data)
    }
    
    func EventUserDidAuthenticate(_ isSuccess: Bool) {
        let data = [
            "event": "EventUserDidAuthenticate",
            "status": isSuccess
            ] as [String : Any]
        updateRfidData(data: data)
    }
    
    func EventInventoryLocalTagCountDidChange(localTagCount: Int) {
        let data = [
            "event": "EventInventoryLocalTagCountDidChange",
            "localTagCount": localTagCount
            ] as [String : Any]
        updateRfidData(data: data)
    }
    func EventInventoryTotalTagCountDidChange(totalTagCount: Int) {
        let data = [
            "event": "EventInventoryTotalTagCountDidChange",
            "totalTagCount": totalTagCount
            ] as [String : Any]
        updateRfidData(data: data)
    }

    func EventInventoryUserCountChange(userCount: Int) {
        let data = [
            "event": "EventInventoryUserCountChange",
            "userCount": userCount
            ] as [String : Any]
        updateRfidData(data: data)
    }

}
