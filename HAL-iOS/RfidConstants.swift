//
//  RfidConstants.swift
//  HAL-iOS
//
//  Created by Minh Dang Le on 5/7/19.
//  Copyright © 2019 macys. All rights reserved.
//

import Foundation

enum bucketType:Int {
    case None = 0
    case OutOfRange = 1
    case BarelyInRange = 2
    case Far = 3
    case Near = 4
    case VeryNear = 5
    case RightOnTop = 6
}

let CONST_SLED_VOLUME = "SVolume"
let CONST_SLED_SESSION = "SSession"

