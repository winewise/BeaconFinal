//
//  Beacon+CoreDataProperties.swift
//  BeaconSearchApp
//
//  Created by Hafiz Usama on 2016-03-21.
//  Copyright © 2016 Ap1. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

import Foundation
import CoreData

extension Beacon {
    @NSManaged public var accuracy: NSNumber?
    @NSManaged public var color: String?
    @NSManaged public var companyId: String?
    @NSManaged public var companyName: String?
    @NSManaged public var createdOn: NSDate?
    @NSManaged public var id: String?
    @NSManaged public var latitude: String?
    @NSManaged public var longitude: String?
    @NSManaged public var macAddress: String?
    @NSManaged public var major: String?
    @NSManaged public var minor: String?
    @NSManaged public var nickName: String?
    @NSManaged public var notifyTextFar: String?
    @NSManaged public var notifyTitleFar: String?
    @NSManaged public var rssi: String?
    @NSManaged public var unit: String?
    @NSManaged public var urlFar: String?
    @NSManaged public var urlNear: String?
    @NSManaged public var uuid: String?
    @NSManaged public var notifyTitleNear: String?
    @NSManaged public var notifyTextNear: String?
    @NSManaged public var beaconState: BeaconState?
    @NSManaged public var urlFarContent: UrlContent?
    @NSManaged public var urlNearContent: UrlContent?
}