//
//  BeaconState+CoreDataProperties.swift
//  BeaconSearchApp
//
//  Created by Hafiz Usama on 2016-01-13.
//  Copyright © 2016 Ap1. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

import Foundation
import CoreData

extension BeaconState {

    @NSManaged public var exitProximity: NSDate?
    @NSManaged public var exitRange: NSDate?
    @NSManaged public var inProximity: NSDate?
    @NSManaged public var inRange: NSDate?
    @NSManaged public var lastSeenNear: NSDate?
    @NSManaged public var lastSeenFar: NSDate?

}
