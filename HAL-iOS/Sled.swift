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
        if let delegate = UIApplication.shared.delegate as? AppDelegate {
            let val = String( delegate.getSledBatteryLevel() );
            return val;
        }
        return "-1";
    }
    
    class func getDeviceBatteryLevel() -> String {
        if let delegate = UIApplication.shared.delegate as? AppDelegate {
            let val = String( delegate.getDeviceBatteryLevel() * 100 );
            return val;
        }
        return "-1";
    }
    
    class func enableScanner() -> Void {
        if let delegate = UIApplication.shared.delegate as? AppDelegate {
            delegate.enableScanner()
        }
    }
    
    class func disableScanner() -> Void {
        if let delegate = UIApplication.shared.delegate as? AppDelegate {
            delegate.disableScanner()
        }
    }
                //First let's set the idle and disconnect timeouts
                delegate.setLineaIdleTimeout()
                
                let iPodBattery:Float! = Float( getDeviceBatteryLevel() );
                let sledBattery:Float! = Float( getSledBatteryLevel() );
}
