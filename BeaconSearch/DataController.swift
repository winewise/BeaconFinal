//
//  DataController.swift
//  beaconSearchFramework
//
//  Created by Hafiz Usama on 2015-08-24.
//  Copyright (c) 2015 Ap1. All rights reserved.
//

import UIKit
import CoreData

class DataController: NSObject {
    
    var managedObjectContext: NSManagedObjectContext
    
    override init() {
        // This resource is the same name as your xcdatamodeld contained in your project.
        guard let modelURL = NSBundle(identifier: "com.ap1.BeaconSearch")?.URLForResource("BeaconModel", withExtension:"momd") else {
            fatalError("Error loading model from bundle")
        }
        // The managed object model for the application. It is a fatal error for the application not to be able to find and load its model.
        guard let mom = NSManagedObjectModel(contentsOfURL: modelURL) else {
            fatalError("Error initializing mom from: \(modelURL)")
        }
        
        let psc = NSPersistentStoreCoordinator(managedObjectModel: mom)
        self.managedObjectContext = NSManagedObjectContext(concurrencyType: .MainQueueConcurrencyType)
        self.managedObjectContext.persistentStoreCoordinator = psc
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0)) {
            var searchPathDirectory: NSSearchPathDirectory = .DocumentDirectory
            if #available(iOS 9.0, *) {
                if UIDevice.currentDevice().userInterfaceIdiom == .TV {
                    searchPathDirectory = .CachesDirectory
                }
            }
            
            let urls = NSFileManager.defaultManager().URLsForDirectory(searchPathDirectory, inDomains: .UserDomainMask)
            let docURL = urls[urls.endIndex-1]
            /* The directory the application uses to store the Core Data store file.
            This code uses a file named "BeaconModel.sqlite" in the application's documents directory.
            */
            let storeURL = docURL.URLByAppendingPathComponent("BeaconModel.sqlite")
            do {
            try psc.addPersistentStoreWithType(NSSQLiteStoreType, configuration: nil, URL: storeURL, options: nil)
            } catch {
                fatalError("Error migrating store: \(error)")
            }
        }
    }
    
    func deleteAll() {
        let beaconFetchRequest = NSFetchRequest(entityName: "Beacon")
        let hashStateFetchRequest = NSFetchRequest(entityName: "HashState")
        let urlContentFetchRequest = NSFetchRequest(entityName: "UrlContent")
        let companyFetchRequest = NSFetchRequest(entityName: "Company")
        
        self.managedObjectContext.performBlockAndWait { () -> Void in
            do {
                let beaconFetchedEntities = try self.managedObjectContext.executeFetchRequest(beaconFetchRequest) as! [Beacon]
                
                for entity in beaconFetchedEntities {
                    self.managedObjectContext.deleteObject(entity)
                }
                
                let urlContentFetchedEntities = try self.managedObjectContext.executeFetchRequest(urlContentFetchRequest) as! [UrlContent]
                
                for entity in urlContentFetchedEntities {
                    self.managedObjectContext.deleteObject(entity)
                }
                
                let hashStateFetchedEntities = try self.managedObjectContext.executeFetchRequest(hashStateFetchRequest) as! [HashState]
                
                for entity in hashStateFetchedEntities {
                    self.managedObjectContext.deleteObject(entity)
                }
                
                let companyFetchedEntities = try self.managedObjectContext.executeFetchRequest(companyFetchRequest) as! [Company]
                
                for entity in companyFetchedEntities {
                    self.managedObjectContext.deleteObject(entity)
                }
                
                try self.managedObjectContext.save()
            }
            catch {
                print("delete all failed")
            }
        }
    }
    
    func deleteAllBeacons() {
        // deleting all entries
        // Assuming type has a reference to managed object context
        
        let fetchRequest = NSFetchRequest(entityName: "Beacon")
        
        do {
            let fetchedEntities = try self.managedObjectContext.executeFetchRequest(fetchRequest) as! [Beacon]
                //.executeFetchRequest(fetchRequest, error: nil) as! [Beacon]
            
            for entity in fetchedEntities {
                self.managedObjectContext.deleteObject(entity)
            }
            
            try self.managedObjectContext.save()
        }
        catch {
            print("delete all beacons failed")
        }
    }
    
    func deleteBeacon(beaconId: String) {
        // deleting all entries
        // Assuming type has a reference to managed object context
        
        let fetchRequest = NSFetchRequest(entityName: "Beacon")
        let predicate = NSPredicate(format: "id == %@", beaconId)
        fetchRequest.predicate = predicate
        
        do {

            let fetchedEntities = try self.managedObjectContext.executeFetchRequest(fetchRequest) as! [Beacon]
            
            for entity in fetchedEntities {
                self.managedObjectContext.deleteObject(entity)
            }
            
            try self.managedObjectContext.save()
        }
        catch {
            print("delete beacon failed")
        }
    }
    
    func deleteAllHash() {
        let fetchRequest = NSFetchRequest(entityName: "HashState")
        
        do {
            let fetchedEntities = try self.managedObjectContext.executeFetchRequest(fetchRequest) as! [HashState]
            
            for entity in fetchedEntities {
                self.managedObjectContext.deleteObject(entity)
            }
            
            try self.managedObjectContext.save()
        }
        catch {
            print("delete all hashStates failed")
        }
    }
    
    func deleteAllUrlContent() {
        self.managedObjectContext.performBlockAndWait { () -> Void in
            let fetchRequest = NSFetchRequest(entityName: "UrlContent")
            
            do {
                let fetchedEntities = try self.managedObjectContext.executeFetchRequest(fetchRequest) as! [UrlContent]
                
                for entity in fetchedEntities {
                    self.managedObjectContext.deleteObject(entity)
                }
                
                try self.managedObjectContext.save()
            }
            catch {
                print("delete all urlContents failed")
            }
        }
    }
    
    func deleteAllCompanies() {
        let fetchRequest = NSFetchRequest(entityName: "Company")
        
        do {
            let fetchedEntities = try self.managedObjectContext.executeFetchRequest(fetchRequest) as! [Company]
            
            for entity in fetchedEntities {
                self.managedObjectContext.deleteObject(entity)
            }
            
            try self.managedObjectContext.save()
        }
        catch {
            print("delete all companies failed")
        }
    }
    
    func deleteCompany(company: Company) {
        do {
            self.managedObjectContext.deleteObject(company)
            
            try self.managedObjectContext.save()
        }
        catch {
            print("delete company failed")
        }
    }
    
    func deleteAllBeaconTypes() {
        let fetchRequest = NSFetchRequest(entityName: "BeaconType")
        
        do {
            let fetchedEntities = try self.managedObjectContext.executeFetchRequest(fetchRequest) as! [BeaconType]
            
            for entity in fetchedEntities {
                self.managedObjectContext.deleteObject(entity)
            }
            
            try self.managedObjectContext.save()
        }
        catch {
            print("delete all companies failed")
        }
    }
    
    func save() {
        do {
            try self.managedObjectContext.save()
        } catch {
            fatalError("Failure to save context: \(error)")
        }
    }
}