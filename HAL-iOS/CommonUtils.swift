//
//  CommonUtils.swift
//  HAL-iOS
//
//  Created by VAMSHI BOMMAVARAM on 10/13/16.
//  Copyright © 2016 macys. All rights reserved.
//

import Foundation
class CommonUtils
{
    static let ssoSignedInKey = "ssoSignedInKey";
    static let ssoAssociateInfo = "ssoAssociateInfo";
    static let currentPage = "currentPage";
    
    class func setUpSSODefaults() -> Void
    {
        let defaults = UserDefaults.standard
        defaults.setValue(false, forKey: ssoSignedInKey)
        defaults.setValue([:], forKey: ssoAssociateInfo)
    }
    
    class func isSSOAuthenticated() -> Bool
    {
        let defaults = UserDefaults.standard
        return defaults.bool(forKey: ssoSignedInKey)
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
    
    class func getSSOData() -> [String:Any]
    {
        let defaults = UserDefaults.standard
        return defaults.value(forKey: ssoAssociateInfo) as! [String:Any]
    }
}
