//
//  HALApplication.swift
//  HAL-iOS
//
//  Created by Pranitha on 11/17/16.
//  Copyright © 2016 macys. All rights reserved.
//

import UIKit
import Foundation
@objc(HALApplication)

class HALApplication: UIApplication {
    var timer = Timer()
    
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
    
    func resetTimer(){
        
        timer.invalidate()
        startTimer()
    }
    func update(){
        print(" autologout")
        CommonUtils.setIsSSOAuthenticated( value: false );
    }
}
