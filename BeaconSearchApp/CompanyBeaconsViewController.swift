//
//  CompanyBeaconsTableViewController.swift
//  BeaconSearchApp
//
//  Created by Developer 1 on 2015-11-05.
//  Copyright © 2015 Ap1. All rights reserved.
//

import UIKit
import BeaconSearch

let kCompanyBeaconCell = "CompanyBeaconCell"

class CompanyBeaconsViewController: UITableViewController {

    weak var mainTabBarController: MainTabBarController?
    
    var companies: [String] {
        get {
            return self.mainTabBarController!.companies
        }
    }
    
    var companyBeacons: [String: [Beacon]] {
        get {
            return self.mainTabBarController!.companyBeacons
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
    
    var companyImages: [String: UIImage] {
        get {
            return self.mainTabBarController!.companyImages
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.reloadData()
    }

    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return self.companies.count
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.companyBeacons[self.companies[section]]?.count ?? 0
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(kCompanyBeaconCell, forIndexPath: indexPath) as! CompanyBeaconCell

        if let value = self.companyBeacons[self.companies[indexPath.section]] {
            let beacon = value[indexPath.row]
            cell.titleLabel?.text = beacon.nickName != nil && !beacon.nickName!.isEmpty ? beacon.nickName! : "Unnamed"
            
            let majorFont = [NSFontAttributeName: UIFont(name: "OpenSans-Light", size: 12)!]
            let minorFont = [NSFontAttributeName: UIFont(name: "OpenSansLight-Italic", size: 12)!]
            
            let para = NSMutableAttributedString()
            let major = NSAttributedString(string: "Major: \(beacon.major ?? "")", attributes: majorFont)
            let minor = NSAttributedString(string: " minor: \(beacon.minor ?? "")", attributes: minorFont)
            para.appendAttributedString(major)
            para.appendAttributedString(minor)
            
            cell.subtitleLabel?.attributedText = para
            
            cell.accessoryType = .None
            
            if let companyName = beacon.companyName, image = self.companyImages[companyName] {
                cell.colorImageView?.image = image
            }
            
            cell.colorImageView?.userInteractionEnabled = true
            
            cell.beacon = beacon
            cell.companyBeaconsViewController = self
        }

        return cell
    }
    
    override func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerCell = tableView.dequeueReusableCellWithIdentifier(kHeaderCell) as! HeaderCell
        headerCell.titleLabel.text = ""
        
        headerCell.subtitleLabel.font = UIFont(name: "OpenSans-Semibold", size: 14)!
        headerCell.subtitleLabel.text = self.companies[section]
        
        return headerCell
    }
    
    override func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 50.0
    }

    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if let value = self.companyBeacons[self.companies[indexPath.section]] {
            let beacon = value[indexPath.row]
            self.openUrl(beacon, closestBeacon: true)
        }
        
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
    }
    
    func openUrl(beacon: Beacon, closestBeacon: Bool) {
        if let webViewController = self.storyboard?.instantiateViewControllerWithIdentifier("WebViewController") as? WebViewController {
            webViewController.beacon = beacon
            webViewController.closestBeacon = closestBeacon
            
            self.navigationController?.pushViewController(webViewController, animated: true)
        }
    }
    
    func update() {
        self.tableView.reloadData()
    }
}