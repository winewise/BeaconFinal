//
//  BeaconType+CoreDataProperties.swift
//  BeaconSearchApp
//
//  Created by Hafiz Usama on 2016-04-03.
//  Copyright © 2016 Ap1. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

import Foundation
import CoreData

extension BeaconType {

    @NSManaged public var id: String?
    @NSManaged public var manufacturer: String?
    @NSManaged public var type: String?
    @NSManaged public var uuid: String?
    @NSManaged public var visible: NSNumber?
    @NSManaged public var usable: NSNumber?

}
