//
//  AppDelegate.swift
//  FindBeaconTest
//
//  Created by Developer 1 on 2015-09-14.
//  Copyright © 2015 Ap1. All rights reserved.
//

import UIKit
import Foundation
import CoreLocation
import Parse
import FBSDKCoreKit
import FBSDKLoginKit
import ParseFacebookUtilsV4
import ParseTwitterUtils
import CoreBluetooth


let MainTintColor = UIColor(red: 19/255, green: 151/255, blue: 195/255, alpha: 1)

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, CLLocationManagerDelegate, CBCentralManagerDelegate {

    var window: UIWindow?
    
    var locationManager: CLLocationManager!
    var currentLocation: CLLocation?
    var centralManager : CBCentralManager?

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        
        application.registerUserNotificationSettings(
            UIUserNotificationSettings(
                forTypes: [.Alert, .Badge, .Sound],
                categories: nil))
            
        locationManager = CLLocationManager()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestAlwaysAuthorization()
        
        locationManager.startUpdatingLocation()

        // [Optional] Power your app with Local Datastore. For more info, go to
        // https://parse.com/docs/ios_guide#localdatastore/iOS
        Parse.enableLocalDatastore()
        
        // Initialize Parse.
        Parse.setApplicationId("2wsE732QLoLf9rlFWS0dSYtm88hCAuFkVUytLP8t", clientKey: "EPYhtShSVpeaKSoD5loUBNJ3IBW0e48ewM33jco0")
        PFAnalytics.trackAppOpenedWithLaunchOptions(launchOptions)
        
        // MARK: - Facebook Additions
        
        PFFacebookUtils.initializeFacebookWithApplicationLaunchOptions(launchOptions)
        
        // Keen setup
        KeenClient.sharedClientWithProjectID("56eab693d2eaaa4d70b5d667", andWriteKey: "143ee28a2199ec529497703bf5a3248393fe389fec182b78804b48a77133d08520c5a20a55522e834327705ae8a55b5f2531df205aa383e722166d65702e82c45b72b3637c135fe36e21d44eeb3498382ffe44b1497fad7d7524128633dbe61e", andReadKey: nil)
        
        UIApplication.sharedApplication().statusBarStyle = .LightContent
        UINavigationBar.appearance().barTintColor = MainTintColor
        UINavigationBar.appearance().tintColor = UIColor.whiteColor()
        UIBarButtonItem.appearance().tintColor = UIColor.whiteColor()
        UINavigationBar.appearance().titleTextAttributes = [NSForegroundColorAttributeName: UIColor.whiteColor()]
        
        UITableViewCell.appearance().tintColor = MainTintColor
        
        self.centralManager = CBCentralManager(delegate: self, queue: nil)
        
        
        return true
    }

    
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        currentLocation = locations[0]
    }
    
    func centralManagerDidUpdateState(central: CBCentralManager) {
        // Determine the state of the peripheral
        if (central.state == .PoweredOff) {
            print("CoreBluetooth BLE hardware is powered off")
        }
    }
    
    func application(application: UIApplication, didReceiveLocalNotification notification: UILocalNotification) {
        
        if application.applicationState != .Active {
            if let userInfo = notification.userInfo, beaconId = userInfo["beaconId"] as? String, distanceDetail = userInfo["distanceDetail"] as? String {
                if let loginViewController = self.window?.rootViewController as? LoginViewController, mainTabBarController = loginViewController.mainTabBarController {
                    mainTabBarController.loadWebViewFromReceiveLocalNotification(beaconId, distanceDetail: distanceDetail)
                }
            }
        }
    }
    
    func application(application: UIApplication, openURL url: NSURL, sourceApplication: String?, annotation: AnyObject) -> Bool {
        return FBSDKApplicationDelegate.sharedInstance().application(application, openURL: url, sourceApplication: sourceApplication, annotation: annotation)
    }
    
    func applicationWillResignActive(application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        
        FBSDKAppEvents.activateApp()
    }

    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
}