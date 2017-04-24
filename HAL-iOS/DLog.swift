//
//  DLog.swift
//  HAL-iOS
//
//  Created by Pranitha Kota on 4/24/17.
//  Copyright © 2017 macys. All rights reserved.
//

import Foundation

func DLog(  _ message: String, filename: String = #file, function: String = #function, line: Int = #line) {
    #if DEBUG
        NSLog("[\((filename as NSString).lastPathComponent):\(line)] \(function) - \(message)")
    #endif
}
