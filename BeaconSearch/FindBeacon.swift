//
//  findBeacon.swift
//  beaconSearchFramework
//
//  Created by Developer 1 on 2015-08-24.
//  Copyright © 2015 Ap1. All rights reserved.
//

import Foundation

/// Powerful beacon manager for managing and detecting beacons.
public class FindBeacon: BeaconDataHandler {
    // MARK:- Variables
    private var beaconManager: BeaconManager?
    private var delegate: BeaconManagerDelegate?
    
    /**
     Initializes a new FindBeacon with the provided delegate.
     
     - Parameters:
     - delegate: BeaconManagerDelegate
     - Returns: FindBeacon object.
     */
    public init (delegate: BeaconManagerDelegate?) {
        super.init()
        self.delegate = delegate
    }
    
    /// Start scanning for unique beacons by UDID. Call this method after updateBeaconData method completionHandler return with true. This method will start invoking BeaconManagerDelegate methods.
    public func startScanning() {
        self.beaconManager = BeaconManager()
        self.beaconManager?.notifactionEnabled = self.notifactionEnabled
        self.beaconManager?.notificationTitle = self.notificationTitle
        self.beaconManager?.notificationDetail = self.notificationDetail
        
        self.beaconManager?.findBeacon = self
        self.beaconManager?.delegate = self.delegate
        var UniqueBeaconIds = self.loadUniqueBeaconTypeUdids()
        UniqueBeaconIds.append(genericProximityUUID)
        self.beaconManager?.setupRegions(UniqueBeaconIds, identifier: identifier)
    }
    
    /// Stop scanning for all the beacons.
    public func stopScanning() {
        self.beaconManager?.delegate = nil
        self.beaconManager?.stopMonitoring()
    }
    
    public func updateBeaconState(persistedBeacon: Beacon, inProximity: Bool?, inRange: Bool?) {
        self.beaconManager?.updateBeaconState(persistedBeacon, inProximity: inProximity, inRange: inRange)
    }
}