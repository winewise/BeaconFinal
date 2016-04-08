//
//  MainTabBarController.swift
//  BeaconSearchApp
//
//  Created by Developer 1 on 2015-10-25.
//  Copyright © 2015 Ap1. All rights reserved.
//

import UIKit
import BeaconSearch

let Unknown = "Unknown"
let getAllBeaconsUrl = "http://159.203.15.175/filemaker/getAllBeacons_bid.php"
let getAllBeaconTypesUrl = "http://159.203.15.175/filemaker/getAllTypesv2.php"
let LastSyncDate = "LastSyncDate"

extension UIViewController {
    var findBeaconContext: FindBeacon? {
        get {
            return (self.tabBarController as? MainTabBarController)?.findBeacon
        }
    }
}

class MainTabBarController: UITabBarController, BeaconManagerDelegate {
    
    var findBeacon: FindBeacon?
    var foundBeacons: [CLBeacon] = []
    var persistedFoundBeacons: [CLBeacon] = []
    var storedBeacons: [CLBeacon : Beacon] = [:]
    var inLocationbeacons: [Beacon] = []
    var allBeacons: [Beacon] = []
    var closestBeacons: [CLBeacon] = []
    var beaconTypes: [BeaconType] = []
    
    
    var allCompanies: [Company] = []
    var companies: [String] = []
    var companyBeacons: [String: [Beacon]] = [:]
    var companyImages: [String: UIImage] = [:]
    var nearbyUserView: Bool = true
    
    weak var loginViewController: LoginViewController?
    var chatNavigationController: UINavigationController?
    var chatViewController: ChatViewController?
    var allBeaconsNavigationController: UINavigationController?
    var viewController: ViewController?
    var closestBeaconsNavigationController: UINavigationController?
    var closestBeaconsViewController: ClosestBeaconsViewController?
    var mapViewController: MapViewController?
    var companyBeaconsViewController: CompanyBeaconsViewController?
//    var settingsNavigationController: UINavigationController?
//    var settingsViewController: SettingsViewController?
    
    var writeAccess: Bool = false
    
    var uniqueFoundBeacons: [String] {
        get {
            let uniqueBeacons: [String] = Util.uniq(self.foundBeacons.map({ u in u.proximityUUID.UUIDString }))
            return uniqueBeacons
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if self.findBeacon == nil {
            self.findBeacon = FindBeacon(delegate: self)
        }
        
        if let allBeaconsNavigationController = self.storyboard?.instantiateViewControllerWithIdentifier("AllBeaconsNavigationController") as? UINavigationController, viewController = allBeaconsNavigationController.topViewController as? ViewController {
            self.allBeaconsNavigationController = allBeaconsNavigationController
            self.viewController = viewController
            self.viewController?.mainTabBarController = self
        }

        if let viewControllers = self.viewControllers {
            self.chatNavigationController = viewControllers[0] as? UINavigationController
            self.chatViewController = self.chatNavigationController?.topViewController as? ChatViewController
            self.chatViewController?.mainTabBarController = self
            
            self.closestBeaconsNavigationController = viewControllers[1] as? UINavigationController
            self.closestBeaconsViewController = self.closestBeaconsNavigationController?.topViewController as? ClosestBeaconsViewController
            self.closestBeaconsViewController?.mainTabBarController = self
            
            self.companyBeaconsViewController = (viewControllers[2] as? UINavigationController)?.topViewController as? CompanyBeaconsViewController
            self.companyBeaconsViewController?.mainTabBarController = self
            
            self.mapViewController = (viewControllers[3] as? UINavigationController)?.topViewController as? MapViewController
            self.mapViewController?.mainTabBarController = self
        }
        
        self.selectedIndex = 1
        
        if let _ = NSUserDefaults.standardUserDefaults().valueForKey(LastSyncDate) as? NSDate {
            self.loadDataInBackground()
        }
        else {
            self.loadData(true)
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func loadDataInBackground() {
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        if let findBeacon = self.findBeacon {
            self.beaconTypes = findBeacon.loadBeaconTypeData()
            let beaconData = findBeacon.loadBeaconData()
            self.allBeacons = beaconData
            self.updateCompanies()
            
            if let currentLocation = appDelegate.currentLocation {
                self.inLocationbeacons = findBeacon.beaconsInLocation(currentLocation, withInMeters: 10)
            }

            findBeacon.startScanning()
            self.update()
        }
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0)) {
            self.loadData(false)
        }
    }
    
    func loadData(indicator: Bool) {
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        
        if indicator {
            self.showLoading()
        }
        
        if let findBeacon = self.findBeacon {
            let bundleIdentifier = NSBundle.mainBundle().bundleIdentifier ?? ""
            findBeacon.getBeaconTypes(getAllBeaconTypesUrl, bundleId: bundleIdentifier, completionHandler: { (result, count) -> Void in
                print("BeaconType fetch \(result). Received \(count)")
                self.beaconTypes = findBeacon.loadBeaconTypeData()
                
                let bundleIdentifier = NSBundle.mainBundle().bundleIdentifier ?? ""
                findBeacon.updateBeaconData(getAllBeaconsUrl, bundleId: bundleIdentifier) { (result: Bool, beaconCount: Int) -> Void in
                    
                    NSUserDefaults.standardUserDefaults().setValue(NSDate(), forKey: LastSyncDate)
                    
                    self.findBeacon?.stopScanning()
                    self.foundBeacons.removeAll()
                    self.storedBeacons.removeAll()
                    self.allBeacons.removeAll()
                    self.closestBeacons.removeAll()
                    
                    print("Beacon fetch \(result). Received \(beaconCount)")
                    
                    let beaconData = findBeacon.loadBeaconData()
                    self.allBeacons = beaconData
                    
                    print("Total stored beacons in core data: \(beaconData.count)")
                    
                    let uniqueBeaconsIds = findBeacon.loadUniqueBeaconIdsByUdid()
                    print("Total unique beacons: \(uniqueBeaconsIds.count)")
                    
                    self.updateCompanies()
                    
                    if let currentLocation = appDelegate.currentLocation {
                        self.inLocationbeacons = findBeacon.beaconsInLocation(currentLocation, withInMeters: 10)
                    }
                    
                    dispatch_async(dispatch_get_main_queue(),{
                        findBeacon.startScanning()
                        
                        if indicator {
                            self.hideLoading()
                        }
                        
                        self.viewController?.refreshControl?.endRefreshing()
                        self.closestBeaconsViewController?.refreshControl?.endRefreshing()
                        
                        self.update()
                    })
                }
            })
        }
    }

    func updateProximity() {
        self.viewController?.update()
        self.closestBeaconsViewController?.update()
        self.mapViewController?.updateNearbyBeacons()
    }
    
    func reset() {
        self.loadData(true)
    }
    
    func reload() {
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        if let findBeacon = self.findBeacon {
            self.findBeacon?.stopScanning()
            self.foundBeacons.removeAll()
            self.storedBeacons.removeAll()
            self.allBeacons.removeAll()
            self.closestBeacons.removeAll()
            
        
            let beaconData = findBeacon.loadBeaconData()
            self.allBeacons = beaconData

            self.updateCompanies()
            
            if let currentLocation = appDelegate.currentLocation {
                self.inLocationbeacons = findBeacon.beaconsInLocation(currentLocation, withInMeters: 10)
            }
            
            findBeacon.startScanning()
            self.update()
        }
    }
    
    func update() {
        self.dataPreparationForCompanies()
        self.viewController?.update()
        self.closestBeaconsViewController?.update()
        self.companyBeaconsViewController?.update()
        self.mapViewController?.update()
    }

    func dataPreparationForCompanies() {
        self.companies.removeAll()
        self.companyBeacons.removeAll()

        for beacon in self.allBeacons {
            if beacon.companyName != nil && !beacon.companyName!.isEmpty {
                let companyName = beacon.companyName!
                if let _ = self.companyBeacons[companyName] {
                    self.companyBeacons[companyName]?.append(beacon)
                } else {
                    self.companyBeacons[companyName] = [beacon]
                    self.companies.append(companyName)
                    
                    var companyColor = UIColor.redColor()
                    if let colorHex = beacon.color, color = UIColor(hexString: colorHex) {
                        companyColor = color
                    }
                    
                    let companyChar = String(companyName.characters.first!).capitalizedString as NSString
                    self.companyImages[companyName] = Util.getImageWithColor(companyColor, drawText: companyChar, size: CGSizeMake(32, 32))
                }
            }
            else {
                if let _ = self.companyBeacons[Unknown] {
                    self.companyBeacons[Unknown]?.append(beacon)
                } else {
                    self.companyBeacons[Unknown] = [beacon]
                }
            }
        }
        
        self.companies.sortInPlace()
        
        if let _ = self.companyBeacons[Unknown] {
            self.companies.append(Unknown)
        }
        
        for company in self.companies {
            if let _ = self.companyBeacons[company] {
                self.companyBeacons[company]?.sortInPlace()
            }
            
            
        }
    }
    
    func beaconsForUdid(udid: String) -> [CLBeacon] {
        return self.foundBeacons.filter { beacon in
            return beacon.proximityUUID.UUIDString == udid
        }
    }
    
    func updateCompanies() {
        if let companies = self.findBeacon?.loadCompanyData() {
            self.allCompanies = companies
        }
    }
    
    // MARK:- BeaconManagerDelegate
    func beaconFound(beacon: CLBeacon, persistedBeacon: Beacon?) {
        self.foundBeacons.append(beacon)
        if let persistedBeaconValue = persistedBeacon {
            self.storedBeacons[beacon] = persistedBeaconValue
            //"Exist in database"
        }
        
        self.sortBeacons()
        self.updateProximity()
    }
    
    func beaconRemoved(beacon: CLBeacon, persistedBeacon: Beacon?) {
        self.foundBeacons.removeObject(beacon)
        self.storedBeacons.removeValueForKey(beacon)
        
        self.sortBeacons()
        self.updateProximity()
        
        self.postToKeen(persistedBeacon)
    }
    
    func postToKeen(persistedBeacon: Beacon?) {
        if let persistedBeacon = persistedBeacon {
            
            let beaconStateKeys = Array(persistedBeacon.beaconState!.entity.attributesByName.keys)
            let beaconStateDict = persistedBeacon.beaconState!.dictionaryWithValuesForKeys(beaconStateKeys)
            
            let beaconKeys = Array(persistedBeacon.entity.attributesByName.keys)
            var beaconDict = persistedBeacon.dictionaryWithValuesForKeys(beaconKeys)
            if let macAddress = beaconDict.removeValueForKey("macAddress") {
                beaconDict["device_macAddress"] = macAddress
            }
            
            var locationDict = ["latitude": 0.0, "longitude": 0.0]
            if let currentLocation = (UIApplication.sharedApplication().delegate as? AppDelegate)?.currentLocation {
                locationDict = ["latitude": currentLocation.coordinate.latitude, "longitude": currentLocation.coordinate.longitude]
            }
            
            let currentDevice = UIDevice.currentDevice()
            let deviceDict = ["macAddress": currentDevice.identifierForVendor!.UUIDString, "version": currentDevice.systemVersion, "OS": "iOS"]
            
            let event = ["device": deviceDict, "Beacon": beaconDict, "BeaconState": beaconStateDict, "location": locationDict]
            
            let keenProps : KeenProperties = KeenProperties()
            keenProps.timestamp = NSDate()
            keenProps.location = nil
            do {
                try KeenClient.sharedClient().addEvent(event, withKeenProperties: keenProps, toEventCollection: "proximity")
            }
            catch let error {
                print(error)
            }
            
            KeenClient.sharedClient().uploadWithFinishedBlock(nil)
        }
    }
    
    func beaconFoundInCloseProximity(beacon: CLBeacon) {
        self.removeBeaconInClosestBeacons(beacon)
        
        self.closestBeacons.append(beacon)
        self.updateBeaconState(beacon, allUpdate: true)
    }
    
    func beaconRemovedFromCloseProximity(beacon: CLBeacon) {
        self.removeBeaconInClosestBeacons(beacon)
        self.updateBeaconState(beacon, allUpdate: true)
    }
    
    func beaconUpdateAccuracy(beacon: CLBeacon) {
        self.updateBeaconState(beacon, allUpdate: false)
        self.viewController?.beaconDetailViewController?.updateAccuracy()
    }
    
    func updateBeaconState(beacon: CLBeacon, allUpdate: Bool) {
        var index: Int?
        let keys = [CLBeacon](self.storedBeacons.keys)
        for (idx, to) in keys.enumerate() {
            if beacon == to {
                index = idx
            }
        }
        
        if(index != nil) {
            if let value = self.storedBeacons.removeValueForKey(keys[index!]) {
                self.storedBeacons[beacon] = value
            }
        }
        
        for idx in self.foundBeacons.indices {
            if self.foundBeacons[idx] == beacon {
                self.foundBeacons[idx] = beacon
            }
        }
        
        if allUpdate {
            self.sortBeacons()
            self.updateProximity()
        }
    }
    
    func sortBeacons() {
        self.foundBeacons.sortInPlace { (beaconA: CLBeacon, beaconB: CLBeacon) -> Bool in
            return self.sortComparison(beaconA, beaconB: beaconB)
        }
        
        self.persistedFoundBeacons = Array(self.storedBeacons.keys)
        self.persistedFoundBeacons.sortInPlace { (beaconA: CLBeacon, beaconB: CLBeacon) -> Bool in
            return self.sortComparison(beaconA, beaconB: beaconB)
        }
    }
    
    func sortComparison(beaconA: CLBeacon, beaconB: CLBeacon) -> Bool {
        var accuracyA: Double = 0
        var accuracyB: Double = 0
        if self.storedBeacons[beaconA] == nil || beaconA.accuracy <= 0 {
            accuracyA = 800
        }
        else if let storedBeaconAValue = self.storedBeacons[beaconA]?.accuracy?.doubleValue {
            accuracyA = beaconA.accuracy <= storedBeaconAValue ? beaconA.accuracy : 600
        }
        else {
            accuracyA = beaconA.accuracy
        }
        
        if self.storedBeacons[beaconB] == nil || beaconB.accuracy <= 0 {
            accuracyB = 900
        }
        else if let storedBeaconBValue = self.storedBeacons[beaconB]?.accuracy?.doubleValue {
            accuracyB = beaconB.accuracy <= storedBeaconBValue ? beaconB.accuracy : 700
        }
        else {
            accuracyB = beaconB.accuracy
        }
        
        return accuracyA < accuracyB
    }
    
    func removeBeaconInClosestBeacons(beacon: CLBeacon) {
        var objectToRemove: CLBeacon?
        for addedBeacon in self.closestBeacons {
            if addedBeacon == beacon {
                objectToRemove = addedBeacon
                break
            }
        }
        
        if let objectToRemoveValue = objectToRemove {
            self.closestBeacons.removeObject(objectToRemoveValue)
        }
    }
    
    func updateNearbyView() -> Bool {
        self.nearbyUserView = !self.nearbyUserView
        let nearbyTab = self.nearbyUserView ? self.closestBeaconsNavigationController : self.allBeaconsNavigationController
        self.viewControllers = [self.viewControllers![0], nearbyTab!, self.viewControllers![2], self.viewControllers![3]]
        
        return self.nearbyUserView
    }
    
    func loadWebViewFromReceiveLocalNotification(beaconId: String, distanceDetail: String) {
        let beacons = Array(self.storedBeacons.values)
            if let _ = beacons.filter({$0.id == beaconId}).first {
            self.selectedIndex = 1
            self.allBeaconsNavigationController?.presentedViewController?.dismissViewControllerAnimated(true, completion: nil)
            self.allBeaconsNavigationController?.popToRootViewControllerAnimated(true)
            self.closestBeaconsNavigationController?.popToRootViewControllerAnimated(true)
            if !self.nearbyUserView {
                self.updateNearbyView()
            }
            
            self.closestBeaconsViewController?.openUrlForBeaconId(beaconId, distanceDetail: distanceDetail)
        }
    }
    
    func getBeaconManufacturer(key: String) -> String? {
        return self.beaconTypes.filter { $0.uuid != nil && !$0.uuid!.isEmpty && $0.uuid! == key }.first?.manufacturer
    }
    
    func logout() {
        self.chatViewController?.stop()
        self.loginViewController?.mainTabBarController = nil
        self.findBeacon?.stopScanning()
        PFUser.logOut()
        self.findBeacon = nil
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    override func supportedInterfaceOrientations() -> UIInterfaceOrientationMask {
        if UIDevice.currentDevice().userInterfaceIdiom == .Phone {
            return UIInterfaceOrientationMask.Portrait
        }
        
        return UIInterfaceOrientationMask.AllButUpsideDown
    }
}

extension Double {
    func string(fractionDigits: Int) -> String {
        let formatter = NSNumberFormatter()
        formatter.minimumIntegerDigits = 1
        formatter.minimumFractionDigits = fractionDigits
        formatter.maximumFractionDigits = fractionDigits
        return formatter.stringFromNumber(self) ?? "\(self)"
    }
}