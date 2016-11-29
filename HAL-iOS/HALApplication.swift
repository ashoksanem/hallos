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
    var networkTimer = Timer()
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
        timer = Timer.scheduledTimer(timeInterval: TimeInterval(CommonUtils.getAutoLogoutTimeinterval()), target: self, selector: #selector(self.update), userInfo: nil, repeats: false)
    }
    func startNetworkTimer(){
        networkTimer = Timer.scheduledTimer(timeInterval: TimeInterval(900), target: self, selector: #selector(self.checkNetworkConnectivity), userInfo: nil, repeats: true)
    }
    func stopNetworkTimer(){
        networkTimer.invalidate()
    }
    func resetTimer(){
        
        timer.invalidate()
        startTimer()
    }
    func update(){
        print(" autologout")
        CommonUtils.setIsSSOAuthenticated( value: false );
    }
    func checkNetworkConnectivity(){
        print("check network")
        if(!isInternetAvailable()){
        LoggingRequest.logData(name: LoggingRequest.metrics_lost_network, value: "", type: "STRING", indexable: true);
        }
    }
    func isInternetAvailable() -> Bool
    {
        var zeroAddress = sockaddr_in()
        zeroAddress.sin_len = UInt8(MemoryLayout.size(ofValue: zeroAddress))
        zeroAddress.sin_family = sa_family_t(AF_INET)
        
        let defaultRouteReachability = withUnsafePointer(to: &zeroAddress) {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {zeroSockAddress in
                SCNetworkReachabilityCreateWithAddress(nil, zeroSockAddress)
            }
        }
        
        var flags = SCNetworkReachabilityFlags()
        if !SCNetworkReachabilityGetFlags(defaultRouteReachability!, &flags) {
            return false
        }
        let isReachable = (flags.rawValue & UInt32(kSCNetworkFlagsReachable)) != 0
        let needsConnection = (flags.rawValue & UInt32(kSCNetworkFlagsConnectionRequired)) != 0
        return (isReachable && !needsConnection)
    }
}
