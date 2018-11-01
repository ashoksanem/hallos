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
    
    
    func EventInventoryLocalTagCountDidChange(localTagCount: Int) {
        let data = [
            "type": "InventoryLocalTagCount",
            "localTagCount": localTagCount
            ] as [String : Any]
        updateRfidData(data: data)
    }
    func EventInventoryTotalTagCountDidChange(totalTagCount: Int) {
        let data = [
            "type": "inventoryTotalTagCount",
            "totalTagCount": totalTagCount
            ] as [String : Any]
        updateRfidData(data: data)
    }
    
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
    
    func enableRFID() -> String
    {
        var result = rfidClient?.establishConnection()
        rfidClient?.addDelegate(self)
        return RfidUtils.TranslateResultToStringResult(result ?? RFID_RESULT.FAILURE);
    }
    
    
    
    
    func changeSessionMode(data: NSDictionary) -> String
    {
        let mode = (data["mode"] as? String) ?? "";
        let invWorkerInstance = rfidClient?.getInventoryWorkerInstance();
        if(invWorkerInstance != nil)
        {
            if(mode == CommonUtils.autoPlayMode )
            {
                var result = INVENTORY_RESULT.FAILURE;
                result =  (invWorkerInstance?.startInventory())!;
                if(result == INVENTORY_RESULT.SUCCESS)
                {
                    CommonUtils.setInventorySessionMode(mode: CommonUtils.autoPlayMode)
                }
                return RfidUtils.TranslateResultToStringResult(result)
            }
            else if(mode == CommonUtils.triggerMode )
            {
                CommonUtils.setInventorySessionMode(mode: CommonUtils.triggerMode)
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
        rfidClient?.addDelegate(self)
        let server = (data["rfidServer"] as? String) ?? "";
        let port = (data["port"] as? Int) ?? -1;
        let storeID = (data["storeID"] as? String) ?? "";
        let tableName = (data["tableName"] as? String) ?? "";
        if(server != "" && port != -1 && storeID != "" && tableName != "")
        {
            rfidClient?.EstablishComm(hostname: server, port: port, siteId: storeID)
            rfidClient?.setReaderSession(READER_SESSION.S2)
            var result = rfidClient?.getInventoryWorkerInstance()?.openInventorySession(withTableName: tableName)
            CommonUtils.setInventorySessionMode(mode: CommonUtils.triggerMode)
            return RfidUtils.TranslateResultToStringResult(result ?? INVENTORY_RESULT.FAILURE)
        }
        else
        {
            return "INVALID_INPUT";
        }
    }
    
    func EventTriggerNotify(pressed: Bool) {
        if(CommonUtils.getInventorySessionMode() == CommonUtils.triggerMode)
        {
            if pressed {
                let r = rfidClient?.getInventoryWorkerInstance()?.startInventory()
                print(r)
            }
            else {
                let r1 = rfidClient?.getInventoryWorkerInstance()?.stopInventory()
            }
        }
    }
    //save rfid session
    func closeRfidSession() -> String{
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
}
