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
    static let locnNum = "locnNumber";
    static let isPreProdEnv = "isPreProdEnv";
    static let ssoSignedInKey = "ssoSignedInKey";
    static let ssoAssociateInfo = "ssoAssociateInfo";
    static let ssoAssociateTimestamp = "ssoAssociateTimestamp";
    static let currentPage = "currentPage";
    static let allowScan = "allowScan";
    static let scannerModeFromWeb = "scannerModeFromWeb";
    static let managedAppConfig = "com.apple.configuration.managed";
    static let landingPage = "landingPage";
    static let deviceId = "deviceId";
    static let printerMACAddress = "printerMACAddress";
    static let isPrinterCPCL = "isCPCL";
    static let scannerEnabledCallback = "scannerEnabledCallback";
    static let scannerScanCallback = "scannerScanCallback";
    static let zipCode = "zipCode";
    static let webviewLoading = "webviewLoading";
    static let commonLogMetrics = "getCommonLogMetrics";
    static let autoLogoutStartTime = "autoLogoutStartTime";
    static let allowMsr = "allowMsr";
    static let certificatePinningEnabled = "certificatePinningEnabled";
    static let savedPrinterMACAddress = "savedPrinterMACAddress";
    
    class func setUpUserDefaults() -> Void
    {
        let defaults = UserDefaults.standard
        defaults.setValue(false, forKey: ssoSignedInKey);
        defaults.setValue(false, forKey: allowScan);
        defaults.setValue([:], forKey: ssoAssociateInfo);
        defaults.setValue(nil, forKey: ssoAssociateTimestamp);
        defaults.setValue("", forKey: currentPage);
        defaults.setValue("-1", forKey: divNum);
        defaults.setValue("-1", forKey: storeNum);
        defaults.setValue("-1", forKey: locnNum);
        defaults.setValue("", forKey: scannerEnabledCallback);
        defaults.setValue("", forKey: scannerScanCallback);
        defaults.removeObject(forKey: LoggingRequest.metricsLog);
        defaults.removeObject(forKey: LogAnalyticsRequest.metricsLog);
        defaults.setValue(false, forKey: webviewLoading);
        defaults.setValue(false, forKey: certificatePinningEnabled)
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
            KeychainWrapper.standard.set(["deviceId":uuid] as NSCoding, forKey: deviceId);
        }
    }
    
    class func isSSOAuthenticated() -> Bool
    {
        let defaults = UserDefaults.standard;
        return defaults.bool(forKey: ssoSignedInKey);
    }
    
    class func isCertificatePinningEnabled() -> Bool
    {
        let defaults = UserDefaults.standard;
        return defaults.bool(forKey: certificatePinningEnabled);
    }
    
    class func setCertificatePinningEnabled(value: Bool)
    {
        let defaults = UserDefaults.standard;
        defaults.set(value, forKey: certificatePinningEnabled);
    }

    class func setEnableMsr(value: Bool)
    {
        let defaults = UserDefaults.standard;
        defaults.set(value, forKey: allowMsr);
    }
    
    class func isMsrEnabled() -> Bool
    {
        let defaults = UserDefaults.standard;
        return defaults.bool(forKey: allowMsr);
    }
    
    class func isScanEnabled() -> Bool
    {
        let defaults = UserDefaults.standard;
        return defaults.bool(forKey: allowScan);
    }
    
    class func setScanEnabled(value: Bool)
    {
        let defaults = UserDefaults.standard;
        defaults.set(value, forKey: allowScan);
    }
    class func isScannerModeEnabledFromWeb() -> Bool
    {
        let defaults = UserDefaults.standard;
        return defaults.bool(forKey: scannerModeFromWeb);
    }
    
    class func setScannerModeFromWeb(value: Bool)
    {
        let defaults = UserDefaults.standard;
        defaults.set(value, forKey: scannerModeFromWeb);
    }
    
    class func isCPCLPrinter() -> Bool
    {
        let defaults = UserDefaults.standard;
        return defaults.bool(forKey: isPrinterCPCL);
    }
    
    class func setCPCLPrinter(value: Bool)
    {
        let defaults = UserDefaults.standard;
        defaults.set(value, forKey: isPrinterCPCL);
    }
    
    class func isSSOAuthenticatedMessage() -> String {
        let defaults = UserDefaults.standard;
        let associate = (defaults.dictionary(forKey: ssoAssociateInfo))! as [String:Any];
        
        let associateData = try! JSONSerialization.data(withJSONObject: associate, options: []);

        let associateString = String(data: associateData, encoding: String.Encoding.utf8);
        var val = "";

        if( associate["associateInfo"] != nil )
        {
            val = "Currently logged in associate: " + String( describing:((associate["associateInfo"] as! NSDictionary)["associateNbr"]! as! String));
        }
        else
        {
            val = "Currently logged in associate: " + associateString!;
        }

        DLog( val );
        LoggingRequest.logData(name: LoggingRequest.metrics_info, value: val, type: "STRING", indexable: true);
        
        return associateString!;
    }
    
    class func setAuthServiceUnavailableInfo(assocNbr: String) -> Void {
        let authMessage = [
            "associateInfo":[
            "associateName": " ",
            "associateNbr": assocNbr,
            "managerLevel": 1
            ] ]as [String : Any];
        
        LoggingRequest.logData(name: LoggingRequest.metrics_warning, value: "Using offline associate info.", type: "STRING", indexable: true);
        
        Heap.track("AssociateAuthentication", withProperties:[AnyHashable("offlineAssociate"):"true",
                                                              AnyHashable("associateNumber"):assocNbr,
                                                              AnyHashable("divNum"):CommonUtils.getDivNum(),
                                                              AnyHashable("storeNum"):CommonUtils.getStoreNum()]);
        
        CommonUtils.setIsSSOAuthenticated(value: true);
        
        let defaults = UserDefaults.standard;
        defaults.setValue(authMessage, forKey: ssoAssociateInfo);
        defaults.setValue(Date(), forKey: ssoAssociateTimestamp);
    }
    
    class func setIsSSOAuthenticated(value: Bool) -> Void
    {
        let defaults = UserDefaults.standard;
        defaults.setValue(value, forKey: ssoSignedInKey);
        
        if( value == false ) {
            defaults.setValue([:], forKey: ssoAssociateInfo);
            defaults.setValue(nil, forKey: ssoAssociateTimestamp);
        }
    }
    
    class func setLandingPage(value: URL) -> Void {
        let defaults = UserDefaults.standard;
        defaults.set(value, forKey: landingPage);
    }
    
    class func getLandingPage() -> URL
    {
        let defaults = UserDefaults.standard;
        return defaults.url(forKey: landingPage)!;
    }
    
    class func setCurrentPage(value: URL) -> Void
    {
        let defaults = UserDefaults.standard;
        defaults.set(value, forKey: currentPage);
    }
    
    class func getCurrentPage() -> URL
    {
        let defaults = UserDefaults.standard;
        return defaults.url(forKey: currentPage)!;
    }

    class func getDeviceId() -> String
    {
        if let device = KeychainWrapper.standard.object(forKey: deviceId) as? [String:Any]
        {
            let deviceData = try! JSONSerialization.data(withJSONObject: device, options: [])
            let deviceString = String(data: deviceData, encoding: String.Encoding.utf8)
            return deviceString!;
        }

        return "";
    }

    class func getSSOData() -> [String:Any]
    {
        let defaults = UserDefaults.standard
        if(!((defaults.value(forKey: ssoAssociateInfo) as? [String:Any]) == nil))
        {
            return defaults.value(forKey: ssoAssociateInfo) as! [String:Any];
        }

        return [:];
    }
    
    class func getSSOTimestamp() -> Date?
    {
        let defaults = UserDefaults.standard
        if(!((defaults.value(forKey: ssoAssociateTimestamp) as? Date) == nil))
        {
            return defaults.value(forKey: ssoAssociateTimestamp) as? Date;
        }
        
        return nil;
    }
    
    class func getSSODuration() -> String
    {
        let loginTimestamp = getSSOTimestamp();
        if( loginTimestamp == nil ) {
            return "Unavailable";
        }
        
        let duration = NSInteger( Date().timeIntervalSince( CommonUtils.getSSOTimestamp()! ) );
        
        let seconds = duration % 60;
        let minutes = (duration / 60 ) % 60;
        let hours = (duration / 3600 );
        
        return String(format: "%0.2d:%0.2d:%0.2d", hours, minutes, seconds);
    }
    
    class func getCurrentAssociateNum() -> String {
        let associate = (UserDefaults.standard.dictionary(forKey: CommonUtils.ssoAssociateInfo))! as [String:Any];
        if( associate["associateInfo"] != nil ) {
            return String( describing: ( associate["associateInfo"] as! NSDictionary)["associateNbr"]! );
        }
        else {
            return "Unavailable";
        }
    }
    
    class func getAutoLogoutTimeinterval() -> Int
    {
        let defaults = UserDefaults.standard;
        
        if( defaults.integer(forKey: autoLogout) == 0)
        {
            return 1200;
        }

        return defaults.integer(forKey: autoLogout);
    }
    
    class func setAutoLogoutTimeinterval(value: Int)
    {
        let defaults = UserDefaults.standard;
        defaults.set(value, forKey: autoLogout);
    }
    
    class func setDivNum(value: Int)
    {
        let defaults = UserDefaults.standard;
        defaults.set(value, forKey: divNum);
    }
    
    class func setStoreNum(value: Int)
    {
        let defaults = UserDefaults.standard;
        defaults.set(value, forKey: storeNum);
    }
    
    class func setLocnNum(value: Int)
    {
        let defaults = UserDefaults.standard;
        defaults.set(value, forKey: locnNum);
    }
    
    class func setZipCode(value: String)
    {
        let defaults = UserDefaults.standard;
        defaults.set(value, forKey: zipCode);
    }
    
    class func GetZipCode() -> String
    {
        var count = 0;
     
        while (UserDefaults.standard.value(forKey: zipCode) == nil && count < 5) {
            let esp = ESPRequest();
            esp.getZipCode();
            count = count + 1;
        }
        
        if let zip = UserDefaults.standard.value(forKey: zipCode) as? String {
            return zip;
        }
        
        return "";
    }
    class func getDivNum() -> Int
    {
        let defaults = UserDefaults.standard;
        return defaults.integer(forKey: divNum);
    }
    
    class func getStoreNum() -> Int
    {
        let defaults = UserDefaults.standard;
        return defaults.integer(forKey: storeNum);
    }
    
    class func getLocnNum() -> Int
    {
        let defaults = UserDefaults.standard;
        return defaults.integer(forKey: locnNum);
    }
    
    class func setPrinterMACAddress(value: String)
    {
        let defaults = UserDefaults.standard;
        defaults.set(value, forKey: printerMACAddress);
    }
    
    class func setPreProdEnv(value: Bool)
    {
        let defaults = UserDefaults.standard;
        defaults.set(value, forKey: isPreProdEnv);
    }
    
    class func getPrinterMACAddress() -> String
    {
        let defaults = UserDefaults.standard
        if let macAddress = defaults.string(forKey: printerMACAddress)
        {
            return macAddress
        }

        return "";
    }
    
    class func setScannerEnabledCallback(value: String)
    {
        let defaults = UserDefaults.standard;
        defaults.set(value, forKey: scannerEnabledCallback);
    }
    
    class func getScannerEnabledCallback() -> String
    {
        let defaults = UserDefaults.standard;
        if(defaults.string(forKey: scannerEnabledCallback) == nil)
        {
            return ""
        }
        
        return defaults.string(forKey: scannerEnabledCallback)!;
    }
    
    class func setScannerScanCallback(value: String)
    {
        let defaults = UserDefaults.standard;
        defaults.set(value, forKey: scannerScanCallback);
    }
    
    class func getScannerScanCallback() -> String
    {
        let defaults = UserDefaults.standard;
        if((defaults.value(forKey: scannerScanCallback) as? String) == nil)
        {
            return "";
        }
        
        return defaults.value(forKey: scannerScanCallback) as! String;
    }
    
    class func getLocationInformation() -> String
    {
        let defaults = UserDefaults.standard;

        if((defaults.string(forKey: divNum) == nil) || (defaults.string(forKey: storeNum) == nil) || (defaults.string(forKey: locnNum) == nil) )
        {
            return "";
        }
        else
        {
            let locationInformation = [
                "locationInformation":[
                    "divInfo": ["num":defaults.string(forKey: divNum)] as Any,
                    "storeInfo": ["num":defaults.string(forKey: storeNum) as Any,
                                  "zipCode": GetZipCode(),
                                  "locn": defaults.string(forKey: locnNum) as Any],
                    "zipCode": GetZipCode()
                ] ]as [String : Any];
            
            let data = try! JSONSerialization.data(withJSONObject: locationInformation, options: [])
            let string = String(data: data, encoding: String.Encoding.utf8)
            return string!;
        }
    }
    
    class func getLogCountLimit() -> Int
    {
        let defaults = UserDefaults.standard;
        if( defaults.integer(forKey: "LogCountLimit")==0)
        {
            return 5000;
        }
        
        return defaults.integer(forKey: "LogCountLimit");
    }
    
    class func setLogCountLimit(value: Int)
    {
        let defaults = UserDefaults.standard;
        defaults.set(value, forKey: "LogCountLimit");
    }
    
    class func getLogTimeLimit() -> Double
    {
        let defaults = UserDefaults.standard;
        if( defaults.double(forKey: "LogTimeLimit")==0)
        {
            return 10800;
        }
        
        return defaults.double(forKey: "LogTimeLimit");
    }
    
    class func setLogTimeLimit(value: Double)
    {
        let defaults = UserDefaults.standard;
        defaults.set(value, forKey: "LogTimeLimit");
    }
    
    class func getLogRetryCount() -> Int
    {
        let defaults = UserDefaults.standard;
        if( defaults.integer(forKey: "LogRetryCount")==0)
        {
            return 25;
        }
        
        return defaults.integer(forKey: "LogRetryCount");
    }
    
    class func setLogRetryCount(value: Int)
    {
        let defaults = UserDefaults.standard;
        defaults.set(value, forKey: "LogRetryCount");
    }
    
    class func getLogRetryFrequency() -> Double
    {
        let defaults = UserDefaults.standard;
        if( defaults.double(forKey: "LogRetryFrequency") == 0)
        {
            return 30;
        }
        
        return defaults.double(forKey: "LogRetryFrequency");
    }
    
    class func setLogRetryFrequency(value: Double)
    {
        let defaults = UserDefaults.standard;
        defaults.set(value, forKey: "LogRetryFrequency");
    }
    
    class func getWebviewLoading() -> Bool
    {
        let defaults = UserDefaults.standard;
        return defaults.bool(forKey: "webviewLoading");
    }
    
    class func setWebviewLoading(value: Bool)
    {
        let defaults = UserDefaults.standard;
        defaults.set(value, forKey: "webviewLoading")
    }
    
    class func setAutoLogoutStartTime()
    {
        let defaults = UserDefaults.standard;
        defaults.set(Date.init(), forKey: autoLogoutStartTime);
    }
    
    class func getAutoLogoutStartTime()-> Date
    {
        let defaults = UserDefaults.standard;
        if let date = defaults.object(forKey: autoLogoutStartTime) as? Date {
            return date as Date;
        }
        else
        {
            setAutoLogoutStartTime();
            return Date.init();
        }
    }
    
    class func getCommonLogMetrics() -> [[String:Any]]
    {
        let defaults = UserDefaults.standard;
        if(defaults.array(forKey: commonLogMetrics)==nil)
        {
            setCommonLogMetrics();
        }
        return defaults.array(forKey: commonLogMetrics) as! [[String : Any]];
    }
    
    class func getDateformatter() -> DateFormatter
    {
        let dateFormatter = DateFormatter();
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ";
        dateFormatter.timeZone = TimeZone.current;
        return dateFormatter;
    }
    
    class func setCommonLogMetrics()
    {
        let defaults = UserDefaults.standard;
        var commonMetricsArray=[[String:Any]]();
        commonMetricsArray.append(metricJson(name: "DeviceOSName", value: "iOS", type: "STRING", indexable: true))
        commonMetricsArray.append(metricJson(name: "DeviceOSVersion", value: UIDevice.current.systemVersion, type: "STRING", indexable: true))
        var uuidData = JSON.parse(getDeviceId()).dictionary;
        
        if (!(uuidData==nil) && !(uuidData?["deviceId"]==nil)) {
            commonMetricsArray.append(metricJson(name: "DeviceUUID", value: (uuidData?["deviceId"]?.description)!, type: "STRING", indexable: true))
        }
        
        //commonMetricsArray.append(metricJson(name: "DeviceUUID", value: getDeviceId(), type: "STRING", indexable: true))
        commonMetricsArray.append(metricJson(name: "DeviceName", value: UIDevice.current.name, type: "STRING", indexable: true))
        commonMetricsArray.append(metricJson(name: "AppVersion", value: Assembly.halVersion(), type: "STRING", indexable: true))
        commonMetricsArray.append(metricJson(name: "AW_LandingPage", value: getLandingPage().absoluteString, type: "STRING", indexable: true))
        commonMetricsArray.append(metricJson(name: "AW_DivNumber", value: getDivNum().description, type: "INTEGER", indexable: true))
        commonMetricsArray.append(metricJson(name: "AW_StoreNumber", value: getStoreNum().description, type: "INTEGER", indexable: true))
        commonMetricsArray.append(metricJson(name: "AW_ISP", value: SharedContainer.getIsp(), type: "STRING", indexable: true))
        commonMetricsArray.append(metricJson(name: "AW_SSP", value: SharedContainer.getSsp(), type: "STRING", indexable: true))
        commonMetricsArray.append(metricJson(name: "AW_Cloud", value: SharedContainer.getCloud(), type: "STRING", indexable: true))
        commonMetricsArray.append(metricJson(name: "AW_AutoLogout", value: getAutoLogoutTimeinterval().description, type: "INTEGER", indexable: true))
        commonMetricsArray.append(metricJson(name: "AW_LogRetryCount", value: getLogRetryCount().description, type: "INTEGER", indexable: true))
        commonMetricsArray.append(metricJson(name: "AW_LogStorageCountLimit", value: getLogCountLimit().description, type: "INTEGER", indexable: true))
        commonMetricsArray.append(metricJson(name: "AW_LogRetryFrequency", value: getLogRetryFrequency().description, type: "DOUBLE", indexable: true))
        commonMetricsArray.append(metricJson(name: "AW_LogStorageTimeLimit", value: getLogTimeLimit().description, type: "DOUBLE", indexable: true))
        
        defaults.set(commonMetricsArray, forKey: commonLogMetrics)
    }
    
    class func metricJson(name:String,value:String,type:String,indexable:Bool)-> [String:Any]
    {
        return [
            "name": name,
            "value": value,
            "type": type,
            "indexable":indexable
        ];
    }
    
    class func isSimulator() -> Bool
    {
        #if arch(i386) || arch(x86_64)
            return true;
        #endif
        
        return false;
    }
    
    class func getConfigurationParams() -> String
    {
        var uuidData = JSON.parse(getDeviceId()).dictionary;
        let configJson = [
            "DeviceOSName": "iOS",
            "DeviceOSVersion": UIDevice.current.systemVersion,
            "DeviceUUID": (uuidData?["deviceId"]?.description) ?? "",
            "DeviceName": UIDevice.current.name,
            "AppVersion": Assembly.halVersion(),
            "AW_LandingPage": getLandingPage().absoluteString,
            "AW_DivNumber": getDivNum().description,
            "AW_StoreNumber": getStoreNum().description,
            "AW_ISP": SharedContainer.getIsp(),
            "AW_SSP": SharedContainer.getSsp(),
            "AW_Cloud": SharedContainer.getCloud(),
            "AW_AutoLogout": getAutoLogoutTimeinterval().description,
            "AW_LogRetryCount": getLogRetryCount().description,
            "AW_LogStorageCountLimit": getLogCountLimit().description,
            "AW_LogRetryFrequency": getLogRetryFrequency().description,
            "AW_LogStorageTimeLimit": getLogTimeLimit().description,
            "AvailableFunctions":Assembly.halFunctions()
            ] as [String : Any]
        
        let halConfigurationData = try! JSONSerialization.data(withJSONObject: configJson, options: [])
        let  halConfiguration = String(data: halConfigurationData, encoding: String.Encoding.utf8)
        return halConfiguration ?? "";
    }
    
    class func setSavedPrinterMACAddress(value: String)
    {
        let defaults = UserDefaults.standard;
        defaults.set(value, forKey: savedPrinterMACAddress);
    }
    class func getSavedPrinterMACAddress() -> String
    {
        let defaults = UserDefaults.standard
        if let macAddress = defaults.string(forKey: savedPrinterMACAddress)
        {
            return macAddress
        }
        
        return "";
    }
}
