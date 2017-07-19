//
//  Utils.swift
//  HAL-iOS
//
//  Created by Brian Dembinski on 7/17/17.
//  Copyright © 2017 macys. All rights reserved.
//

import Foundation

extension Data {
    
    /// Create hexadecimal string representation of `Data` object.
    ///
    /// - returns: `String` representation of this `Data` object.
    
    func toHexString() -> String {
        return map { String(format: "%02x", $0) }.joined(separator: "");
    }
    
    func getBytes() -> [UInt8]! {
        // create array of appropriate length:
        var array = [UInt8](repeating: 0, count: self.count);
        
        // copy bytes into array
        (self as NSData).getBytes(&array, length:self.count);
        
        return array;
    }
}

extension NSData {
    func getBytes() -> [UInt8]! {
        // create array of appropriate length:
        var array = [UInt8](repeating: 0, count: self.length);
        
        // copy bytes into array
        self.getBytes(&array, length:self.length);
        
        return array;
    }
}

extension Array {
    func toHexString() -> String {
        
        let string = NSMutableString(capacity: count * 2);
        
        if self.first is UInt8 {
            var byteArray = self.map { $0 as! UInt8 };
            for i in 0 ..< count {
                string.appendFormat("%02X", byteArray[i]);
            }
        }
        return string as String
    }
    
    func getNSData() -> Data {
        let data = Data(buffer: UnsafeBufferPointer(start: self, count: self.count));
        
        return data;
    }
}
