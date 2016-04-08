//
//  BeaconDataHandler.swift
//  BeaconSearchApp
//
//  Created by Hafiz Usama on 2016-02-07.
//  Copyright © 2016 Ap1. All rights reserved.
//

import Foundation
import CoreData
import CoreLocation

let identifier = "Ap1"
let genericProximityUUID = "E2C56DB5-DFFB-48D2-B060-D0F5A71096E0"

/**
 Beacon elements for notification settings. e.g. Alert title and body.
 
 - CID: Will only work for persisted beacon otherwise returns "Unkown".
 - UUID: Proximity UUID.
 - MajorMinor: Major and minor value separated by space.
 - NickName: Will only work for persisted beacon otherwise returns "Unkown".
 - None
 */
public enum BeaconElement {
    case CID
    case UUID
    case MajorMinor
    case NickName
    case None
}

/// Powerful beacon data handler for managing beacons.
public class BeaconDataHandler: NSObject {
    // MARK:- Variables
    var dataController: DataController?
    
    /// Local notification turn on off flag
    public var notifactionEnabled = true
    
    /// Local notification alert title element
    public var notificationTitle: BeaconElement = .NickName
    
    /// Local notification alert or badge body element
    public var notificationDetail: BeaconElement = .MajorMinor
    
    // MARK:- Public Methods
    
    /**
    Initializes a new BeaconDataHandler.
    */
    public override init () {
        super.init()
        self.setup()
    }
    
    /**
     Fetch all the beacon data from provided url and update database. Call this as first method after the initialization of FindBeacon.
     
     - Parameters:
     - url: Url to fetch beacons data from server for hash and/or beacons.
     - bundleId: App bundle identifier for beacon classification.
     - completionHandler: It will return a boolean and interger. Boolean tells if the response against provided url was sucessful. Integer value tells how many beacons recevied. If Boolean is true and integer showing zero that means hash is same and no data changed on the server since last fetch.
     
     - Returns: Void.
     */
    public func updateBeaconData(url: String, bundleId: String, completionHandler: ((Bool, Int) -> Void)) {
        let myUrl = NSURL(string: url)
        let request = NSMutableURLRequest(URL: myUrl!)
        request.HTTPMethod = "POST"
        
        let bidString = "bid=\(bundleId)"
        if let hashValue = self.getHash() {
            let postString = "hash=\(hashValue)&\(bidString)"
            request.HTTPBody = postString.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)
        }
        else {
            request.HTTPBody = bidString.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)
        }
        
        let task = NSURLSession.sharedSession().dataTaskWithRequest(request) {
            data, response, error in
            
            if error != nil {
                print("error=\(error)")
                completionHandler(false, 0)
                return
            }
            
            // To print response string
            if let responseString = NSString(data: data!, encoding: NSUTF8StringEncoding) {
                // Same hash. No data received in this case. No need to update beacon data.
                if responseString == "1" {
                    completionHandler(true, 0)
                    return
                }
            }
            
            var success = true
            let jsonObjects: AnyObject?
            var beaconCount = 0
            do {
                jsonObjects = try NSJSONSerialization.JSONObjectWithData(data!, options: .MutableLeaves)
                
                if let allObjects = jsonObjects as? Dictionary<String, AnyObject> {
                    if let currentHash = allObjects["hash"] as? String {
                        if !self.hashExists(currentHash) {
                            
                            self.dataController?.deleteAll()
                            self.insertHashStateValue(currentHash)
                            
                            if let companyItems = allObjects["companies"] as? Array<AnyObject> {
                                for item in companyItems {
                                    if item["id"] != nil {
                                        self.dataController!.managedObjectContext.performBlockAndWait { () -> Void in
                                            let company = NSEntityDescription.insertNewObjectForEntityForName("Company", inManagedObjectContext: self.dataController!.managedObjectContext) as! Company
                                            
                                            company.id = item["id"] as? String ?? ""
                                            company.name = item["company"] as? String ?? ""
                                            company.color  = item["color"] as? String ?? ""
                                            company.idHash  = item["hash"] as? String ?? ""
                                            company.latitude  = item["lat"] as? String ?? ""
                                            company.longitude  = item["long"] as? String ?? ""
                                        }
                                    }
                                }
                            }
                            
                            if let beaconObjects = allObjects["beacons"] as? Array<AnyObject> {
                                beaconCount = beaconObjects.count
                                for item in beaconObjects {
                                    if item["uuid"] != nil {
                                        self.dataController!.managedObjectContext.performBlockAndWait { () -> Void in
                                            let beacon = NSEntityDescription.insertNewObjectForEntityForName("Beacon", inManagedObjectContext: self.dataController!.managedObjectContext) as! Beacon
                                            
                                            beacon.id = item["id"] as? String ?? ""
                                            beacon.uuid = item["uuid"] as? String ?? ""
                                            beacon.major  = item["major"] as? String ?? ""
                                            beacon.minor = item["minor"] as? String ?? ""
                                            beacon.latitude = item["lat"] as? String ?? ""
                                            beacon.longitude = item["long"] as? String ?? ""
                                            beacon.unit = item["unit"] as? String ?? ""
                                            beacon.nickName = item["nickname"] as? String ?? ""
                                            beacon.rssi = item["rssi"] as? String ?? ""
                                            if let accuracy = item["accuracy"] as? String, accuracyDouble = Double(accuracy) {
                                                beacon.accuracy = NSNumber(double: accuracyDouble)
                                            }
                                            
                                            beacon.companyId = item["idcompany"] as? String ?? ""
                                            beacon.companyName = item["companyname"] as? String ?? ""
                                            beacon.color = item["color"] as? String ?? ""
                                            beacon.macAddress = item["macAddress"] as? String ?? ""
                                            if let dateString = item["createdDate"] as? String {
                                                let dateFormatter = NSDateFormatter()
                                                dateFormatter.dateFormat = "yyyy\\/MM\\/dd hh:mm:ss"
                                                beacon.createdOn = dateFormatter.dateFromString(dateString)
                                            }
                                            
                                            beacon.urlNear = item["urlnear"] as? String ?? ""
                                            beacon.urlFar = item["urlfar"] as? String ?? ""
                                            beacon.notifyTitleFar = item["notifytitle"] as? String ?? ""
                                            beacon.notifyTextFar = item["notifytext"] as? String ?? ""
                                            beacon.notifyTitleNear = item["notifytitlenear"] as? String ?? ""
                                            beacon.notifyTextNear = item["notifytextnear"] as? String ?? ""
                                        }
                                    }
                                }
                                
                                self.dataController!.managedObjectContext.performBlockAndWait { () -> Void in
                                    self.dataController?.save()
                                }
                            }
                        }
                    }
                }
            }
            catch _ {
                jsonObjects = nil
                success = false
            }
            
            self.loadAndSaveUrlContent(self.loadBeaconData())
            
            completionHandler(success, beaconCount)
        }
        
        task.resume()
    }
    
    /**
     When url response returns valid company objects it deletes all the existing companies. Add all the companies in core data from latest fetch.
     
     - Parameters:
     - url: Url to fetch company data from server.
     - bundleId: App bundle identifier for beacon classification.
     - completionHandler: It will return a boolean and interger. Boolean tells if the response against provided url was sucessful. Integer value tells how many companies recevied.
     
     - Returns: Void.
     */
    public func updateCompanyData(url: String, bundleId: String, completionHandler: ((Bool, Int) -> Void)) {
        let myUrl = NSURL(string: url)
        let request = NSMutableURLRequest(URL: myUrl!)
        request.HTTPMethod = "POST"
        let postString = "bid=\(bundleId)"
        request.HTTPBody = postString.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)
        
        let task = NSURLSession.sharedSession().dataTaskWithRequest(request) {
            data, response, error in
            
            if error != nil {
                print("error=\(error)")
                completionHandler(false, 0)
                return
            }
            
            var success = true
            let jsonObjects: AnyObject?
            var companyCount = 0
            do {
                jsonObjects = try NSJSONSerialization.JSONObjectWithData(data!, options: .MutableLeaves)
                
                if let responseDictionary = jsonObjects as? NSDictionary, companyItems = responseDictionary["companies"] as? Array<NSDictionary> {
                    
                    self.dataController!.managedObjectContext.performBlockAndWait { () -> Void in
                        if companyItems.count > 0 {
                            self.dataController?.deleteAllCompanies()
                            companyCount = companyItems.count
                            for item in companyItems {
                                if item["id"] != nil {
                                    let company = NSEntityDescription.insertNewObjectForEntityForName("Company", inManagedObjectContext: self.dataController!.managedObjectContext) as! Company
                                    
                                    company.id = item["id"] as? String ?? ""
                                    company.name = item["company"] as? String ?? ""
                                    company.color  = item["color"] as? String ?? ""
                                    company.idHash  = item["hash"] as? String ?? ""
                                    company.latitude  = item["lat"] as? String ?? ""
                                    company.longitude  = item["long"] as? String ?? ""
                                }
                            }
                        }
                        
                        self.dataController?.save()
                    }
                }
            }
            catch _ {
                jsonObjects = nil
                success = false
            }
            
            completionHandler(success, companyCount)
        }
        
        task.resume()
    }
    
    /**
     Fectch all the beacon types from backend and store it to core data.
     
     - Parameters:
     - url: Url to fetch company data from server.
     - bundleId: App bundle identifier for beacon classification.
     - completionHandler: It will return a boolean and interger. Boolean tells if the response against provided url was sucessful. Integer value tells how many beacon types recevied.
     
     - Returns: Void.
     */
    public func getBeaconTypes(url: String, bundleId: String, completionHandler: ((Bool, Int) -> Void)) {
        let myUrl = NSURL(string: url)
        let request = NSMutableURLRequest(URL: myUrl!)
        request.HTTPMethod = "POST"
        let postString = "bid=\(bundleId)"
        request.HTTPBody = postString.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)
        
        let task = NSURLSession.sharedSession().dataTaskWithRequest(request) {
            data, response, error in
            
            if error != nil {
                print("error=\(error)")
                completionHandler(false, 0)
                return
            }
            
            var success = true
            var jsonObjects: AnyObject?
            var beaconTypeCount = 0
            do {
                jsonObjects = try NSJSONSerialization.JSONObjectWithData(data!, options: .MutableLeaves)
                
                if let beaconTypeItems = jsonObjects as? Array<AnyObject> {
                    
                    self.dataController!.managedObjectContext.performBlockAndWait { () -> Void in
                        if beaconTypeItems.count > 0 {
                            self.dataController?.deleteAllBeaconTypes()
                            beaconTypeCount = beaconTypeItems.count
                            for item in beaconTypeItems {
                                if item["id"] != nil {
                                    let beaconType = NSEntityDescription.insertNewObjectForEntityForName("BeaconType", inManagedObjectContext: self.dataController!.managedObjectContext) as! BeaconType
                                    
                                    beaconType.id = item["id"] as? String ?? ""
                                    beaconType.uuid = item["uuid"] as? String ?? ""
                                    beaconType.manufacturer  = item["manufacturer"] as? String ?? ""
                                    beaconType.type  = item["type"] as? String ?? ""
                                    beaconType.visible  = Util.convertToBool(item["visible"] as? String ?? "1")
                                    beaconType.usable  = Util.convertToBool(item["usable"] as? String ?? "1")
                                }
                            }
                        }
                        
                        self.dataController?.save()
                    }
                }
            }
            catch _ {
                jsonObjects = nil
                success = false
            }
            
            completionHandler(success, beaconTypeCount)
        }
        
        task.resume()
    }
    
    
    /**
     Add beacon to server database
     
     - Parameters:
     - completionHandler: Returns true when operation completed successfully; false otherwise with message.
     
     - Returns: Void.
     */
    public func addBeacon(urlString: String, username: String, uuid: String, major: String, minor: String, accuracy: String, rssi: String, macAddress: String, nickName: String, lat: String, long: String, urlFar: String, urlNear: String, companyId: String, notifyTitleFar: String, notifyTextFar: String, notifyTitleNear: String, notifyTextNear: String, completionHandler: ((Bool, String) -> Void)) {
        
        let myUrl = NSURL(string: urlString)
        let request = NSMutableURLRequest(URL: myUrl!)
        request.HTTPMethod = "POST"
        
        let postString = "uuid=\(uuid)&major=\(major)&minor=\(minor)&rssi=\(rssi)&macAddress=\(macAddress)&nickname=\(nickName)&lat=\(lat)&long=\(long)&urlfar=\(urlFar)&urlnear=\(urlNear)&hash=\(companyId)&notifytitle=\(notifyTitleFar)&notifytext=\(notifyTextFar)&notifytitlenear=\(notifyTitleNear)&notifytextnear=\(notifyTextNear)&accuracy=\(accuracy)&user=\(username)"
        
        request.HTTPBody = postString.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)
        let task = NSURLSession.sharedSession().dataTaskWithRequest(request) {
            data, response, error in
            
            if error != nil {
                completionHandler(false, error!.description)
                return
            }
            
            var jsonObjects: AnyObject?
            
            do {
               jsonObjects = try NSJSONSerialization.JSONObjectWithData(data!, options: .MutableLeaves)

                if let dictionary = jsonObjects as? Dictionary<String, AnyObject> {
                    // Same hash. No data received in this case. No need to update beacon data.
                    if let success = dictionary["success"] as? Int {
                        if let idbeacon = dictionary["idbeacon"] as? String where success == 1 {
                            self.dataController!.managedObjectContext.performBlockAndWait { () -> Void in
                                let beacon = NSEntityDescription.insertNewObjectForEntityForName("Beacon", inManagedObjectContext: self.dataController!.managedObjectContext) as! Beacon
                                
                                beacon.id = idbeacon
                                beacon.uuid = uuid
                                beacon.major  = major
                                beacon.minor = minor
                                beacon.latitude = lat
                                beacon.longitude = long
                                beacon.unit = ""
                                beacon.nickName = nickName
                                beacon.rssi = ""
                                if let accuracyDouble = Double(accuracy) {
                                    beacon.accuracy = NSNumber(double: accuracyDouble)
                                }
                                
                                beacon.companyId = companyId
                                beacon.companyName = ""
                                beacon.color = ""
                                beacon.macAddress = ""
                                beacon.createdOn = NSDate()
                                
                                beacon.urlNear = urlNear
                                beacon.urlFar = urlFar
                                beacon.notifyTitleFar = notifyTitleFar
                                beacon.notifyTextFar = notifyTextFar
                                beacon.notifyTitleNear = notifyTitleNear
                                beacon.notifyTextNear = notifyTextNear
                                
                                self.dataController?.save()
                                completionHandler(true, "Beacon Added")
                            }
                        }
                        else if success == 2 {
                            completionHandler(false, "Apengage showcase is limited to 3 deployed beacons, please remove a beacon and try again")
                        }
                        else {
                            completionHandler(false, "Error")
                        }
                    }
                    else {
                        completionHandler(false, "Error")
                    }
                }
                else {
                    completionHandler(false, "Error")
                }
            }
            catch _ {
                jsonObjects = nil
                completionHandler(false, "Error")
            }
        }
        
        task.resume()
    }
    
    /**
     Update beacon to server database
     
     - Parameters: Limited parameters related to location only.
     - completionHandler: Returns true when operation completed successfully; false otherwise with message.
     
     - Returns: Void.
     */
    public func updateBeacon(urlString: String, username: String, beacon: Beacon, lat: String, long: String, completionHandler: ((Bool, String) -> Void)) {
        self.updateBeacon(urlString, username: username, beaconId: beacon.id ?? "", uuid: beacon.uuid ?? "", major: beacon.major ?? "", minor: beacon.minor ?? "", accuracy: beacon.accuracy?.stringValue ?? "", rssi: beacon.rssi ?? "", macAddress: beacon.macAddress ?? "", nickName: beacon.nickName ?? "", lat: lat, long: long, urlFar: beacon.urlFar ?? "", urlNear: beacon.urlNear ?? "", companyId: beacon.companyId ?? "", notifyTitle: beacon.notifyTitleFar ?? "", notifyText: beacon.notifyTextFar ?? "")
            { result, message in
                if result {
                    beacon.latitude = lat
                    beacon.longitude = long
                    self.dataController?.save()
                    
                    completionHandler(result, message)
                }
                else {
                    completionHandler(result, message)
                }
        }
    }
    
    /**
     Update beacon to server database
     
     - Parameters: All parameters.
     - completionHandler: Returns true when operation completed successfully; false otherwise with message.
     
     - Returns: Void.
     */
    public func updateBeacon(urlString: String, username: String, beaconId: String, uuid: String, major: String, minor: String, accuracy: String, rssi: String, macAddress: String, nickName: String, lat: String, long: String, urlFar: String, urlNear: String, companyId: String, notifyTitle: String, notifyText: String, completionHandler: ((Bool, String) -> Void)) {
        
        let myUrl = NSURL(string: urlString)
        let request = NSMutableURLRequest(URL: myUrl!)
        request.HTTPMethod = "POST"
        
        let postString = "id=\(beaconId)&uuid=\(uuid)&major=\(major)&minor=\(minor)&rssi=\(rssi)&macAddress=\(macAddress)&nickname=\(nickName)&lat=\(lat)&long=\(long)&urlfar=\(urlFar)&urlnear=\(urlNear)&idcompany=\(companyId)&notifytitle=\(notifyTitle)&notifytext=\(notifyText)&accuracy=\(accuracy)&user=\(username)"
        
        request.HTTPBody = postString.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)
        
        let task = NSURLSession.sharedSession().dataTaskWithRequest(request) {
            data, response, error in
            
            if error != nil {
                completionHandler(false, error!.description)
                return
            }
            
            do {
                if let responseString = NSString(data: data!, encoding: NSUTF8StringEncoding) {
                    // Same hash. No data received in this case. No need to update beacon data.
                    if responseString == "1" {
                        completionHandler(true, "Beacon Updated")
                    }
                    else {
                        completionHandler(false, "Error")
                    }
                }
            }
        }
        
        task.resume()
    }
    
    /**
     Update beacon seen state to core data.
     
     - Parameters:
     - persistedBeacon: Core data beacon object.
     - near: Found in near range flag.
     - far: Found in far range flag.
     
     - Returns: Void.
     */
    public func updateBeaconSeenState(persistedBeacon: Beacon, near: Bool, far: Bool) {
        self.dataController!.managedObjectContext.performBlockAndWait { () -> Void in
            if persistedBeacon.beaconState == nil {
                persistedBeacon.beaconState = NSEntityDescription.insertNewObjectForEntityForName("BeaconState", inManagedObjectContext: self.dataController!.managedObjectContext) as? BeaconState
            }
            
            let date = NSDate()
            
            if near {
                persistedBeacon.beaconState?.lastSeenNear = date
            }
            
            if far {
                persistedBeacon.beaconState?.lastSeenFar = date
            }
        }
        
        self.dataController?.save()
    }
    
    /**
     Delete beacon from server database
     
     - Parameters:
     - url: Url for making service call to delete the beacon.
     - bundleId: App bundle identifier for beacon classification.
     - username: username.
     - beaconId: Beacon id.
     - completionHandler: Returns true when operation completed successfully.
     */
    public func deleteBeacon(urlString: String, bundleId: String, username: String, beaconId: String, completionHandler: ((Bool) -> Void)) {
        
        let myUrl = NSURL(string: urlString)
        let request = NSMutableURLRequest(URL: myUrl!)
        request.HTTPMethod = "POST"
        
        let postString = "id=\(beaconId)&user=\(username)&bid=\(bundleId)"
        
        request.HTTPBody = postString.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)
        
        let task = NSURLSession.sharedSession().dataTaskWithRequest(request) {
            data, response, error in
            
            if error != nil {
                completionHandler(false)
                return
            }
            
            if let responseString = NSString(data: data!, encoding: NSUTF8StringEncoding) {
                if responseString == "1" || responseString.containsString("1") {
                    self.dataController?.deleteBeacon(beaconId)
                    completionHandler(true)
                }
                else {
                    completionHandler(false)
                }
            }
        }
        
        task.resume()
    }
    
    /**
     Add company to server database
     
     - Parameters:
     - completionHandler: Returns true when operation completed successfully; false otherwise with message.
     */
    public func addCompany(urlString: String, username: String, bundleId: String, companyName: String, color: String, latitude: String, longitude: String, completionHandler: ((Bool, String) -> Void)) {
        
        let myUrl = NSURL(string: urlString)
        let request = NSMutableURLRequest(URL: myUrl!)
        request.HTTPMethod = "POST"
        
        let postString = "bid=\(bundleId)&company=\(companyName)&color=\(color)&lat=\(latitude)&long=\(longitude)&user=\(username)"
        
        request.HTTPBody = postString.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)
        
        let task = NSURLSession.sharedSession().dataTaskWithRequest(request) {
            data, response, error in
            
            if error != nil {
                completionHandler(false, error!.description)
                return
            }
            
            do {
                if let responseString = NSString(data: data!, encoding: NSUTF8StringEncoding) {
                    // Same hash. No data received in this case. No need to update beacon data.
                    if responseString == "1" {
                        completionHandler(true, "Company Added")
                    }
                    else {
                        completionHandler(false, "Error")
                    }
                }
            }
        }
        
        task.resume()
    }
    
    /**
     Update company to server database
     
     - Parameters:
     - completionHandler: Returns true when operation completed successfully; false otherwise with message.
     */
    public func updateCompany(urlString: String, company: Company, hasdId: String, companyName: String, color: String, latitude: String, longitude: String, completionHandler: ((Bool, String) -> Void)) {
        
        let myUrl = NSURL(string: urlString)
        let request = NSMutableURLRequest(URL: myUrl!)
        request.HTTPMethod = "POST"
        
        let postString = "hash=\(hasdId)&company=\(companyName)&color=\(color)&lat=\(latitude)&long=\(longitude)"
        
        request.HTTPBody = postString.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)
        
        let task = NSURLSession.sharedSession().dataTaskWithRequest(request) {
            data, response, error in
            
            if error != nil {
                completionHandler(false, error!.description)
                return
            }
            
            do {
                if let responseString = NSString(data: data!, encoding: NSUTF8StringEncoding) {
                    // Same hash. No data received in this case. No need to update beacon data.
                    if responseString == "1" {
                        self.dataController!.managedObjectContext.performBlockAndWait { () -> Void in
                            company.name = companyName
                            company.color = color
                            company.latitude = latitude
                            company.longitude = longitude
                        }
                        
                        self.dataController?.save()
                        
                        completionHandler(true, "Company Edited")
                    }
                    else {
                        completionHandler(false, "Error")
                    }
                }
            }
        }
        
        task.resume()
    }
    
    /**
     Delete company from server database
     
     - Parameters:
     - urlString: Url for making service call to delete the company.
     - username: Username.
     - company: Core data company object.
     - completionHandler: Returns true when operation completed successfully.
     */
    public func deleteCompany(urlString: String, username: String, company: Company, completionHandler: ((Bool) -> Void)) {
        
        let myUrl = NSURL(string: urlString)
        let request = NSMutableURLRequest(URL: myUrl!)
        request.HTTPMethod = "POST"
        
        let postString = "hash=\(company.idHash ?? "")&user=\(username)"
        
        request.HTTPBody = postString.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)
        
        let task = NSURLSession.sharedSession().dataTaskWithRequest(request) {
            data, response, error in
            
            if error != nil {
                completionHandler(false)
                return
            }
            
            if let responseString = NSString(data: data!, encoding: NSUTF8StringEncoding) {
                if responseString == "1" || responseString.containsString("1") {
                    self.dataController?.deleteCompany(company)
                    completionHandler(true)
                }
                else {
                    completionHandler(false)
                }
            }
        }
        
        task.resume()
    }
    
    /**
     Loads all the beacon objects from local storage.
     
     - Returns: An array of beacon objects.
     */
    public func loadBeaconData() -> [Beacon] {
        var beacons: [Beacon] = []
        self.dataController!.managedObjectContext.performBlockAndWait { () -> Void in
            let moc = self.dataController?.managedObjectContext
            let beaconsFetch = NSFetchRequest(entityName: "Beacon")
            
            do {
                let fetchedBeacons = try moc!.executeFetchRequest(beaconsFetch) as! [Beacon]
                
                beacons = fetchedBeacons
            } catch {
                beacons = []
            }
        }
        
        return beacons
    }
    
    /**
     Loads all the company objects from local storage.
     
     - Returns: An array of company objects.
     */
    public func loadCompanyData() -> [Company] {
        var companies: [Company] = []
        self.dataController!.managedObjectContext.performBlockAndWait { () -> Void in
            let moc = self.dataController?.managedObjectContext
            let companiesFetch = NSFetchRequest(entityName: "Company")
            
            do {
                let fetchedCompanies = try moc!.executeFetchRequest(companiesFetch) as! [Company]
                
                companies = fetchedCompanies
            } catch {
                companies = []
            }
        }
        
        return companies
    }
    
    /**
     Loads all the beacon type objects from local storage.
     
     - Returns: An array of beacon type objects.
     */
    public func loadBeaconTypeData() -> [BeaconType] {
        var beaconTypes: [BeaconType] = []
        self.dataController!.managedObjectContext.performBlockAndWait { () -> Void in
            let moc = self.dataController?.managedObjectContext
            let companiesFetch = NSFetchRequest(entityName: "BeaconType")
            
            do {
                let fetchedBeaconTypes = try moc!.executeFetchRequest(companiesFetch) as! [BeaconType]
                
                beaconTypes = fetchedBeaconTypes
            } catch {
                beaconTypes = []
            }
        }
        
        return beaconTypes
    }
    
    /**
     Loads all the unique beacon type UDID from local storage.
     
     - Returns: An array of beacon type UDID strings.
     */
    public func loadUniqueBeaconTypeUdids() -> [String] {
        let allBeaconTypes = self.loadBeaconTypeData()
        let uniqueBeacons: [String] = Util.uniq(allBeaconTypes.map({ u in u.uuid! }))
        return uniqueBeacons
    }
    
    /**
     Find all the beacons in local storage that are tagged in certain location.
     
     - Parameters:
     - location: Location for which all the stored beacons compared against by their latitude and longitude attributes.
     - withInMeters: Minimum distance from provided location
     
     - Returns: An array of found beacons.
     */
    public func beaconsInLocation(location: CLLocation, withInMeters: Double) -> [Beacon] {
        let beacons = self.loadBeaconData()
        var beaconsInLocation: [Beacon] = []
        for beacon in beacons {
            if let latValue = beacon.latitude, lngValue = beacon.longitude, lat = Double(latValue), lng = Double(lngValue) {
                let beaconLocation = CLLocation(latitude: lat, longitude: lng)
                if location.distanceFromLocation(beaconLocation) <= withInMeters {
                    beaconsInLocation.append(beacon)
                }
            }
        }
        
        return beaconsInLocation
    }
    
    /**
     Loads all the unique beacon by udid.
     
     - Returns: An array of beacon udids.
     */
    public func loadUniqueBeaconIdsByUdid() -> [String] {
        let allBeacons = self.loadBeaconData()
        let uniqueBeacons: [String] = Util.uniq(allBeacons.map({ u in u.uuid! }))
        return uniqueBeacons
    }
    
    /**
     Find the beacon in local storage.
     
     - Parameters:
     - uuid: Proximity uuid.
     - major: Beacon major value.
     - minor: Beacon minor value.
     
     - Returns: Beacon object if found; nil otherwise.
     */
    public func findBeacon(uuid: String, major: String, minor: String) -> Beacon? {
        var beacon: Beacon?
        self.dataController!.managedObjectContext.performBlockAndWait { () -> Void in
            let moc = self.dataController?.managedObjectContext
            let beaconsFetch = NSFetchRequest(entityName: "Beacon")
            let uuidPredicate = NSPredicate(format: "uuid == %@", uuid)
            let majorPredicate = NSPredicate(format: "major == %@", major)
            let minorPredicate = NSPredicate(format: "minor == %@", minor)
            let compoundPredicate = NSCompoundPredicate(andPredicateWithSubpredicates: [uuidPredicate, majorPredicate, minorPredicate])
            beaconsFetch.predicate = compoundPredicate
            
            do {
                if let fetchedBeacons = try moc!.executeFetchRequest(beaconsFetch) as? [Beacon] {
                    beacon = fetchedBeacons.count > 0 ? fetchedBeacons[0] : nil
                }
                else {
                    beacon = nil
                }
            } catch {
                beacon = nil
            }
        }
        
        return beacon
    }
    
    /**
     Fetch all url's data for given beacon and store in to local storage.
     
     - Parameters:
     - beacon: Core data beacon object.
     
     - Returns: void.
     */
    public func updateUrlContent(beacon: Beacon) {
        if let urlNearString = beacon.urlNear, urlNear = NSURL(string: urlNearString) {
            
            if beacon.urlNearContent == nil {
                let urlNearContent = NSEntityDescription.insertNewObjectForEntityForName("UrlContent", inManagedObjectContext: self.dataController!.managedObjectContext) as! UrlContent
                beacon.urlNearContent = urlNearContent
            }
            
            do {
                let request: NSURLRequest = NSURLRequest(URL: urlNear)
                let response: AutoreleasingUnsafeMutablePointer<NSURLResponse? >= nil
                let dataValue: NSData =  try NSURLConnection.sendSynchronousRequest(request, returningResponse: response)
                beacon.urlNearContent?.html = dataValue
            }
            catch let error as NSError {
                if let errorDescription = error.userInfo["NSLocalizedDescription"] as? String {
                    beacon.urlNearContent?.errorCode = error.code.description
                    beacon.urlNearContent?.errorDescription = errorDescription
                }
            }
        }
        
        if let urlFarString = beacon.urlFar, urlFar = NSURL(string: urlFarString) {
            if beacon.urlFarContent == nil {
                let urlFarContent = NSEntityDescription.insertNewObjectForEntityForName("UrlContent", inManagedObjectContext: self.dataController!.managedObjectContext) as! UrlContent
                beacon.urlFarContent = urlFarContent
            }
            
            do {
                let request: NSURLRequest = NSURLRequest(URL: urlFar)
                let response: AutoreleasingUnsafeMutablePointer<NSURLResponse? >= nil
                let dataValue: NSData =  try NSURLConnection.sendSynchronousRequest(request, returningResponse: response)
                beacon.urlFarContent?.html = dataValue
            }
            catch let error as NSError {
                if let errorDescription = error.userInfo["NSLocalizedDescription"] as? String {
                    beacon.urlFarContent?.errorCode = error.code.description
                    beacon.urlFarContent?.errorDescription = errorDescription
                }
            }
        }
        
        self.dataController!.managedObjectContext.performBlockAndWait { () -> Void in
            self.dataController?.save()
        }
    }
    
    // MARK:- Private Methods
    internal func setup() {
        self.dataController = DataController()
    }
    
    private func getHash() -> String? {
        var value: String?
        self.dataController!.managedObjectContext.performBlockAndWait { () -> Void in
            let moc = self.dataController?.managedObjectContext
            let hashStateFetch = NSFetchRequest(entityName: "HashState")
            
            do {
                if let fetchedResults = try moc!.executeFetchRequest(hashStateFetch) as? [HashState] {
                    value = fetchedResults.count > 0 && fetchedResults[0].hashString != nil ? fetchedResults[0].hashString! : nil
                }
                else {
                    value = nil
                }
            } catch {
                value = nil
            }
        }
        
        return value
    }
    
    private func hashExists(hashString: String) -> Bool {
        var result = false
        self.dataController!.managedObjectContext.performBlockAndWait { () -> Void in
            let moc = self.dataController?.managedObjectContext
            let hashStateFetch = NSFetchRequest(entityName: "HashState")
            let predicate = NSPredicate(format: "hashString == %@", hashString)
            hashStateFetch.predicate = predicate
            
            do {
                let fetchedResults = try moc!.executeFetchRequest(hashStateFetch) as! [HashState]
                
                result = fetchedResults.count > 0
            } catch {
                result = false
            }
        }
        
        return result
    }
    
    private func insertHashStateValue(hashString: String) {
        self.dataController!.managedObjectContext.performBlockAndWait { () -> Void in
            let hashState = NSEntityDescription.insertNewObjectForEntityForName("HashState", inManagedObjectContext: self.dataController!.managedObjectContext) as! HashState
            hashState.hashString = hashString
            self.dataController?.save()
        }
    }
    
    private func loadAndSaveUrlContent(beacons: [Beacon]) {
        self.dataController?.deleteAllUrlContent()
        
        for beacon in beacons {
            if let urlNearString = beacon.urlNear, urlNear = NSURL(string: urlNearString) {
                let urlNearContent = NSEntityDescription.insertNewObjectForEntityForName("UrlContent", inManagedObjectContext: self.dataController!.managedObjectContext) as! UrlContent
                beacon.urlNearContent = urlNearContent
                
                do {
                    let request: NSURLRequest = NSURLRequest(URL: urlNear)
                    let response: AutoreleasingUnsafeMutablePointer<NSURLResponse? >= nil
                    let dataValue: NSData =  try NSURLConnection.sendSynchronousRequest(request, returningResponse: response)
                    urlNearContent.html = dataValue
                }
                catch let error as NSError {
                    if let errorDescription = error.userInfo["NSLocalizedDescription"] as? String {
                        urlNearContent.errorCode = error.code.description
                        urlNearContent.errorDescription = errorDescription
                    }
                }
            }
            
            if let urlFarString = beacon.urlFar, urlFar = NSURL(string: urlFarString) {
                let urlFarContent = NSEntityDescription.insertNewObjectForEntityForName("UrlContent", inManagedObjectContext: self.dataController!.managedObjectContext) as! UrlContent
                beacon.urlFarContent = urlFarContent
                
                do {
                    let request: NSURLRequest = NSURLRequest(URL: urlFar)
                    let response: AutoreleasingUnsafeMutablePointer<NSURLResponse? >= nil
                    let dataValue: NSData =  try NSURLConnection.sendSynchronousRequest(request, returningResponse: response)
                    urlFarContent.html = dataValue
                }
                catch let error as NSError {
                    if let errorDescription = error.userInfo["NSLocalizedDescription"] as? String {
                        urlFarContent.errorCode = error.code.description
                        urlFarContent.errorDescription = errorDescription
                    }
                }
            }
        }
        
        self.dataController!.managedObjectContext.performBlockAndWait { () -> Void in
            self.dataController?.save()
        }
    }
}