//
//  Company+CoreDataProperties.swift
//  BeaconSearchApp
//
//  Created by Hafiz Usama on 2016-01-26.
//  Copyright © 2016 Ap1. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

import Foundation
import CoreData

public extension Company {

    @NSManaged public var color: String?
    @NSManaged public var id: String?
    @NSManaged public var idHash: String?
    @NSManaged public var name: String?
    @NSManaged public var latitude: String?
    @NSManaged public var longitude: String?

}
