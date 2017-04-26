//
//  Assembly.swift
//  HAL-iOS
//
//  Created by Pranitha on 9/29/16.
//  Copyright © 2016 macys. All rights reserved.
//

import Foundation
class Assembly{
    class func halVersion() -> String {
        
        if(!((Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String)==nil))
        {
            return Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as! String
        }
        return "";
    }
    
    class func halType() -> String {
        
        return "iOS"
    }
    class func halFunctions() -> [String] {
        var availableFunctions=[String]();
        if(isScannerAvailable()){
        availableFunctions.append("Scanner");
        }
        if(isCameraAvailable()){
            availableFunctions.append("Camera");
        }
        return availableFunctions
    }
    
    class func halJson() -> String {
        let halJson = [
            "amIinHal": "true",
            "halType": self.halType(),
            "halVersion": self.halVersion(),
            "availableFunctions":self.halFunctions()
        ] as [String : Any]
        let halJsonData = try! JSONSerialization.data(withJSONObject: halJson, options: [])
        let  halJsonString = String(data: halJsonData, encoding: String.Encoding.utf8)
        DLog(halJsonString!);
        return halJsonString!
    }
    class func isScannerAvailable() -> Bool {
        return Sled.isConnected();
    }
    class func isCameraAvailable() -> Bool {
        return true;
    }
}
