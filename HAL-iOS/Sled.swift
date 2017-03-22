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
            LoggingRequest.logData(name: LoggingRequest.metrics_info, value: "Sled battery level: " + val, type: "STRING", indexable: true);
            return val;
        }
        return "-1";
    }
    
    class func getDeviceBatteryLevel() -> String {
        if let delegate = UIApplication.shared.delegate as? AppDelegate {
            let val = String( delegate.getDeviceBatteryLevel() * 100 );
            LoggingRequest.logData(name: LoggingRequest.metrics_info, value: "Device battery level: " + val, type: "STRING", indexable: true);
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
    
    class func enableCharging( val: Bool ) -> Void {
        //Linea Logic
        if let delegate = UIApplication.shared.delegate as? AppDelegate {
            if( isConnected() )
            {
                let charging = delegate.isLineaCharging();
                let iPodBattery:Int! = Int( getDeviceBatteryLevel() );
                let sledBattery:Int! = Int( getSledBatteryLevel() );
    
                //trickle charge
                if( charging && ( sledBattery < 45 || iPodBattery >= 90 ) ) {
                    LoggingRequest.logData(name: LoggingRequest.metrics_info, value: "Disable sled trickle charge", type: "STRING", indexable: true);
                    delegate.setLineaCharging( val: false );
                }
                else if( !charging && sledBattery > 50 && iPodBattery < 75 ) {
                    LoggingRequest.logData(name: LoggingRequest.metrics_info, value: "Enable sled trickle charge", type: "STRING", indexable: true);
                    delegate.setLineaCharging( val: true );
                }
    
                //emergency mode
                if( !charging && sledBattery > 20 && iPodBattery < 10 ) {
                    LoggingRequest.logData(name: LoggingRequest.metrics_info, value: "Enable sled emergency charge", type: "STRING", indexable: true);
                    delegate.setLineaCharging( val: true );
                }
                else if( charging && sledBattery < 20 ) {
                    LoggingRequest.logData(name: LoggingRequest.metrics_info, value: "Disable sled emergency charge", type: "STRING", indexable: true);
                    delegate.setLineaCharging( val: false );
                }
            }
        }
    }
}
