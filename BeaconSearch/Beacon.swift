//
//  Beacon.swift
//  BeaconSearch
//
//  Created by Developer 1 on 2015-08-24.
//  Copyright © 2015 Ap1. All rights reserved.
//

import Foundation
import CoreData

@objc(Beacon)
public class Beacon: NSManagedObject, Comparable {

// Insert code here to add functionality to your managed object subclass

}

public func == (lhs: Beacon, rhs: Beacon) -> Bool {
    return((lhs.uuid == rhs.uuid) &&
        (lhs.major == rhs.major) &&
        (lhs.minor == rhs.minor))
}

public func < (lhs: Beacon, rhs: Beacon) -> Bool {
    if (lhs == rhs){
        return false
    }
    if(lhs.uuid == rhs.uuid){
        if(lhs.major == rhs.major){
            return (lhs.minor < rhs.minor)
        }
        return (lhs.major < rhs.major)
    }
    return (lhs.uuid < rhs.uuid)
}

extension Beacon {
    public override var hashValue : Int{
        get {
            return ("\(uuid),\(major),\(minor)".hashValue)
        }
    }
    
    public override var description: String {
        return ("Beacon (ID: \(id) (UUID: \(uuid)  Major: \(major)  Minor: \(minor))")
    }
}