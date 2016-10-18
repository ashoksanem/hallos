//
//  CommonUtils.swift
//  HAL-iOS
//
//  Created by VAMSHI BOMMAVARAM on 10/13/16.
//  Copyright © 2016 macys. All rights reserved.
//

import Foundation
class CommonUtils{
    static let ssoUserDefaultKey = "SSOData";
    static let ssoSignedInKey = "ssoSignedInKey";
    static let currentPage = "currentPage";
    class func setUpSSODefaults() -> Void {
        let defaults = UserDefaults.standard
        defaults.setValue(nil, forKey: ssoUserDefaultKey)
        defaults.setValue(false, forKey: ssoSignedInKey)
}
    class func isSSOAuthenticated() -> Bool {
        let defaults = UserDefaults.standard
        return defaults.bool(forKey: ssoSignedInKey)
    }
    
    class func isSSOAuthenticatedMessage() -> String {
        let successmsg = [
            "signedin": "true"
            ] as [String : Any]
        
        let failmsg = [
            "signedin": "false"
            ] as [String : Any]
        let halJsonData1 = try! JSONSerialization.data(withJSONObject: successmsg, options: [])
        let halJsonData2 = try! JSONSerialization.data(withJSONObject: failmsg, options: [])
        let  halJsonString1 = String(data: halJsonData1, encoding: String.Encoding.utf8)
        let  halJsonString2 = String(data: halJsonData2, encoding: String.Encoding.utf8)
        
        if(isSSOAuthenticated()){
        return halJsonString1!
        }
        return halJsonString2!
        
    }

    
    class func setIsSSOAuthenticated(value: Bool) -> Void {
        let defaults = UserDefaults.standard
        defaults.setValue(value, forKey: ssoSignedInKey)
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
        let defaults = UserDefaults.standard
        defaults.setValue(value, forKey: ssoUserDefaultKey)
        
        let json = JSON(data: value)
        let ssoJsonObject : Json4Swift_Base = Json4Swift_Base(dictionary: json)!
        print(ssoJsonObject.error?.errorCode)
        if(ssoJsonObject.error?.errorCode==0)
        {
            CommonUtils.setIsSSOAuthenticated(value: true)
        }
        else
        {
            CommonUtils.setIsSSOAuthenticated(value: false)
        }

    }
}
