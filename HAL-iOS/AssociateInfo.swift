//
//  AssociateInfo.swift
//  HAL-iOS
//
//  Created by Pranitha on 10/7/16.
//  Copyright © 2016 macys. All rights reserved.
//

import Foundation
public class AssociateInfo {
    public var associateNbr : Int?
    public var associateName : String?
    public var inq28Status : Int?
    public var associateStatus : String?
    public var clockStatus : Int?
    public var exemptStatus : Int?
    public var exemptType : Int?
    public var clienteleAccess : String?
    public var managerLevel : Int?
    public var empClass : Int?
    public var clientTodo : String?
    
    
    /**
     Constructs the object based on the given dictionary.
     
     Sample usage:
     let associateInfo = AssociateInfo(someDictionaryFromJSON)
     
     - parameter dictionary:  NSDictionary from JSON.
     
     - returns: AssociateInfo Instance.
     */
    required public init?(dictionary: JSON) {
        
        associateNbr = dictionary["associateNbr"].int
        associateName = dictionary["associateName"].string
        inq28Status = dictionary["inq28Status"].int
        associateStatus = dictionary["associateStatus"].string
        clockStatus = dictionary["clockStatus"].int
        exemptStatus = dictionary["exemptStatus"].int
        exemptType = dictionary["exemptType"].int
        clienteleAccess = dictionary["clienteleAccess"].string
        managerLevel = dictionary["managerLevel"].int
        empClass = dictionary["empClass"].int
        clientTodo = dictionary["clientTodo"].string
    }
    
    
    /**
     Returns the dictionary representation for the current instance.
     
     - returns: NSDictionary.
     */
    public func dictionaryRepresentation() -> NSDictionary {
        
        let dictionary = NSMutableDictionary()
        
        dictionary.setValue(self.associateNbr, forKey: "associateNbr")
        dictionary.setValue(self.associateName, forKey: "associateName")
        dictionary.setValue(self.inq28Status, forKey: "inq28Status")
        dictionary.setValue(self.associateStatus, forKey: "associateStatus")
        dictionary.setValue(self.clockStatus, forKey: "clockStatus")
        dictionary.setValue(self.exemptStatus, forKey: "exemptStatus")
        dictionary.setValue(self.exemptType, forKey: "exemptType")
        dictionary.setValue(self.clienteleAccess, forKey: "clienteleAccess")
        dictionary.setValue(self.managerLevel, forKey: "managerLevel")
        dictionary.setValue(self.empClass, forKey: "empClass")
        dictionary.setValue(self.clientTodo, forKey: "clientTodo")
        
        return dictionary
    }
    
}
