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
    var isBarcodeEnable = false;

    
    func sendRfidResponse(data: [String : Any])
    {
        let jsonData = try! JSONSerialization.data(withJSONObject: data, options: [])
        let  rfidData = String(data: jsonData, encoding: String.Encoding.utf8) ?? ""
        if let viewController:ViewController = UIApplication.shared.keyWindow?.rootViewController as? ViewController
        {
            viewController.sendRfidResponse(rfidData:rfidData);
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
    


    
    func establishComm(data:NSDictionary, completion: ((Bool) -> Void)? ){
        let server = (data["rfidServer"] as? String) ?? "";
        let port = (data["port"] as? Int) ?? -1;
        
        rfidClient.EstablishComm(hostname: server, port: port, completion: {response -> Void in
            print(response)
            completion!( response);
        })
    }
    
    
    //MARK: UTILITIES
    //0-100
    func setRfidPowerLevel( data: NSDictionary) -> String{
        var result = RFID_RESULT.FAILURE
        if let power = (data["rfidPower"] as? Int){
            result = rfidClient.setPowerLevel(power: power)
        }
        return RfidUtils.TranslateResultToStringResult(result)
    }
    
    //mute-low-medium-high
    func setVolumeLevel(data:NSDictionary) -> String {
        var result = RFID_RESULT.FAILURE
        if let vol = (data["rfidVolume"] as? String){
            switch vol {
                case "mute":
                    result = rfidClient.setReaderVolume(.MUTE);
            case "low":
                result = rfidClient.setReaderVolume(.LOW);
            case "medium":
                result = rfidClient.setReaderVolume(.MEDIUM);
            case "high":
                result = rfidClient.setReaderVolume(.HIGH);
            default:
                return RfidUtils.TranslateResultToStringResult(RFID_RESULT.INVALID_PARAMS)
            }
        }
           return RfidUtils.TranslateResultToStringResult(result)
        
    }
    
    func getRfidDeviceStatus() -> String {
        var data = DeviceStatus();
        if let result = rfidClient.getReaderStatus(){
            data = result;
        }
        let jsonData = try! JSONSerialization.data(withJSONObject: data, options: [])
        let rfidData = String(data: jsonData, encoding: String.Encoding.utf8) ?? ""
        return rfidData;
    }
    
    
    //MARK: FIND PRODUCT WORKFLOW
    
    //TO BE FILL IN
    func openTagLocatingSession(data: NSDictionary)-> String{
        let upcList = (data["upcList"] as? [String]) ?? [];
        let result = rfidClient.findProductWorker?.openFindProductSession(upcList)
        return RfidUtils.TranslateResultToStringResult(result ?? FIND_PRODUCT_RESULT.FAILURE)
    }
    func startTagLocating() -> String{
        let result = rfidClient.findProductWorker?.startFindProduct()
        return RfidUtils.TranslateResultToStringResult(result ?? FIND_PRODUCT_RESULT.FAILURE)
    }
    func findNextTag()-> String{
        let result = rfidClient.findProductWorker?.findNextTag()
        return RfidUtils.TranslateResultToStringResult(result ?? FIND_PRODUCT_RESULT.FAILURE)
    }
    func stopTagLocating() -> String{
        let result = rfidClient.findProductWorker?.stopFindProduct()
        return RfidUtils.TranslateResultToStringResult(result ?? FIND_PRODUCT_RESULT.FAILURE)
    }
    func closeTagLocatingSession()-> String{
        let result = rfidClient.findProductWorker?.closeFindProductSession()
        return RfidUtils.TranslateResultToStringResult(result ?? FIND_PRODUCT_RESULT.FAILURE)
    }
    

    //MARK:  BARCODE SCANNER WORKFLOW
    func startScanningBarcode(){
        //enable barcode reader if disable, then start scanning for barcode
        let result =  rfidClient.enableBarcodeReader(enable: true)
        if result == .SUCCESS {rfidClient.startScanningBarcode()}
    }
    
    func stopScanningBarcode(){
        // stop scanning for barcode and disable barcode reader
        rfidClient.stopScanningBarcode();
        rfidClient.enableBarcodeReader(enable: false)

    }

    
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
            "type": "EventTriggerNotify",
            "pressed": pressed
            ] as [String : Any]
        sendRfidResponse(data: data)
    }
    
    
    
    func EventInventorySessionDidOpen(_ isSuccess: Bool, withSessionId: String, isSessionOwner: Bool) {
        let data = [
            "type": "EventInventorySessionDidOpen",
            "status": isSuccess,
            "sessionID": withSessionId,
            "sessionOwner": isSessionOwner
            ] as [String : Any]
        sendRfidResponse(data: data)
    }
    
    func EventInventoryDidReadTag(_ epc: String)
    {
        let data = [
            "type": "EventInventoryDidReadTag",
            "epc": epc
            ] as [String : Any]
        sendRfidResponse(data: data)
    }

    func EventInventorySessionDidCommit(_ isSuccess: Bool) {
        let data = [
            "type": "EventInventorySessionDidCommit",
            "status": isSuccess
            ] as [String : Any]
        sendRfidResponse(data: data)
    }
 
    func EventInventorySessionDidClose(_ isSuccess: Bool) {
        let data = [
            "type": "EventInventorySessionDidClose",
            "status": isSuccess
            ] as [String : Any]
        sendRfidResponse(data: data)
    }
    
    func EventScannerBarcode(_ barcode: String, barcodeType: String) {
        let data = [
            "type": "EventScannerBarcode",
            "barcode": barcode,
            "barcodeType" : barcodeType
            ] as [String : Any]
            sendRfidResponse(data: data)
    }

    func EventFindProductDidLocateTag(tag: TagInfo, proximityPercent: Int) {
        let data = [
            "type": "EventFindProductDidLocateTag",
            "upc": tag.upc,
            "epc": tag.epc,
            "proximity": proximityPercent
            ] as [String : Any]
        sendRfidResponse(data: data)
    }
    
    
    
    func EventUserDidAuthenticate(_ isSuccess: Bool) {
        let data = [
            "type": "EventUserDidAuthenticate",
            "status": isSuccess
            ] as [String : Any]
        sendRfidResponse(data: data)
    }
    

    func EventInventoryLocalTagCountDidChange(localTagCount: Int) {
        let data = [
            "type": "EventInventoryLocalTagCountDidChange",
            "localTagCount": localTagCount
            ] as [String : Any]
        sendRfidResponse(data: data)
    }
    func EventInventoryTotalTagCountDidChange(totalTagCount: Int) {
        let data = [
            "type": "EventInventoryTotalTagCountDidChange",
            "totalTagCount": totalTagCount
            ] as [String : Any]
        sendRfidResponse(data: data)
    }

    func EventInventoryUserCountChange(userCount: Int) {
        let data = [
            "type": "EventInventoryUserCountChange",
            "userCount": userCount
            ] as [String : Any]
        sendRfidResponse(data: data)
    }

}
