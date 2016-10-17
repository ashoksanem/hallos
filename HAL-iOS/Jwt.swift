//
//  Jwt.swift
//  HAL-iOS
//
//  Created by Pranitha on 10/7/16.
//  Copyright © 2016 macys. All rights reserved.
//

import Foundation
public class Jwt {
    public var token : String?
    
    /**
     Constructs the object based on the given dictionary.
     
     Sample usage:
     let jwt = Jwt(someDictionaryFromJSON)
     
     - parameter dictionary:  NSDictionary from JSON.
     
     - returns: Jwt Instance.
     */
    required public init?(dictionary: JSON) {
        
        token = dictionary["token"].string
    }
    
    
    /**
     Returns the dictionary representation for the current instance.
     
     - returns: NSDictionary.
     */
    public func dictionaryRepresentation() -> NSDictionary {
        
        let dictionary = NSMutableDictionary()
        
        dictionary.setValue(self.token, forKey: "token")
        
        return dictionary
    }
    
}
