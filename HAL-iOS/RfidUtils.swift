//
//  Utilities.swift
//  HAL-iOS
//
//  Created by Mahesh Koneru on 10/18/18.
//  Copyright © 2018 macys. All rights reserved.
//

import Foundation
import rfid_ios_fw

class RfidUtils: NSObject {
    
    static let triggerMode = "triggerMode";
    static let autoPlayMode = "autoPlayMode";
    
    class func setInventorySessionMode(mode: String)
    {
        let defaults = UserDefaults.standard;
        defaults.set(mode, forKey: inventorySessionMode);
    }
    class func getInventorySessionMode() -> String
    {
        let defaults = UserDefaults.standard;
        return defaults.string(forKey: inventorySessionMode) ?? triggerMode;
    }
    
    class func TranslateResultToStringResult(_ result:RFID_RESULT) -> String{
        switch result {
        case .SUCCESS:
            return "SUCCESS"
        case .ALREADY_PAIRED:
            return "ALREADY_PAIRED"
        case .DEVICE_NOT_SUPPORT:
            return "DEVICE_NOTE_PAIRED"
        case .FAILURE:
            return "FAILURE"
        case .ASCII_CONNECTION_REQUIRED:
            return "ASCII_CONNECTION_REQUIRED"
        case .INVALID_PARAMS:
            return "INVALID_PARAMS"
        case .NOT_ACTIVE:
            return "NOT_ACTIVE"
        case .NOT_SUPPORTED:
            return "NOT_SUPPORTED"
        case .READER_NOT_AVAILABLE:
            return "READER_NOT_AVAILABLE"
        case .RESPONSE_ERROR:
            return "RESPONSE_ERROR"
        case .RESPONSE_TIMEOUT:
            return "RESPONSE_TIMEOUT"
        case .WRONG_ASCII_PASSWORD:
            return "WRONG_ASCII_PASSWORD"
        default:
            return "FAILURE"
        }
    }
    
    class func TranslateResultToStringResult(_ result:FIND_PRODUCT_RESULT) -> String{
        switch result {
        case .SUCCESS:
            return "SUCCESS"
        case .LOCATE_SESSION_NOT_OPEN:
            return "LOCATE_SESSION_NOT_OPEN"
        case .UPC_LIST_EMPTY:
            return "UPC_LIST_EMPTY"
        case .NO_TAG_LOCKED_ON:
            return "NO_TAG_LOCKED_ON"
        case .ASCII_CONNECTION_REQUIRED:
            return "ASCII_CONNECTION_REQUIRED"
        case .DEVICE_NOT_SUPPORTED:
            return "DEVICE_NOT_SUPPORTED"
        case .FAILURE :
            return "FAILURE"
        case .INVALID_PARAMS:
            return "INVALID_PARAMS"
        case .WRONG_ASCII_PASSWORD:
            return "WRONG_ASCII_PASSWORD"
        case .READER_NOT_AVAILABLE:
            return "READER_NOT_AVAILABLE"
        case .RESPONSE_ERROR:
            return "RESPONSE_ERROR"
        case .RESPONSE_TIMEOUT:
            return "RESPONSE_TIMEOUT"
        default:
            return "FAILURE"
        }
    }
    
    class func TranslateResultToStringResult(_ result:INVENTORY_RESULT) -> String{
        switch result {
        case .SUCCESS:
            return "SUCCESS"
        case .COMM_NOT_INITIALIZED:
            return "COMM_NOT_INITIALIZED"
        case .NO_OPEN_SESSION:
            return "NO_OPEN_SESSION"
        default:
            return "FAILURE"
        }
    }
    
}

