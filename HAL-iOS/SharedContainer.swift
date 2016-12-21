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
    
    class func saveData(data: NSDictionary) -> Void {
        //let defaults = UserDefaults.init(suiteName: sharedContainerKey)
        //let key=data["key"] as! String
        
        //defaults?.set(data, forKey: key)
        let key=data["key"] as! String
        KeychainWrapper.standard.set(data, forKey: key)
        print(KeychainWrapper.standard.object(forKey: key) as! NSDictionary)
    }
    
    class func restoreData(key: String) -> String {
        let jsonData = try! JSONSerialization.data(withJSONObject: getData(key: key), options: [])
        return String(data: jsonData, encoding: String.Encoding.utf8)!
        }
    
    class func removeData(key: String){
        //let defaults = UserDefaults.init(suiteName: sharedContainerKey)
        //defaults?.removeObject(forKey: key)
        KeychainWrapper.standard.removeObject(forKey: key)
    }
    class func getData(key: String) -> NSDictionary{
        /*let defaults = UserDefaults.init(suiteName: sharedContainerKey)
        if let value = defaults?.value(forKey: key)
        {
            return value as! NSDictionary
        }*/
        //print(KeychainWrapper.standard.object(forKey: key) as! NSDictionary)
        if KeychainWrapper.standard.hasValue(forKey: key) {
            return KeychainWrapper.standard.object(forKey: key) as! NSDictionary
        }
        else{
            return [:]
        }
    }
}
