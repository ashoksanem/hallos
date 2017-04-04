//
//  HALApplication.swift
//  HAL-iOS
//
//  Created by Pranitha on 11/17/16.
//  Copyright © 2016 macys. All rights reserved.
//

import UIKit
import Foundation
import SystemConfiguration
@objc(HALApplication)

class HALApplication: UIApplication {
    var timer = Timer()
    var networkTimer = Timer();
    var metricTimer = Timer();
    var batteryTimer = Timer();
    var jsTimer = Timer();
    var chargingTimer = Timer();
    
    override func sendEvent(_ event: UIEvent) {
        
        if event.type != .touches {
            super.sendEvent(event)
            return
        }
        
        var restartTimer = true
        if let touches = event.allTouches {
            for touch in touches.enumerated() {
                if touch.element.phase != .cancelled && touch.element.phase != .ended {
                    restartTimer = false
                    break
                }
            }
        }
        
        if restartTimer {
            resetTimer()
        } else {
            timer.invalidate()
        }
        
        super.sendEvent(event)
    }
    
    func startTimer(){
        timer = Timer.scheduledTimer(timeInterval: TimeInterval(CommonUtils.getAutoLogoutTimeinterval()), target: self, selector: #selector(self.update), userInfo: nil, repeats: false);
    }
    
    func startNetworkTimer(){
        networkTimer = Timer.scheduledTimer(timeInterval: TimeInterval(900), target: self, selector: #selector(self.checkNetworkConnectivity), userInfo: nil, repeats: true);
    }
    
    func stopNetworkTimer(){
        networkTimer.invalidate();
    }
    
    func startMetricTimer(){
        metricTimer = Timer.scheduledTimer(timeInterval: TimeInterval(CommonUtils.getLogRetryFrequency()), target: self, selector: #selector(self.logStoredData), userInfo: nil, repeats: true);
    }
    
    func stopMetricTimer(){
        metricTimer.invalidate();
    }
    
    func resetTimer(){
        
        timer.invalidate();
        startTimer();
    }
    
    func startBatteryTimer(){
        batteryTimer = Timer.scheduledTimer(timeInterval: TimeInterval(60), target: self, selector: #selector(self.updateBattery), userInfo: nil, repeats: true);
    }
    
    func stopBatteryTimer(){
        batteryTimer.invalidate();
    }
    
    func startJSTimer() {
        jsTimer = Timer.scheduledTimer(timeInterval: TimeInterval(0.250), target: self, selector: #selector(self.sendStoredJS), userInfo: nil, repeats: true);
    }
    
    func stopJSTimer() {
        jsTimer.invalidate();
    }
    
    func startChargingTimer(){
        chargingTimer = Timer.scheduledTimer(timeInterval: TimeInterval(30), target: self, selector: #selector(self.enableCharging), userInfo: nil, repeats: true);

    }
    
    func stopChargingTimer(){
        chargingTimer.invalidate();
    }
    
    func update() {
        NSLog("autologout");
        LoggingRequest.logData(name: LoggingRequest.metrics_info, value: "Associate autoLogout due to inactivity.", type: "STRING", indexable: true);
        CommonUtils.setIsSSOAuthenticated( value: false );
    }
    
    func checkNetworkConnectivity() {
        NSLog("Check network");
        if(!isInternetAvailable()){
            LoggingRequest.logData(name: LoggingRequest.metrics_lost_network, value: "", type: "STRING", indexable: true);
        }
    }
    
    func logStoredData() {
        NSLog("Send stored logs to server");
        LogAnalyticsRequest.logStoredData();
        LoggingRequest.logStoredData();
    }
    
    func updateBattery() {
        NSLog("Update Sled battery");
        let delegate = UIApplication.shared.delegate as? AppDelegate;
        delegate?.updateBattery();
    }
    
    func enableCharging() {
        if(Sled.isConnected()) {
            NSLog("Enable charging from sled");
            Sled.enableCharging(val: true)
        }
    }
    
    func isInternetAvailable() -> Bool
    {
        var zeroAddress = sockaddr_in();
        zeroAddress.sin_len = UInt8(MemoryLayout.size(ofValue: zeroAddress));
        zeroAddress.sin_family = sa_family_t(AF_INET);
        
        let defaultRouteReachability = withUnsafePointer(to: &zeroAddress) {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {zeroSockAddress in
                SCNetworkReachabilityCreateWithAddress(nil, zeroSockAddress);
            }
        }
        
        var flags = SCNetworkReachabilityFlags();
        
        if !SCNetworkReachabilityGetFlags(defaultRouteReachability!, &flags) {
            return false;
        }
        
        let isReachable = (flags.rawValue & UInt32(kSCNetworkFlagsReachable)) != 0;
        let needsConnection = (flags.rawValue & UInt32(kSCNetworkFlagsConnectionRequired)) != 0;
        return (isReachable && !needsConnection);
    }
    
    func sendStoredJS() {
       
        if( ViewController.storedJS.count > 0 )
        {
            let javascriptMessage = ViewController.storedJS.popLast() as String!;
            NSLog("Resending : " + javascriptMessage!);
            ViewController.webView?.evaluateJavaScript(javascriptMessage!) { result, error in
                guard error == nil else {
                    ViewController.storedJS.append(javascriptMessage!);
                    NSLog("evaluateJavaScript message: " + javascriptMessage!);
                    if( error != nil ) {
                        let junk = error?.localizedDescription;
                        if( junk != nil ) {
                            NSLog("evaluateJavaScript error: " + junk! );
                        }
                    }
                    return
                }
            }
        }
    }
}
