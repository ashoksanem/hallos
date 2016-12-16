//
//  Sled.swift
//  HAL-iOS
//
//  Created by Pranitha on 11/2/16.
//  Copyright © 2016 macys. All rights reserved.
//

import Foundation
class Sled
{
    class func isConnected() -> Bool
    {
        if let delegate = UIApplication.shared.delegate as? AppDelegate {
            return delegate.isLineaConnected()
        }
        return false
    }
    
    class func getSledBatteryLevel() -> String {
        let delegate = UIApplication.shared.delegate as? AppDelegate
        return String( delegate!.getSledBatteryLevel() );
    }
    
    class func getDeviceBatteryLevel() -> String {
        let delegate = UIApplication.shared.delegate as? AppDelegate
        return String(delegate!.getDeviceBatteryLevel()*100)
    }
    
    class func enableScanner() -> Void {
        let delegate = UIApplication.shared.delegate as? AppDelegate
        delegate?.enableScanner()
    }
    
    class func disableScanner() -> Void {
        let delegate = UIApplication.shared.delegate as? AppDelegate
        delegate?.disableScanner()
    }
}
