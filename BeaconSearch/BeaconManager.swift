//
//  BeaconManager.swift
//  BeaconSearch
//
//  Created by Developer 1 on 2015-08-24.
//  Copyright © 2015 Ap1. All rights reserved.
//

import Foundation
import CoreLocation
import UIKit
import CoreData

// Globally defined special notification key to be broadcast
let notificationKey = "com.ap1.notificationKey"

/// BeaconManagerDelegate is a required protocol for FindBeacon class for responding to the beacon found and remove events.
@objc(BeaconManagerDelegate)
public protocol BeaconManagerDelegate: NSObjectProtocol {
    
    /**
     When user enters the region of a beacon and within a known proximity range then this method will be invoked.
     
     - Parameters:
     - beacon: Beacon of type CLBeacon.
     - persistedBeacon: If this beacon stored in local storage then persistedBeacon will be passed; nil otherwise.
     - Returns: Void.
     */
    func beaconFound(foundBeacon: CLBeacon, persistedBeacon: Beacon?)
    
    /**
     When user exit the region and beacon is no longer in range of a device then this method will be invoked.
     
     - Parameters:
     - beacon: Beacon object of type CLBeacon.
     
     - Returns: Void.
     */
    func beaconRemoved(beacon: CLBeacon, persistedBeacon: Beacon?)

    /**
     When user enters the region of a beacon in close proximity range then this method will be invoked.
     
     - Parameters:
     - beacon: Beacon object of type CLBeacon.
     - Returns: Void.
     */
    func beaconFoundInCloseProximity(beacon: CLBeacon)
    
    /**
     When user exit the region of a beacon in close proximity range then this method will be invoked.
     
     - Parameters:
     - beacon: Beacon object of type CLBeacon.
     
     - Returns: Void.
     */
    func beaconRemovedFromCloseProximity(beacon: CLBeacon)
    
    /**
     This method will be constantly executed to update the state of the beacon for accuracy and RSSI value.
     
     - Parameters:
     - beacon: Beacon object of type CLBeacon.
     
     - Returns: Void.
     */
    func beaconUpdateAccuracy(beacon: CLBeacon)
}

class BeaconManager: NSObject, CLLocationManagerDelegate {
    // MARK:- Variables
    // Beacon Location delegations
    var locationManager: CLLocationManager?
    var lastProximity: CLProximity?
    // Placement to turn of constant requests
    var existingBeacon:Int = 0
    
    // Variable for notifaction ID
    var restBeacon:String?
    var existingLocationID = 0
    var currentlyDetectedBeacons: Dictionary<CLBeacon, Int> = Dictionary<CLBeacon, Int>()
    
    var currentlyInRegionBeacons: Dictionary<CLBeacon, Int> = Dictionary<CLBeacon, Int>()
    var regions: [CLBeaconRegion]?
    var delegate: BeaconManagerDelegate?
    weak var findBeacon: FindBeacon?
    var notifactionEnabled = true
    var notificationTitle: BeaconElement = .NickName
    var notificationDetail: BeaconElement = .MajorMinor
    
    override init () {
        super.init()
        self.locationManager = CLLocationManager()
        
        if (CLLocationManager.authorizationStatus() != CLAuthorizationStatus.AuthorizedAlways) {
            locationManager!.requestAlwaysAuthorization()
        }
        
        locationManager!.delegate = self
        locationManager!.pausesLocationUpdatesAutomatically = false
    }
    
    func stopMonitoring() {
        for region in self.locationManager!.monitoredRegions {
            self.locationManager!.stopMonitoringForRegion(region)
            self.locationManager!.stopRangingBeaconsInRegion(region as! CLBeaconRegion)
        }
        
        self.locationManager!.stopUpdatingLocation()
    }
    
    func setupRegions(beaconUDIDs: [String], identifier: String) {
        self.regions = Array<CLBeaconRegion>()
        
        self.stopMonitoring()
        
        self.locationManager!.startUpdatingLocation()
        
        for beaconUDID in beaconUDIDs {
            if let beaconUDIDValue = NSUUID(UUIDString: beaconUDID) {
                let region = CLBeaconRegion(proximityUUID: beaconUDIDValue, identifier: beaconUDID)
                self.regions?.append(region)
                
                region.notifyOnEntry = true
                region.notifyOnExit = true
                region.notifyEntryStateOnDisplay = true
                self.locationManager!.startMonitoringForRegion(region)
                self.locationManager!.startRangingBeaconsInRegion(region as CLBeaconRegion)
            }
        }
    }
    
    // MARK:- CLLocationManagerDelegate
    func locationManager(manager: CLLocationManager, didRangeBeacons beacons: [CLBeacon], inRegion region: CLBeaconRegion) {
        // Set proximity variable.
        let knownBeacons = beacons.filter{
            $0.proximity != CLProximity.Unknown
        }
    
    
        var removeableBeacons: [CLBeacon] = []
        for beacon in self.currentlyDetectedBeacons.keys {
            if beacon.proximityUUID.UUIDString  == region.identifier {
                if (beacons.filter{ self.eqaulBeacons(beaconA: $0 , beaconB: beacon) }.count <= 0) {
                    if self.currentlyDetectedBeacons[beacon] <= -20 {
                        removeableBeacons.append(beacon)
                    }
                    else {
                        self.currentlyDetectedBeacons[beacon] = self.currentlyDetectedBeacons[beacon] <= -20 ? -20 : self.currentlyDetectedBeacons[beacon]! - 1
                    }
                }
                else {
                    self.currentlyDetectedBeacons[beacon] = 1
                }
            }
        }
        
        for beacon in removeableBeacons {
            self.removeCurrentlyInRegionBeacons(beacon)
            self.removeFromCurrentlyDetectedBeacons(beacon)
            
            var persistedBeacon: Beacon? = nil
            if let findBeacon = self.findBeacon {
                if let beacon = findBeacon.findBeacon(beacon.proximityUUID.UUIDString, major: beacon.major.stringValue, minor: beacon.minor.stringValue) {
                    persistedBeacon = beacon
                }
            }
            
            if persistedBeacon != nil {
                self.updateBeaconState(persistedBeacon!, inProximity: nil, inRange: false)
            }
            
            delegate?.beaconRemovedFromCloseProximity(beacon)
            delegate?.beaconRemoved(beacon, persistedBeacon: persistedBeacon)
            
            if beacon.minor.integerValue == existingBeacon {
                existingBeacon = 0
            }
        }
        
        if (knownBeacons.count > 0) {
            for closestBeacon in knownBeacons {
                if ([CLBeacon](self.currentlyDetectedBeacons.keys.filter{ self.eqaulBeacons(beaconA: $0, beaconB: closestBeacon) }).count <= 0) {
                    
                    self.currentlyDetectedBeacons[closestBeacon] = 1
                    
                    var persistedBeacon: Beacon? = nil
                    
                    if let findBeacon = self.findBeacon {
                        if let item = findBeacon.findBeacon(closestBeacon.proximityUUID.UUIDString, major: closestBeacon.major.stringValue, minor: closestBeacon.minor.stringValue) {
                            persistedBeacon = item
                        }
                    }
                    
                    var alertTitle = self.getBeaconElement(self.notificationTitle, beacon: closestBeacon, persistedBeacon: persistedBeacon)
                    var message = self.getBeaconElement(self.notificationDetail, beacon: closestBeacon, persistedBeacon: persistedBeacon)
                    
                    if let persistedBeacon = persistedBeacon {
                        alertTitle = persistedBeacon.notifyTitleFar ?? ""
                        message = persistedBeacon.notifyTextFar ?? ""
                        
                        self.sendLocalNotificationWithMessage(persistedBeacon, alertTitle: alertTitle, message: message, distanceDetail: "far")
                    }
                    
                    delegate?.beaconFound(closestBeacon, persistedBeacon: persistedBeacon)
                    if let persistedBeacon = persistedBeacon {
                        self.updateBeaconState(persistedBeacon, inProximity: nil, inRange: true)
                    }
                    
                    if persistedBeacon != nil {
                        self.handleAccuracy(closestBeacon, persistedBeacon: persistedBeacon!, beacons: beacons, region: region)
                    }
                    else {
                        self.delegate?.beaconUpdateAccuracy(closestBeacon)
                    }
                }
                else {
                    var persistedBeacon: Beacon? = nil
                    if let findBeacon = self.findBeacon {
                        if let item = findBeacon.findBeacon(closestBeacon.proximityUUID.UUIDString, major: closestBeacon.major.stringValue, minor: closestBeacon.minor.stringValue) {
                            persistedBeacon = item
                        }
                    }
                    
                    if persistedBeacon != nil {
                        self.handleAccuracy(closestBeacon, persistedBeacon: persistedBeacon!, beacons: beacons, region: region)
                    }
                    else {
                        self.delegate?.beaconUpdateAccuracy(closestBeacon)
                    }
                }
            }
        }
    }
    
    func updateBeaconState(persistedBeacon: Beacon, inProximity: Bool?, inRange: Bool?) {
        self.findBeacon?.dataController!.managedObjectContext.performBlockAndWait { () -> Void in
            if persistedBeacon.beaconState == nil {
                persistedBeacon.beaconState = NSEntityDescription.insertNewObjectForEntityForName("BeaconState", inManagedObjectContext: self.findBeacon!.dataController!.managedObjectContext) as? BeaconState
            }
            
            let date = NSDate()
            
            if let value = inRange {
                if value {
                    // reset beacon state once its detected
                    persistedBeacon.beaconState?.inProximity = nil
                    persistedBeacon.beaconState?.exitProximity = nil
                    persistedBeacon.beaconState?.exitRange = nil
                    
                    persistedBeacon.beaconState?.inRange = date
                }
                else {
                    if persistedBeacon.beaconState?.exitProximity == nil {
                        persistedBeacon.beaconState?.exitProximity = date
                    }
                    
                    persistedBeacon.beaconState?.exitRange = date
                }
            }
            
            if let value = inProximity {
                if value {
                    persistedBeacon.beaconState?.inProximity = date
                }
                else {
                    persistedBeacon.beaconState?.exitProximity = date
                }
            }
        }
        
        self.findBeacon?.dataController?.save()
    }
    
    func handleAccuracy(foundBeacon: CLBeacon, persistedBeacon: Beacon, beacons: [CLBeacon], region: CLBeaconRegion) {
        //print("\(persistedBeacon.accuracy) \(foundBeacon.accuracy) \(foundBeacon.minor)")
        if let accuracyValue = persistedBeacon.accuracy?.doubleValue {
            if foundBeacon.accuracy < accuracyValue {
                if ([CLBeacon](self.currentlyInRegionBeacons.keys.filter{ self.eqaulBeacons(beaconA: $0, beaconB: foundBeacon) }).count <= 0) {
                    
                    self.currentlyInRegionBeacons[foundBeacon] = 1
                    self.delegate?.beaconFoundInCloseProximity(foundBeacon)
                    self.updateBeaconState(persistedBeacon, inProximity: true, inRange: nil)
                    
                    let alertTitle = persistedBeacon.notifyTitleNear ?? ""
                    let message = persistedBeacon.notifyTextNear ?? ""
                    
                    self.sendLocalNotificationWithMessage(persistedBeacon, alertTitle: alertTitle, message: message, distanceDetail: "near")
                }
            }
            else {
                var removeableBeacons: [CLBeacon] = []
                for beacon in self.currentlyInRegionBeacons.keys {
                    if beacon == foundBeacon {
                        if self.currentlyInRegionBeacons[beacon] <= -10 {
                            removeableBeacons.append(beacon)
                        }
                        else {
                            self.currentlyInRegionBeacons[beacon] = self.currentlyInRegionBeacons[beacon] <= -10 ? -10 : self.currentlyInRegionBeacons[beacon]! - 1
                        }
                    }
                }
                
                for beacon in removeableBeacons {
                    self.removeCurrentlyInRegionBeacons(beacon)

                    self.delegate?.beaconRemovedFromCloseProximity(beacon)
                    self.updateBeaconState(persistedBeacon, inProximity: false, inRange: nil)
                }
            }
        }
    }
    
    func eqaulBeacons(beaconA beaconA: CLBeacon, beaconB: CLBeacon) -> Bool {
        return beaconA.proximityUUID == beaconB.proximityUUID && beaconA.major == beaconB.major && beaconA.minor == beaconB.minor
    }
    
    func removeFromCurrentlyDetectedBeacons(beacon: CLBeacon) {
        var index: Int?
        let keys = [CLBeacon](self.currentlyDetectedBeacons.keys)
        for (idx, to) in keys.enumerate() {
            if eqaulBeacons(beaconA: beacon, beaconB: to) {
                index = idx
            }
        }
        
        if(index != nil) {
            self.currentlyDetectedBeacons.removeValueForKey(keys[index!])
        }
    }
    
    func removeCurrentlyInRegionBeacons(beacon: CLBeacon) {
        var index: Int?
        let keys = [CLBeacon](self.currentlyInRegionBeacons.keys)
        for (idx, to) in keys.enumerate() {
            if eqaulBeacons(beaconA: beacon, beaconB: to) {
                index = idx
            }
        }
        
        if(index != nil) {
            self.currentlyInRegionBeacons.removeValueForKey(keys[index!])
        }
    }
    
    func sendLocalNotificationWithMessage(persistedBeacon: Beacon, alertTitle: String, message: String, distanceDetail: String) {
        if notifactionEnabled {
            let notification:UILocalNotification = UILocalNotification()
            notification.alertAction = "Alert action"
            if #available(iOS 8.2, *) {
                notification.alertTitle = alertTitle
            } else {
                // Fallback on earlier versions
            }
            
            if let persistedBeaconId = persistedBeacon.id {
                let userInfo = ["beaconId": persistedBeaconId, "distanceDetail": distanceDetail]
                notification.userInfo = userInfo as [NSObject : AnyObject]
            }
            
            notification.alertBody = message
            UIApplication.sharedApplication().scheduleLocalNotification(notification)
            NSNotificationCenter.defaultCenter().postNotificationName(notificationKey, object: self)
        }
    }
    
    func getBeaconElement(beaconElement: BeaconElement, beacon: CLBeacon, persistedBeacon: Beacon?) -> String {
        if let persistedBeacon = persistedBeacon {
            switch(beaconElement) {
            case .CID:
                return persistedBeacon.companyId ?? ""
            case .MajorMinor:
                return "\(persistedBeacon.major ?? String()) \(persistedBeacon.minor ?? String())"
            case .NickName:
                return persistedBeacon.nickName ?? ""
            case .UUID:
                return persistedBeacon.uuid ?? ""
            case .None:
                return ""
            }
        }
        else {
            switch(beaconElement) {
            case .MajorMinor:
                return "\(beacon.major) \(beacon.minor)"
            case .UUID:
                return beacon.proximityUUID.UUIDString
            case .None:
                return ""
            default:
                return "Unkown"
            }
        }
    }
}

public func == (lhs: CLBeacon, rhs: CLBeacon) -> Bool {
    return((lhs.proximityUUID == rhs.proximityUUID) &&
        (lhs.major == rhs.major) &&
        (lhs.minor == rhs.minor))
}