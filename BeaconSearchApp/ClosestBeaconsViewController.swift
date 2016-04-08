//
//  ClosestBeaconsViewController.swift
//  BeaconSearchApp
//
//  Created by Developer 1 on 2015-10-28.
//  Copyright © 2015 Ap1. All rights reserved.
//

import UIKit
import BeaconSearch
class ClosestBeaconsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    weak var mainTabBarController: MainTabBarController?
    var refreshControl: UIRefreshControl?
    let formatter = NSDateFormatter()
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var rightBarButton: UIBarButtonItem!
    
    var closestBeacons: [CLBeacon] {
        get {
            return self.mainTabBarController!.closestBeacons
        }
        set {
            self.mainTabBarController!.closestBeacons = newValue
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
    
    var persistedBeacons: [CLBeacon] {
        get {
            return self.mainTabBarController!.persistedFoundBeacons
        }
    }
    
    var companyImages: [String: UIImage] {
        get {
            return self.mainTabBarController!.companyImages
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.refreshControl = UIRefreshControl()
        formatter.dateFormat = "HH:mm"
        
        self.refreshControl?.attributedTitle = NSAttributedString(string: "Pull to refresh")
        self.refreshControl?.addTarget(self, action: #selector(ClosestBeaconsViewController.refresh(_:)), forControlEvents: UIControlEvents.ValueChanged)
        self.tableView?.addSubview(refreshControl!)
        
        self.updateRefereshControl()
        
        if !self.mainTabBarController!.writeAccess {
            self.navigationItem.rightBarButtonItem = nil
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.persistedBeacons.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(kBeaconCell, forIndexPath: indexPath) as! BeaconCell
        cell.closestBeaconsViewController = self
        cell.indexPath = indexPath
        
        let beacon = self.persistedBeacons[indexPath.row]
        
        cell.selectionStyle = .Default
        cell.accessoryType = .None
        
        let openSansRegular = [NSFontAttributeName: UIFont(name: "OpenSans", size: 14)!, NSForegroundColorAttributeName: UIColor.blackColor()]
        let openSansRegularTint = [NSFontAttributeName: UIFont(name: "OpenSans-Semibold", size: 14)!, NSForegroundColorAttributeName: MainTintColor]
        
        let titlePara = NSMutableAttributedString()
        
        if let storedBeacon = storedBeacons[beacon] {
            cell.disclosureHidden = false
            
            let nickname = NSAttributedString(string: storedBeacon.nickName != nil && !storedBeacon.nickName!.isEmpty ? storedBeacon.nickName! : "Unnamed", attributes: openSansRegular)
            let pipe = NSAttributedString(string: " | ", attributes: openSansRegularTint)
            let storedAttribute = NSAttributedString(string: "Registered", attributes: openSansRegular)
            titlePara.appendAttributedString(nickname)
            titlePara.appendAttributedString(pipe)
            titlePara.appendAttributedString(storedAttribute)
            
            cell.titleLabel?.attributedText = titlePara
            cell.titleLabel?.layer.opacity = 1
            cell.subtitleLabel?.layer.opacity = 1
            
            if let companyName = storedBeacon.companyName, image = self.companyImages[companyName] {
                cell.colorImageView?.image = image
            }
            
            cell.colorImageView?.userInteractionEnabled = true
        }
        else {
            cell.disclosureHidden = true
            cell.titleLabel?.text = "Inactive"
            cell.titleLabel?.layer.opacity = 0.5
            cell.subtitleLabel?.layer.opacity = 0.5
        }
        
        let majorFont = [NSFontAttributeName: UIFont(name: "OpenSans-Light", size: 12)!]
        let minorFont = [NSFontAttributeName: UIFont(name: "OpenSansLight-Italic", size: 12)!]
        
        let para = NSMutableAttributedString()
        
        if let closestBeacon = (self.closestBeacons.filter{$0 == beacon}.first) {
            let major = NSAttributedString(string: "Nearby | Accuracy \(closestBeacon.accuracy.string(2)) | Major: \(beacon.major.stringValue)", attributes: majorFont)
            let minor = NSAttributedString(string: " minor: \(beacon.minor.stringValue)", attributes: minorFont)
            
            para.appendAttributedString(major)
            para.appendAttributedString(minor)
            
            cell.subtitleLabel?.attributedText = para
        }
        else {
            let major = NSAttributedString(string: "Not in Proximity | Major: \(beacon.major.stringValue)", attributes: majorFont)
            let minor = NSAttributedString(string: " minor: \(beacon.minor.stringValue)", attributes: minorFont)
            para.appendAttributedString(major)
            para.appendAttributedString(minor)
            cell.subtitleLabel?.attributedText = para
        }
        
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        self.openUrl(indexPath, closestBeacon: true)
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
    }
    
    func openUrl(indexPath: NSIndexPath) {
        self.openUrl(indexPath, closestBeacon: false)
    }
    
    func openUrl(indexPath: NSIndexPath, closestBeacon: Bool) {
        if indexPath.row < self.persistedBeacons.count {
            let beacon = self.persistedBeacons[indexPath.row]
            if let storedBeacon = storedBeacons[beacon] {
                openBeaconUrl(storedBeacon, closestBeacon: closestBeacon)
            }
        }
    }
    
    func openBeaconUrl(storedBeacon: Beacon, closestBeacon: Bool) {
        if let webViewController = self.storyboard?.instantiateViewControllerWithIdentifier("WebViewController") as? WebViewController {
            webViewController.beacon = storedBeacon
            webViewController.closestBeacon = closestBeacon
            
            self.navigationController?.pushViewController(webViewController, animated: true)
        }
    }
    
    func openUrlForBeaconId(beaconId: String, distanceDetail: String) {
        let beacons = Array(self.storedBeacons.values)
        if let beacon = beacons.filter({$0.id == beaconId}).first {
            let closestBeacon = distanceDetail == "near" ? true : false
            self.openBeaconUrl(beacon, closestBeacon: closestBeacon)
        }
    }
    
    func update() {
        self.tableView?.reloadData()
        self.updateRefereshControl()
    }
    
    func refresh(sender:AnyObject) {
        self.mainTabBarController?.reset()
    }
    
    func updateRefereshControl() {
        if let date = NSUserDefaults.standardUserDefaults().valueForKey(LastSyncDate) as? NSDate {
            self.refreshControl?.attributedTitle = NSAttributedString(string: "Last updated \(formatter.stringFromDate(date))")
        }
    }
    
    @IBAction func rightBarButtonTapped(sender: UIBarButtonItem) {
        self.mainTabBarController!.updateNearbyView()
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
    
    @IBAction func logoutTapped(sender: UIBarButtonItem) {
        self.findBeaconContext?.stopScanning()
        PFUser.logOut()
        self.dismissViewControllerAnimated(true, completion: nil)
    }
}
