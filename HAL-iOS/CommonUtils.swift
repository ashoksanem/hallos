//
//  CommonUtils.swift
//  HAL-iOS
//
//  Created by VAMSHI BOMMAVARAM on 10/13/16.
//  Copyright © 2016 macys. All rights reserved.
//

import Foundation
import UIKit

class CommonUtils
{
    static let autoLogout = "autoLogout";
    static let divNum = "divNumber";
    static let storeNum = "storeNumber";
    static let isPreProdEnv = "isPreProdEnv";
    static let ssoSignedInKey = "ssoSignedInKey";
    static let ssoAssociateInfo = "ssoAssociateInfo";
    static let currentPage = "currentPage";
    static let allowScan = "allowScan";
    static let landingPage = "com.apple.configuration.managed";
    static let deviceId = "deviceId";
    static let printerMACAddress = "printerMACAddress";
    static let isPrinterCPCL = "isCPCL";
    static let scannerEnabledCallback = "scannerEnabledCallback";
    static let scannerScanCallback = "scannerScanCallback";
    static let zipCode = "zipCode";
    
    
    class func setUpUserDefaults() -> Void
    {
        let defaults = UserDefaults.standard
        defaults.setValue(false, forKey: ssoSignedInKey);
        defaults.setValue(false, forKey: allowScan);
        defaults.setValue([:], forKey: ssoAssociateInfo);
        defaults.setValue("", forKey: currentPage);
        defaults.setValue("-1", forKey: divNum);
        defaults.setValue("-1", forKey: storeNum);
        defaults.setValue("", forKey: scannerEnabledCallback);
        defaults.setValue("", forKey: scannerScanCallback);
        
        //BJD No, this isn't perfet. It needs to be stored persistently where others can't easily overwrite it. That functionality is coming in
        //SDF-208 so hopefully this will suffice for now. I'll come back and fix it later.
        var uuid = "";
        /*if( UIPasteboard.general.string != "" && UIPasteboard.general.string?.lengthOfBytes(using: String.Encoding.utf8) == 36 ) {
            uuid = UIPasteboard.general.string!;
        }
        else {
            uuid = UUID().uuidString;
            UIPasteboard.general.string = uuid;
        }
        
        print(uuid.lengthOfBytes(using: String.Encoding.utf8));
        
        defaults.setValue(["deviceId":uuid], forKey: deviceId);*/
        if !(KeychainWrapper.standard.hasValue(forKey: deviceId)){
            uuid = UUID().uuidString;
            KeychainWrapper.standard.set(["deviceId":uuid] as NSCoding, forKey: deviceId)
        }
    }
    
    class func isSSOAuthenticated() -> Bool
    {
        let defaults = UserDefaults.standard
        return defaults.bool(forKey: ssoSignedInKey)
    }
    
    class func isScanEnabled() -> Bool
    {
        let defaults = UserDefaults.standard
        return defaults.bool(forKey: allowScan)
    }
    class func setScanEnabled(value: Bool)
    {
        let defaults = UserDefaults.standard
        defaults.set(value, forKey: allowScan)
       
        print(value)
    }
    
    class func isCPCLPrinter() -> Bool
    {
        let defaults = UserDefaults.standard
        return defaults.bool(forKey: isPrinterCPCL)
    }
    
    class func setCPCLPrinter(value: Bool)
    {
        let defaults = UserDefaults.standard
        defaults.set(value, forKey: isPrinterCPCL)
    }
    
    class func isSSOAuthenticatedMessage() -> String {
        
        let defaults = UserDefaults.standard
        let associate = defaults.dictionary(forKey: ssoAssociateInfo)! as [String:Any];
        
        let associateData = try! JSONSerialization.data(withJSONObject: associate, options: [])
        let associateString = String(data: associateData, encoding: String.Encoding.utf8)
        return associateString!;
    }
    
    class func setAuthServiceUnavailableInfo(assocNbr: String) -> Void {
        let authMessage = [
            "associateInfo":[
            "associateName": " ",
            "associateNbr": assocNbr,
            "managerLevel": 1
            ] ]as [String : Any]
        CommonUtils.setIsSSOAuthenticated(value: true)
        let defaults = UserDefaults.standard
        defaults.setValue(authMessage, forKey: ssoAssociateInfo)
    }
    
    class func setIsSSOAuthenticated(value: Bool) -> Void
    {
        let defaults = UserDefaults.standard
        defaults.setValue(value, forKey: ssoSignedInKey)
        
        if( value == false ) {
            defaults.setValue([:], forKey: ssoAssociateInfo)
        }
    }
    
    class func setLandingPage(value: URL) -> Void {
        let defaults = UserDefaults.standard
        defaults.set(value, forKey: landingPage)
    }
    
    class func getLandingPage() -> URL
    {
        let defaults = UserDefaults.standard
        if let landingPageDict = defaults.dictionary(forKey: landingPage)  {
            if let landingPage = landingPageDict["landingPage"] {
                return URL(string: landingPage as! String)!
            }
        }
        //return defaults.url(forKey: landingPage)!
        return URL(string: "http://www.macys.com")!;
    }
    
    class func setCurrentPage(value: URL) -> Void
    {
        let defaults = UserDefaults.standard
        defaults.set(value, forKey: currentPage)
        //defaults.setValue(value, forKey: currentPage)
    }
    
    class func getCurrentPage() -> URL
    {
        let defaults = UserDefaults.standard
        return defaults.url(forKey: currentPage)!
    }
    
    class func setSSOData(value: Data) -> Void
    {
        let json = JSON(data: value)
        let ssoJsonObject : Json4Swift_Base = Json4Swift_Base(dictionary: json)!
        
        print(ssoJsonObject);
        
        let defaults = UserDefaults.standard

        if( ssoJsonObject.error?.errorCode == 0 )
        {
            CommonUtils.setIsSSOAuthenticated(value: true)
            defaults.setValue(ssoJsonObject.dictionaryRepresentation(), forKey: ssoAssociateInfo)
        }
        else
        {
            CommonUtils.setIsSSOAuthenticated(value: false)
            defaults.setValue([:], forKey: ssoAssociateInfo)
        }
    }

    class func getDeviceId() -> String
    {
        //let defaults = UserDefaults.standard;
        //let device = defaults.dictionary(forKey: deviceId)! as [String:Any];
        let device = KeychainWrapper.standard.object(forKey: deviceId) as! [String:Any];
        
        let deviceData = try! JSONSerialization.data(withJSONObject: device, options: [])
        let deviceString = String(data: deviceData, encoding: String.Encoding.utf8)
        return deviceString!;
    }

    class func getSSOData() -> [String:Any]
    {
        let defaults = UserDefaults.standard
        return defaults.value(forKey: ssoAssociateInfo) as! [String:Any]
    }
    
    class func getAutoLogoutTimeinterval() -> Int
    {
        let defaults = UserDefaults.standard
        if( defaults.integer(forKey: autoLogout)==0)
        {
            return 1200;
        }

        return defaults.integer(forKey: autoLogout);
    }
    
    class func setAutoLogoutTimeinterval(value: Int)
    {
        let defaults = UserDefaults.standard
        defaults.set(value, forKey: autoLogout)
    }
    
    class func setDivNum(value: Int)
    {
        let defaults = UserDefaults.standard
        defaults.set(value, forKey: divNum)
    }
    
    class func setStoreNum(value: Int)
    {
        let defaults = UserDefaults.standard
        defaults.set(value, forKey: storeNum)
    }
    class func setZipCode(value: String)
    {
        let defaults = UserDefaults.standard
        defaults.set(value, forKey: zipCode)
    }
    class func GetZipCode() -> String
    {
        var count=0;
        while (UserDefaults.standard.value(forKey: zipCode)==nil && count<5) {
            let esp = ESPRequest()
            esp.getZipCode()
            count=count+1;
        }
        if(UserDefaults.standard.value(forKey: zipCode)==nil)
        {
        return "";
        }
        else{
        return UserDefaults.standard.value(forKey: zipCode) as! String;
        }
        
    }
    class func getDivNum() -> Int
    {
        let defaults = UserDefaults.standard;
        print(defaults.integer(forKey: divNum))
        return defaults.integer(forKey: divNum)
        //return 71;
    }
    
    class func getStoreNum() -> Int
    {
        let defaults = UserDefaults.standard;
        return defaults.integer(forKey: storeNum);
        //return 166;
    }
    class func setPrinterMACAddress(value: String)
    {
        let defaults = UserDefaults.standard
        defaults.set(value, forKey: printerMACAddress)
    }
    
    class func setPreProdEnv(value: Bool)
    {
        let defaults = UserDefaults.standard
        defaults.set(value, forKey: isPreProdEnv)
    }
    
    class func getPrinterMACAddress() -> String
    {
        let defaults = UserDefaults.standard
        if let macAddress = defaults.value(forKey: printerMACAddress)
        {
            return macAddress as! String
        }

        return ""
    }
    
    class func setScannerEnabledCallback(value: String)
    {
        let defaults = UserDefaults.standard;
        defaults.set(value, forKey: scannerEnabledCallback);
    }
    
    class func getScannerEnabledCallback() -> String
    {
        let defaults = UserDefaults.standard;
        return defaults.value(forKey: scannerEnabledCallback) as! String;
    }
    
    class func setScannerScanCallback(value: String)
    {
        let defaults = UserDefaults.standard;
        defaults.set(value, forKey: scannerScanCallback);
    }
    
    class func getScannerScanCallback() -> String
    {
        let defaults = UserDefaults.standard;
        return defaults.value(forKey: scannerScanCallback) as! String;
    }
    
    class func getLocationInformation() -> String
    {
        let defaults = UserDefaults.standard;
        
        let locationInformation = [
            "locationInformation":[
                "divInfo": ["num":defaults.string(forKey: divNum)],
                "storeInfo": ["num":defaults.string(forKey: storeNum)],
                "zipCode": GetZipCode()
            ] ]as [String : Any];
        
        let data = try! JSONSerialization.data(withJSONObject: locationInformation, options: [])
        let string = String(data: data, encoding: String.Encoding.utf8)
        return string!;
    }
}
