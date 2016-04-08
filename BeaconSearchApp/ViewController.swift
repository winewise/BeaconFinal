//
//  ViewController.swift
//  FindBeaconTest
//
//  Created by Developer 1 on 2015-09-14.
//  Copyright © 2015 Ap1. All rights reserved.
//

import UIKit
import CoreData
import BeaconSearch
import CoreLocation
import Parse

let kBeaconCell = "BeaconCell"
let kHeaderCell = "HeaderCell"

class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    var refreshControl: UIRefreshControl?
    weak var mainTabBarController: MainTabBarController?
    let formatter = NSDateFormatter()
    var beaconDetailViewController: BeaconDetailViewController?
    
    @IBOutlet weak var tableView: UITableView?
    
    var findBeacon: FindBeacon? {
        get {
            return self.mainTabBarController!.findBeacon
        }
        set {
            self.mainTabBarController!.findBeacon = newValue
        }
    }
    
    var uniqueFoundBeacons: [String] {
        get {
            return self.mainTabBarController!.uniqueFoundBeacons
        }
    }
    
    var foundBeacons: [CLBeacon] {
        get {
            return self.mainTabBarController!.foundBeacons
        }
        set {
            self.mainTabBarController!.foundBeacons = newValue
        }
    }
    
    var persistedFoundBeacons: [CLBeacon] {
        get {
            return self.mainTabBarController!.persistedFoundBeacons
        }
        set {
            self.mainTabBarController!.persistedFoundBeacons = newValue
        }
    }
    
    var storedBeacons: [CLBeacon : Beacon] {
        get {
            return self.mainTabBarController!.storedBeacons
        }
        set {
            self.mainTabBarController!.storedBeacons = newValue
        }
    }
    
    var inLocationbeacons: [Beacon] {
        get {
            return self.mainTabBarController!.inLocationbeacons
        }
        
        set {
            self.mainTabBarController!.inLocationbeacons = newValue
        }
    }
    
    var allBeacons: [Beacon] {
        get {
            return self.mainTabBarController!.allBeacons
        }
        
        set {
            self.mainTabBarController!.allBeacons = newValue
        }
    }
    
    var allCompanies: [Company] {
        get {
            return self.mainTabBarController!.allCompanies
        }
        
        set {
            self.mainTabBarController!.allCompanies = newValue
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.refreshControl = UIRefreshControl()
        formatter.dateFormat = "HH:mm"
        
        self.refreshControl?.attributedTitle = NSAttributedString(string: "Pull to refresh")
        self.refreshControl?.addTarget(self, action: #selector(ViewController.refresh(_:)), forControlEvents: UIControlEvents.ValueChanged)
        self.tableView?.addSubview(refreshControl!)
        
        self.updateRefereshControl()
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    func refresh(sender:AnyObject) {
        self.mainTabBarController?.reset()
    }
    
    func reset() {
        self.mainTabBarController?.reset()
    }
    
    func update() {
        self.tableView?.reloadData()
        self.updateRefereshControl()
    }
    
    func updateRefereshControl() {
        if let date = NSUserDefaults.standardUserDefaults().valueForKey(LastSyncDate) as? NSDate {
            self.refreshControl?.attributedTitle = NSAttributedString(string: "Last updated \(formatter.stringFromDate(date))")
        }
    }
    
    // MARK: - Table view data source
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return self.uniqueFoundBeacons.count
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.mainTabBarController!.beaconsForUdid(self.uniqueFoundBeacons[section]).count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(kBeaconCell, forIndexPath: indexPath) as! BeaconCell
        cell.indexPath = indexPath
        cell.viewController = self
    
        let beacon = self.mainTabBarController!.beaconsForUdid(self.uniqueFoundBeacons[indexPath.section])[indexPath.row]
        
        var stored = String()

        cell.selectionStyle = .Default
        cell.accessoryType = .None
        
        let openSansRegular = [NSFontAttributeName: UIFont(name: "OpenSans", size: 14)!, NSForegroundColorAttributeName: UIColor.blackColor()]
        let openSansRegularTint = [NSFontAttributeName: UIFont(name: "OpenSans-Semibold", size: 14)!, NSForegroundColorAttributeName: MainTintColor]
        
        let titlePara = NSMutableAttributedString()
        if let storedBeacon = storedBeacons[beacon] {
            stored = "Registered"
            
            cell.imageViewDisclosure.image = UIImage(named: "chevron")
            if self.mainTabBarController!.writeAccess {
                cell.infoButton?.hidden = false
            }
            else {
                cell.infoButton?.hidden = true
            }
            
            if self.inLocationbeacons.contains(storedBeacon) {
                stored = "Registered & In Location"
            }
            
            let nickname = NSAttributedString(string: storedBeacon.nickName != nil && !storedBeacon.nickName!.isEmpty ? storedBeacon.nickName! : "Unnamed", attributes: openSansRegular)
            let pipe = NSAttributedString(string: " | ", attributes: openSansRegularTint)
            let storedAttribute = NSAttributedString(string: stored, attributes: openSansRegular)
            titlePara.appendAttributedString(nickname)
            titlePara.appendAttributedString(pipe)
            titlePara.appendAttributedString(storedAttribute)
            
            cell.titleLabel?.attributedText = titlePara
            
            cell.titleLabel?.layer.opacity = 1.0
            cell.subtitleLabel?.layer.opacity = 1.0
            cell.keenButton?.hidden = false
        }
        else {
            cell.keenButton?.hidden = true
            cell.infoButton?.hidden = true
            cell.titleLabel?.text = "Inactive"
            if self.mainTabBarController!.writeAccess {
                cell.imageViewDisclosure.image = UIImage(named: "add-inactive")
            }
            else {
                cell.imageViewDisclosure.image = nil
            }
            
            cell.titleLabel?.layer.opacity = 0.5
            cell.subtitleLabel?.layer.opacity = 0.5
        }
        
        let majorFont = [NSFontAttributeName: UIFont(name: "OpenSans-Light", size: 12)!]
        let minorFont = [NSFontAttributeName: UIFont(name: "OpenSansLight-Italic", size: 12)!]
        
        let para = NSMutableAttributedString()
        let major = NSAttributedString(string: "Major: \(beacon.major.stringValue)", attributes: majorFont)
        let minor = NSAttributedString(string: " minor: \(beacon.minor.stringValue)", attributes: minorFont)
        para.appendAttributedString(major)
        para.appendAttributedString(minor)
        
        cell.subtitleLabel?.attributedText = para
    
        return cell
    }

    func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerCell = tableView.dequeueReusableCellWithIdentifier(kHeaderCell) as! HeaderCell
        
        let key = self.uniqueFoundBeacons[section]
        let manufacturer = self.mainTabBarController!.getBeaconManufacturer(key)
        headerCell.titleLabel.text = manufacturer ?? key
        headerCell.subtitleLabel.text = self.mainTabBarController!.writeAccess && manufacturer != nil ? key : ""
        
        return headerCell
    }
    
    func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 50.0
    }
    
    func accessoryButtonTapped(indexPath: NSIndexPath) {
        let beacon = self.mainTabBarController!.beaconsForUdid(self.uniqueFoundBeacons[indexPath.section])[indexPath.row]
        if let beaconDetailViewController = self.storyboard?.instantiateViewControllerWithIdentifier("BeaconDetailViewController") as? BeaconDetailViewController {
            beaconDetailViewController.findBeacon = self.findBeacon
            if let storedBeacon = storedBeacons[beacon] {
                beaconDetailViewController.beacon = storedBeacon
            }
            
            beaconDetailViewController.clBeacon = beacon
            beaconDetailViewController.viewController = self
            self.beaconDetailViewController = beaconDetailViewController
            self.navigationController?.pushViewController(beaconDetailViewController, animated: true)
        }
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let beacon = self.mainTabBarController!.beaconsForUdid(self.uniqueFoundBeacons[indexPath.section])[indexPath.row]
        if storedBeacons[beacon] != nil {
            if let storedBeacon = storedBeacons[beacon] {
                if let webViewController = self.storyboard?.instantiateViewControllerWithIdentifier("WebViewController") as? WebViewController {
                    webViewController.beacon = storedBeacon
                    
                    self.navigationController?.pushViewController(webViewController, animated: true)
                }
            }
        }
        else if self.mainTabBarController!.writeAccess {
            self.accessoryButtonTapped(indexPath)
        }

        tableView.deselectRowAtIndexPath(indexPath, animated: true)
    }
    
    func postToKeenWithMockBeaconExit(indexPath: NSIndexPath) {
        let beacon = self.mainTabBarController!.beaconsForUdid(self.uniqueFoundBeacons[indexPath.section])[indexPath.row]
        if let storedBeacon = storedBeacons[beacon] {
            self.findBeacon?.updateBeaconState(storedBeacon, inProximity: nil, inRange: false)
            self.mainTabBarController?.postToKeen(storedBeacon)
        }
    }
    
    @IBAction func userButtonTapped(sender: UIBarButtonItem) {
        self.mainTabBarController?.updateNearbyView()
    }
    
    @IBAction func optionsButtonTapped(sender: UIBarButtonItem) {
        let settingsActionSheet: UIAlertController = UIAlertController(title:nil, message:nil, preferredStyle:UIAlertControllerStyle.ActionSheet)
        
        settingsActionSheet.addAction(UIAlertAction(title: "Settings", style:UIAlertActionStyle.Default, handler:{ action in
            if let navigationController = UIStoryboard(name: "Settings", bundle: nil).instantiateViewControllerWithIdentifier("SettingsNavigationController") as? UINavigationController, settingsViewController = navigationController.topViewController as? SettingsViewController {
                settingsViewController.mainTabBarController = self.mainTabBarController
                self.presentViewController(navigationController, animated: true, completion: nil)
            }
        }))
        
        settingsActionSheet.addAction(UIAlertAction(title: "Sign Out", style:UIAlertActionStyle.Default, handler:{ action in
            self.mainTabBarController?.logout()
        }))
        
        settingsActionSheet.addAction(UIAlertAction(title:NSLocalizedString("Cancel", comment:"Cancel"), style:UIAlertActionStyle.Cancel, handler:nil))
        
        // for iPad
        if let popoverController = settingsActionSheet.popoverPresentationController {
            popoverController.barButtonItem = sender
        }
        
        self.presentViewController(settingsActionSheet, animated:true, completion:nil)
    }
    
    override func motionEnded(motion: UIEventSubtype, withEvent event: UIEvent?) {
        self.reset()
    }
}

extension RangeReplaceableCollectionType where Generator.Element : Equatable {
    
    // Remove first collection element that is equal to the given `object`:
    mutating func removeObject(object : Generator.Element) {
        if let index = self.indexOf(object) {
            self.removeAtIndex(index)
        }
    }
}