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
    var isBCScannerEnable = false;
    var isBCScanInProgress = false;
    var isINVScanInProgress = false;
    var isFPScanInProgress = false;
    var isSledSoundMute = false;
    let defaults = UserDefaults.standard
    
    
    var isProximityChanged = true;
    var oldBucket:bucketType = bucketType.None
    var newBucket:bucketType = bucketType.None
    var inclFPRangeBucket = false;
    var returnOnBucketChange = false;// if set true, return callback when there is change in range bucket. this help reduces # of callback
    
    var OutOfRange:(Int,Int)!
    var BarelyInRange: (Int,Int)!
    var Far : (Int,Int)!
    var Near: (Int,Int)!
    var VeryNear : (Int,Int)!
    var RightOnTop : (Int,Int)!
    var count = 0;
    
    var oldTagCount = 0;
    var firstTimeUpdate = true;
    
    
    private var RangeDefinition:[bucketType: (Int,Int)] = [
        bucketType.OutOfRange:(0, 0),
        bucketType.BarelyInRange:(1,10),
        bucketType.Far :(11,29),
        bucketType.Near : (30,54),
        bucketType.VeryNear:(55,62),
        bucketType.RightOnTop:(63,100)]
    
    
    func sendRfidResponse(data: [String : Any])
    {
        let jsonData = try! JSONSerialization.data(withJSONObject: data, options: [])
        let  rfidData = String(data: jsonData, encoding: String.Encoding.utf8) ?? ""
        if let viewController:ViewController = UIApplication.shared.keyWindow?.rootViewController as? ViewController
        {
            viewController.sendRfidResponse(rfidData:rfidData);
        }
    }
    
    func handleAppTimeOut(){
        stopInventory()
        stopTagLocating()
        
    }
    
    
    func enableRFID() -> String
    {
        var result = rfidClient.establishConnection()
        if result == .SUCCESS{
            rfidClient.addDelegate(self)
            
            //TODO: remove this when using zebraSDK
            RfidSoundManager.init()
            RfidSoundManager.isEnable = true;
            
        }
        return RfidUtils.TranslateResultToStringResult(result);
    }
    
    
    
    func disableRFID()
    {
        rfidClient.removeDelegate(self)
        rfidClient.closeConnection()
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
    //session value : 0,1,2 or 3
    func setRfidReaderSession( data: NSDictionary) -> String {
        var result = RFID_RESULT.FAILURE
        if let session = (data["session"] as? Int){
            switch( session){
            case 0: result = rfidClient.setReaderSession(.S0)
            defaults.set(READER_SESSION.S0.rawValue, forKey: CONST_SLED_SESSION)
            case 1: result = rfidClient.setReaderSession(.S1)
            defaults.set(READER_SESSION.S1.rawValue, forKey: CONST_SLED_SESSION)
            case 2: result = rfidClient.setReaderSession(.S2)
            defaults.set(READER_SESSION.S2.rawValue, forKey: CONST_SLED_SESSION)
            case 3: result = rfidClient.setReaderSession(.S3)
            defaults.set(READER_SESSION.S3.rawValue, forKey: CONST_SLED_SESSION)
            default: break;
            }
        }
        defaults.synchronize()
        return RfidUtils.TranslateResultToStringResult(result)
    }
    
    //rfidPower value: 0-100
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
                defaults.set(VOLUME_LEVEL.MUTE.rawValue, forKey: CONST_SLED_VOLUME)
                
            case "low":
                result = rfidClient.setReaderVolume(.LOW);
                defaults.set(VOLUME_LEVEL.LOW.rawValue, forKey: CONST_SLED_VOLUME)
            case "medium":
                result = rfidClient.setReaderVolume(.MEDIUM);
                defaults.set(VOLUME_LEVEL.MEDIUM.rawValue, forKey: CONST_SLED_VOLUME)
            case "high":
                result = rfidClient.setReaderVolume(.HIGH);
                defaults.set(VOLUME_LEVEL.HIGH.rawValue, forKey: CONST_SLED_VOLUME)
            default:
                return RfidUtils.TranslateResultToStringResult(RFID_RESULT.INVALID_PARAMS)
            }
        }
        defaults.synchronize()
        return RfidUtils.TranslateResultToStringResult(result)
        
    }
    
    func getRfidDeviceStatus() -> String {
        var data = DeviceStatus();
        if let result = rfidClient.getReaderStatus(){
            data = result;
        }
        let rfidDeviceStatus = [
            "batteryLevel": data.batteryLevel,
            "deviceId": data.deviceId,
            "isConnected": data.isConnected,
            "readerRfidPower": data.readerRfidPower,
            "readerSession": data.readerSession.hashValue,
            "volume": data.volume,
            "readerMode": data.readerMode.hashValue
            ] as [String : Any]
        
        let jsonData = try! JSONSerialization.data(withJSONObject: rfidDeviceStatus, options: [])
        let rfidData = String(data: jsonData, encoding: String.Encoding.utf8) ?? ""
        return rfidData;
    }
    
    func isRfidScannerAvailable() -> Bool {
        return rfidClient.getReaderStatus()?.isConnected ?? false;
    }
    func getBatteryLevel() -> String {
        return String(rfidClient.getReaderStatus()?.batteryLevel ?? 0 );
    }
    
    //MARK: FIND PRODUCT SOUND HANDLER
    //special handling case for FP sounds since Tyco SDK FP
    //issue: sled is beeping around rfid tags even though none of the tag is belong to the list
    //solution: mute the sound and unmute when FP locked on something
    
    internal func mute(){
        //mute sled volume
        if(!isSledSoundMute){
            if let oldVol = rfidClient.getReaderStatus()?.volume{
                defaults.set(oldVol, forKey: CONST_SLED_VOLUME)
                defaults.synchronize()
                
                if (rfidClient.setReaderVolume(.MUTE) == .SUCCESS){
                    isSledSoundMute = true;
                }
            }
        }
    }
    //restore sled volume
    internal func unmute() {
        if(isSledSoundMute){
            if let vol = VOLUME_LEVEL.init(rawValue: defaults.integer(forKey: CONST_SLED_VOLUME)){
                print("unmute -> \(vol.rawValue)")
                if(rfidClient.setReaderVolume(vol) == .SUCCESS){
                    isSledSoundMute = false;
                    defaults.synchronize()
                }
            }
        }
    }
    
    //MARK: FIND PRODUCT WORKFLOW
    
    //TO BE FILL IN
    func openTagLocatingSession(data: NSDictionary)-> String{
        let upcList = (data["upcList"] as? [String]) ?? [];
        
        returnOnBucketChange = (data["onBucketChange"] as? Bool) ?? false;
        print("openTagLocatingSession  size= \(upcList.count)")
        let result = rfidClient.findProductWorker?.openFindProductSession(upcList)
        
        //handle FP sounds. this can be removed when eliminating Tyco SDK
        mute()
        //end
        
        return RfidUtils.TranslateResultToStringResult(result ?? FIND_PRODUCT_RESULT.FAILURE)
        
    }
    
    func startTagLocating() -> String{
        if let result = rfidClient.findProductWorker?.startFindProduct(){
            if result == .SUCCESS {
                isFPScanInProgress = true;
                if let delegate = UIApplication.shared.delegate as? AppDelegate
                {
                    delegate.disableAppIdle(true)
                }
            }
            return RfidUtils.TranslateResultToStringResult(result)
        }
        return RfidUtils.TranslateResultToStringResult(FIND_PRODUCT_RESULT.FAILURE)
    }
    
    func findNextTag()-> String{
        let result = rfidClient.findProductWorker?.findNextTag()
        RfidSoundManager.StopAllSounds()
        return RfidUtils.TranslateResultToStringResult(result ?? FIND_PRODUCT_RESULT.FAILURE)
    }
    
    func stopTagLocating() -> String{
        if let result = rfidClient.findProductWorker?.stopFindProduct(){
            if result == .SUCCESS {
                isFPScanInProgress = false;
                
                RfidSoundManager.StopAllSounds()
                if let delegate = UIApplication.shared.delegate as? AppDelegate
                {
                    delegate.disableAppIdle(false)
                }
            }
            return RfidUtils.TranslateResultToStringResult(result)
        }
        return RfidUtils.TranslateResultToStringResult(FIND_PRODUCT_RESULT.FAILURE)
    }
    
    func closeTagLocatingSession()-> String{
        let result = rfidClient.findProductWorker?.closeFindProductSession()
        RfidSoundManager.StopAllSounds()
        self.unmute()
        
        
        return RfidUtils.TranslateResultToStringResult(result ?? FIND_PRODUCT_RESULT.FAILURE)
    }
    
    func enableBarcodeReader(enable:Bool ) -> String{
        let result =  rfidClient.enableBarcodeReader(enable: true)
        isBCScannerEnable = result == .SUCCESS ? enable : false
        return RfidUtils.TranslateResultToStringResult(result)
    }
    
    //MARK:  BARCODE SCANNER WORKFLOW
    func startScanningBarcode(){
        let result = rfidClient.startScanningBarcode()
        isBCScanInProgress = result == .SUCCESS ? true : false
    }
    
    func stopScanningBarcode(){
        // stop scanning for barcode and disable barcode reader
        let result = rfidClient.stopScanningBarcode();
        isBCScanInProgress = false;
    }
    
    
    //MARK: INVENTORY WORKFLOW
    func openInventorySession(data:NSDictionary) -> String{
        let tableName = (data["tableName"] as? String) ?? "";
        oldTagCount = 0 ;
        if(tableName != "")
        {
            var result = rfidClient.inventoryWorker?.openInventorySession(withTableName: tableName)
            
            if result == INVENTORY_RESULT.SUCCESS{
                mute()
                
                firstTimeUpdate = true;
            }
            
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
        if let result = rfidClient.inventoryWorker?.startInventory(){
            if result == .SUCCESS {
                isINVScanInProgress = true;
                if let delegate = UIApplication.shared.delegate as? AppDelegate
                {
                    delegate.disableAppIdle(true)
                }
            }
            return RfidUtils.TranslateResultToStringResult(result)
        }
        return RfidUtils.TranslateResultToStringResult(INVENTORY_RESULT.FAILURE)
    }
    
    func stopInventory() -> String {
        if let result = rfidClient.inventoryWorker?.stopInventory(){
            if result == .SUCCESS {
                isINVScanInProgress = false;
                if let delegate = UIApplication.shared.delegate as? AppDelegate
                {
                    delegate.disableAppIdle(false)
                }
            }
            return RfidUtils.TranslateResultToStringResult(result)
        }
        return RfidUtils.TranslateResultToStringResult(INVENTORY_RESULT.FAILURE)
    }
    
    func closeInventorySession() -> String {
        unmute()
        let result = rfidClient.inventoryWorker?.closeInventorySession()
        return RfidUtils.TranslateResultToStringResult(result ?? INVENTORY_RESULT.FAILURE)
    }
    
    
    func playBeepSound(){
        RfidSoundManager.playBeepSound();
        
    }
    func playScanBeepSound(){
        RfidSoundManager.playScanBeepSound();
        
    }
    
    private func GetBucketType(p_rssi:Int ) -> bucketType{
        
        if(isProximityChanged){
            OutOfRange = RangeDefinition[bucketType.OutOfRange]
            BarelyInRange = RangeDefinition[bucketType.BarelyInRange]
            Far = RangeDefinition[bucketType.Far]
            Near = RangeDefinition[bucketType.Near]
            VeryNear = RangeDefinition[bucketType.VeryNear]
            RightOnTop = RangeDefinition[bucketType.RightOnTop]
            isProximityChanged = false
        }
        
        if(RightOnTop?.0)! <= p_rssi{
            return bucketType.RightOnTop
        }
        else if(VeryNear?.0)! <= p_rssi{
            return bucketType.VeryNear
        }
        else if(Near?.0)! <= p_rssi{
            return bucketType.Near
        }
        else if(Far?.0)! <= p_rssi{
            return bucketType.Far
        }
        else if(BarelyInRange?.0)! <= p_rssi{
            return bucketType.BarelyInRange
        }
        else { return bucketType.OutOfRange
        }
        
        
    }
    
    //MARK: PROTOCOL FUNCTIONS
    
    func EventTriggerNotify(pressed: Bool) {
        //automatically wire trigger to barcode scanner if it is enable
        if isBCScannerEnable {
            if pressed { startScanningBarcode()}
            else {stopScanningBarcode()}
        }
        
        let data = [
            "type": "EventTriggerNotify",
            "pressed": pressed
            ] as [String : Any]
        sendRfidResponse(data: data)
    }
    
    func EventInventorySessionDidOpen(_ isSuccess: Bool, withSessionId: String, isSessionOwner: Bool) {
        //reset old tag count for sound purpose
        if isSuccess {
            oldTagCount = 0;
        }
        
        let data = [
            "type": "EventInventorySessionDidOpen",
            "status": isSuccess,
            "sessionID": withSessionId,
            "sessionOwner": isSessionOwner
            ] as [String : Any]
        sendRfidResponse(data: data)
    }
    
    func EventInventoryDidReadTag(_ epc: String){
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
        if let delegate = UIApplication.shared.delegate as? AppDelegate
        {
            delegate.updateBarcodeData(barcode: barcode)
        }
        
        let data = [
            "type": "EventScannerBarcode",
            "barcode": barcode,
            "barcodeType" : barcodeType
            ] as [String : Any]
        sendRfidResponse(data: data)
    }
    
    func EventFindProductDidLocateTag(tag: TagInfo, proximityPercent: Int) {
        
        newBucket = GetBucketType(p_rssi: proximityPercent);
        //handle FP sounds. this can be removed when eliminating Tyco SDK
        let _ = isFPScanInProgress ?  RfidSoundManager.playSound(bucket: newBucket) : RfidSoundManager.StopAllSounds()
        var date = Date()
        
        var data = [
            "type": "EventFindProductDidLocateTag",
            "upc": tag.upc,
            "epc": tag.epc,
            "proximity": proximityPercent,
            "rangeBucket": "\(newBucket)",
            ] as [String : Any]
        
        if returnOnBucketChange {
            if oldBucket.hashValue != newBucket.hashValue {
                oldBucket = newBucket;
                DispatchQueue.global(qos: .background).async {
                    
                    print("upc: \(tag.upc) Proximity: \(proximityPercent) bucket: \(data["rangeBucket"])")
                    self.sendRfidResponse(data: data)
                }
            }
            
        }
        else{
            DispatchQueue.global(qos: .background).async {
                print("Proximity: \(proximityPercent)")
                self.sendRfidResponse(data: data)
            }
        }
        
    }
    
    func EventUserDidAuthenticate(_ isSuccess: Bool) {
        let data = [
            "type": "EventUserDidAuthenticate",
            "status": isSuccess
            ] as [String : Any]
        sendRfidResponse(data: data)
    }
    
    func EventInventoryLocalTagCountDidChange(localTagCount: Int) {
        
        //play scan beep
        if oldTagCount != localTagCount && !firstTimeUpdate{
            RfidSoundManager.playScanBeepSound()
        }
        oldTagCount = localTagCount;
        firstTimeUpdate = false;
        
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
