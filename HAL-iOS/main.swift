//
//  main.swift
//  HAL-iOS
//
//  Created by Pranitha on 11/17/16.
//  Copyright © 2016 macys. All rights reserved.
//

import UIKit
import Foundation
UIApplicationMain(
    CommandLine.argc,
    UnsafeMutableRawPointer(CommandLine.unsafeArgv)
        .bindMemory(
            to: UnsafeMutablePointer<Int8>.self,
            capacity: Int(CommandLine.argc)),
    nil,
    NSStringFromClass(AppDelegate.self)
)
