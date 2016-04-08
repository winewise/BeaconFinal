//
//  UrlContent+CoreDataProperties.swift
//  BeaconSearchApp
//
//  Created by Developer 1 on 2015-10-26.
//  Copyright © 2015 Ap1. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

import Foundation
import CoreData

public extension UrlContent {

    @NSManaged public var html: NSData?
    @NSManaged public var errorCode: String?
    @NSManaged public var errorDescription: String?
}