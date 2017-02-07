//
//  Json4Swift_Base.swift
//  HAL-iOS
//
//  Created by Pranitha on 10/7/16.
//  Copyright © 2016 macys. All rights reserved.
//

import Foundation

public class Json4Swift_Base {
    public var jwt : String?;
    public var associateInfo : AssociateInfo?;

    public var code : Int?;
    public var title : String?;
    public var description : String?;
    public var stack : String?;
   
    required public init? (dictionary: JSON) {
        if (dictionary["jwt"] != nil) { jwt = dictionary["jwt"].string };
        if (dictionary["associateInfo"] != nil) { associateInfo = AssociateInfo(dictionary: dictionary["associateInfo"]) };

        if (dictionary["code"] != nil) { code = dictionary["code"].int; };
        if (dictionary["title"] != nil) { title = dictionary["title"].string; };
        if (dictionary["description"] != nil) { description = dictionary["description"].string; };
        if (dictionary["stack"] != nil) { stack = dictionary["stack"].string; };
    }
    
    /**
     Returns the dictionary representation for the current instance.
     
     - returns: NSDictionary.
     */
    public func dictionaryRepresentation() -> NSDictionary {
        
        let dictionary = NSMutableDictionary();
        
        dictionary.setValue(self.jwt, forKey: "jwt");
        dictionary.setValue(self.associateInfo?.dictionaryRepresentation(), forKey: "associateInfo");
        
        dictionary.setValue(self.code, forKey: "code");
        dictionary.setValue(self.title, forKey: "title");
        dictionary.setValue(self.description, forKey: "description");
        dictionary.setValue(self.stack, forKey: "stack");
        
        return dictionary;
    }
}
