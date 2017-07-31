//
//  SharedContainer.swift
//  HAL-iOS
//
//  Created by Pranitha on 11/7/16.
//  Copyright © 2016 macys. All rights reserved.
//

import Foundation
class SharedContainer
{
    static let sharedContainerKey = "group.com.macys.technology";
    static let webDataKey = "webData";
    class func saveData(data: NSDictionary) -> Bool {
        if let key = data["key"] as? String {
            if( JSONSerialization.isValidJSONObject( data ) ) {
                KeychainWrapper.standard.set(data, forKey: key);
                
                if let dict = KeychainWrapper.standard.object(forKey: key) as? NSDictionary {
                    print(dict); //specifically don't want to use NSLog here
                }
                return true;
            }
            else {
                LoggingRequest.logData(name: LoggingRequest.metrics_error, value: "Storing invalid JSON object for key: " + key, type: "STRING", indexable: true);
            }
        }
        return false;
    }
    
    class func restoreData(key: String) -> String {
        do {
            let data = getData(key:key);
            if( JSONSerialization.isValidJSONObject( data ) ) {
                let jsonData = try JSONSerialization.data(withJSONObject: getData(key: key), options: [])
                
                if let dict = KeychainWrapper.standard.object(forKey: key) as? NSDictionary {
                    print(dict); //specifically don't want to use NSLog here
                }
                
                return String(data: jsonData, encoding: String.Encoding.utf8)!
            }
            else {
                LoggingRequest.logData(name: LoggingRequest.metrics_error, value: "Restoring invalid JSON object for key: " + key, type: "STRING", indexable: true);
            }
        }
        catch {
            LoggingRequest.logData(name: LoggingRequest.metrics_error, value: "Unable to restore data for key: " + key, type: "STRING", indexable: true);
        }
        
        return "{}";
    }
    
    class func removeData(key: String){
        KeychainWrapper.standard.removeObject(forKey: key)
    }
    
    class func saveWebData(data: [NSDictionary]) -> Void {
        KeychainWrapper.standard.set(([webDataKey:data] as NSDictionary), forKey: webDataKey)
    }
    
    class func removeWebData(){
        KeychainWrapper.standard.removeObject(forKey: webDataKey)
    }
    
    class func getData(key: String) -> NSDictionary {
        if KeychainWrapper.standard.hasValue(forKey: key) {
            if let dict = KeychainWrapper.standard.object(forKey: key) as? NSDictionary {
                return dict;
            }
        }

        return [:]
    }
    
    class func getIsp() -> String {
        if KeychainWrapper.standard.hasValue(forKey: "isp") {
            if(!(KeychainWrapper.standard.string(forKey: "isp")==nil)) {
                return KeychainWrapper.standard.string(forKey: "isp")!
            }
        }

        return "";
    }
    
    class func getSsp() -> String {
        if KeychainWrapper.standard.hasValue(forKey: "ssp") {
            if(!(KeychainWrapper.standard.string(forKey: "ssp")==nil)) {
                return KeychainWrapper.standard.string(forKey: "ssp")!
            }
        }
        return "";
    }
    
    class func getCloud() -> String {
        if KeychainWrapper.standard.hasValue(forKey: "cloud") {
            if(!(KeychainWrapper.standard.string(forKey: "cloud")==nil))
            {
                return KeychainWrapper.standard.string(forKey: "cloud")!
            }
        }
        
        return "";
    }
    
    class func setIsp(value: String) -> Void {
       KeychainWrapper.standard.set(value, forKey: "isp")
    }
    
    class func setSsp(value: String) -> Void {
        KeychainWrapper.standard.set(value, forKey: "ssp")
    }
    
    class func setCloud(value: String) -> Void {
        KeychainWrapper.standard.set(value, forKey: "cloud")
    }
}
