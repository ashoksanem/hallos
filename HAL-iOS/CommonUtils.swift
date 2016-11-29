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
    static let ssoSignedInKey = "ssoSignedInKey";
    static let ssoAssociateInfo = "ssoAssociateInfo";
    static let currentPage = "currentPage";
    static let allowScan = "allowScan";
    static let landingPage = "com.apple.configuration.managed";
    static let deviceId = "deviceId";
    static let printerMACAddress = "printerMACAddress";
    static let isPrinterCPCL = "isCPCL";
    class func setUpUserDefaults() -> Void
    {
        let defaults = UserDefaults.standard
        defaults.setValue(false, forKey: ssoSignedInKey);
        defaults.setValue([:], forKey: ssoAssociateInfo);
        defaults.setValue("", forKey: currentPage);
        
        //BJD No, this isn't perfet. It needs to be stored persistently where others can't easily overwrite it. That functionality is coming in
        //SDF-208 so hopefully this will suffice for now. I'll come back and fix it later.
        var uuid = "";
        if( UIPasteboard.general.string != "" && UIPasteboard.general.string?.lengthOfBytes(using: String.Encoding.utf8) == 36 ) {
            uuid = UIPasteboard.general.string!;
        }
        else {
            uuid = UUID().uuidString;
            UIPasteboard.general.string = uuid;
        }
        
        print(uuid.lengthOfBytes(using: String.Encoding.utf8));
        
        defaults.setValue(["deviceId":uuid], forKey: deviceId);
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

    class func setIsSSOAuthenticated(value: Bool) -> Void {
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
    
    class func getLandingPage() -> URL {
        let defaults = UserDefaults.standard
        if let landingPageDict = defaults.dictionary(forKey: landingPage)  {
            if let landingPage = landingPageDict["landingPage"] {
                return URL(string: landingPage as! String)!
            }
        }
        //return defaults.url(forKey: landingPage)!
        return URL(string: "http://www.macys.com")!;
    }
    
    class func setCurrentPage(value: URL) -> Void {
        let defaults = UserDefaults.standard
        defaults.set(value, forKey: currentPage)
        //defaults.setValue(value, forKey: currentPage)
    }
    
    class func getCurrentPage() -> URL {
        let defaults = UserDefaults.standard
        return defaults.url(forKey: currentPage)!
    }
    
    class func setSSOData(value: Data) -> Void {

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
    

    class func getDeviceId() -> String {
        let defaults = UserDefaults.standard;
        let device = defaults.dictionary(forKey: deviceId)! as [String:Any];
        
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
        else
        {
            return defaults.integer(forKey: autoLogout);
        }
    }
    class func setAutoLogoutTimeinterval(value: Int)
    {
        let defaults = UserDefaults.standard
        defaults.set(value, forKey: autoLogout)
        
        print(value)
        
    }
    class func setPrinterMACAddress(value: String)
    {
        let defaults = UserDefaults.standard
        defaults.set(value, forKey: printerMACAddress)
    }
    class func getPrinterMACAddress() -> String
    {
        let defaults = UserDefaults.standard
        return defaults.value(forKey: printerMACAddress) as! String
    }
   
}
