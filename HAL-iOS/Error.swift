//
//  Error.swift
//  HAL-iOS
//
//  Created by Pranitha on 10/7/16.
//  Copyright © 2016 macys. All rights reserved.
//

import Foundation
public class Error {
    public var errorCode : Int?
    public var errorMessage : String?
    
   /**
     Constructs the object based on the given dictionary.
     
     Sample usage:
     let error = Error(someDictionaryFromJSON)
     
     - parameter dictionary:  NSDictionary from JSON.
     
     - returns: Error Instance.
     */
    required public init?(dictionary: JSON) {
        
        errorCode = dictionary["errorCode"].int
        errorMessage = dictionary["errorMessage"].string
    }
    
    
    /**
     Returns the dictionary representation for the current instance.
     
     - returns: NSDictionary.
     */
    public func dictionaryRepresentation() -> NSDictionary {
        
        let dictionary = NSMutableDictionary()
        
        dictionary.setValue(self.errorCode, forKey: "errorCode")
        dictionary.setValue(self.errorMessage, forKey: "errorMessage")
        return dictionary
    }
    
}
