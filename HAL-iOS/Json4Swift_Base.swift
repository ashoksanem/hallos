//
//  Json4Swift_Base.swift
//  HAL-iOS
//
//  Created by Pranitha on 10/7/16.
//  Copyright © 2016 macys. All rights reserved.
//

import Foundation

public class Json4Swift_Base {
    public var jwt : Jwt?
    public var error : Error?
    public var associateInfo : AssociateInfo?
    
   
    required public init?(dictionary: JSON) {
        if (dictionary["jwt"] != nil) { jwt = Jwt(dictionary: dictionary["jwt"]) }
        if (dictionary["error"] != nil) { error = Error(dictionary:dictionary["error"]) }
        if (dictionary["associateInfo"] != nil) { associateInfo = AssociateInfo(dictionary: dictionary["associateInfo"]) }
    }
    
    
    /**
     Returns the dictionary representation for the current instance.
     
     - returns: NSDictionary.
     */
    public func dictionaryRepresentation() -> NSDictionary {
        
        let dictionary = NSMutableDictionary()
        
        dictionary.setValue(self.jwt?.dictionaryRepresentation(), forKey: "jwt")
        dictionary.setValue(self.error?.dictionaryRepresentation(), forKey: "error")
        dictionary.setValue(self.associateInfo?.dictionaryRepresentation(), forKey: "associateInfo")
        
        return dictionary
    }
    
}
