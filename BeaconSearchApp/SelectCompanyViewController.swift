//
//  SelectCompanyViewController.swift
//  BeaconSearchApp
//
//  Created by Developer 1 on 2015-12-03.
//  Copyright © 2015 Ap1. All rights reserved.
//

import UIKit
import BeaconSearch

let getAllCompaniesUrl = "http://159.203.15.175/filemaker/getAllCompanies_bid.php"
let deleteCompanyUrl = "http://159.203.15.175/filemaker/deleteCompany.php"

class SelectCompanyViewController: UITableViewController {
    weak var beaconDetailViewController: BeaconDetailViewController?
    
    var allCompanies: [Company] {
        get {
            return self.beaconDetailViewController!.viewController!.allCompanies
        }
        set {
            self.beaconDetailViewController!.viewController!.allCompanies = newValue
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.tableView.allowsMultipleSelectionDuringEditing = false
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.allCompanies.count
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("CompanyCell", forIndexPath: indexPath)

        let company = self.allCompanies[indexPath.row]
        cell.textLabel?.text = company.name ?? "Unnamed"

        return cell
    }

    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        
        self.beaconDetailViewController?.updateSelectedCompanyValue(self.allCompanies[indexPath.row])
        self.navigationController?.popViewControllerAnimated(true)
    }
    
    override func tableView(tableView: UITableView, accessoryButtonTappedForRowWithIndexPath indexPath: NSIndexPath) {
        if let navigationController = self.storyboard?.instantiateViewControllerWithIdentifier("AddCompanyNavigationController") as? UINavigationController, addCompanyViewController = navigationController.topViewController as? AddCompanyViewController {
            addCompanyViewController.selectCompanyViewController = self
            addCompanyViewController.company = self.allCompanies[indexPath.row]
            self.presentViewController(navigationController, animated: true, completion: nil)
        }
    }

    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
    
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if (editingStyle == .Delete) {
            if let findBeacon = self.findBeaconContext {
                let alert = UIAlertController (
                    title: NSLocalizedString("Important", comment: "Important"),
                    message: NSLocalizedString("Deleting company will delete all associated beacons. Are you sure you want to continue?", comment: "Deleting company will delete all associated beacons. Are you sure you want to continue?"),
                    preferredStyle: UIAlertControllerStyle.Alert
                )
                alert.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment:"Cancel"), style: .Cancel, handler: nil))
                alert.addAction(UIAlertAction(title: NSLocalizedString("Confrim", comment:"Confrim"), style: .Default, handler: { (alert) -> Void in
                    self.view.userInteractionEnabled = false
                    self.navigationController?.navigationBar.userInteractionEnabled = false
                    self.navigationController?.showLoading()
                    findBeacon.deleteCompany(deleteCompanyUrl, username: PFUser.currentUser()?.username ?? "", company: self.allCompanies[indexPath.row], completionHandler: { (result) -> Void in
                        dispatch_async(dispatch_get_main_queue(), {
                            self.view.userInteractionEnabled = true
                            self.navigationController?.navigationBar.userInteractionEnabled = true
                            self.navigationController?.hideLoading()
                            if result {
                                self.allCompanies.removeAtIndex(indexPath.row)
                                tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: UITableViewRowAnimation.Automatic)
                            }
                            else {
                                let alert = UIAlertController(title: "Alert", message: "Error!", preferredStyle: UIAlertControllerStyle.Alert)
                                let okAction = UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: { (alert: UIAlertAction) -> Void in
                                })
                                
                                alert.addAction(okAction)
                                self.navigationController?.presentViewController(alert, animated: true, completion: { () -> Void in
                                })
                            }
                        })
                    })
                }))
                
                self.presentViewController(alert, animated: true, completion: nil)
            }
        }
    }
    
    func updateCompanies() {
        self.showLoading()
        let bundleIdentifier = NSBundle.mainBundle().bundleIdentifier ?? ""
        self.findBeaconContext?.updateCompanyData(getAllCompaniesUrl, bundleId: bundleIdentifier, completionHandler: { (result, totalCount) -> Void in
            dispatch_async(dispatch_get_main_queue(), {
                self.beaconDetailViewController?.viewController?.mainTabBarController?.updateCompanies()
                self.tableView.reloadData()
                self.hideLoading()
            })
        })
    }

    @IBAction func addButtonTapped(sender: UIBarButtonItem) {
        if let navigationController = self.storyboard?.instantiateViewControllerWithIdentifier("AddCompanyNavigationController") as? UINavigationController, addCompanyViewController = navigationController.topViewController as? AddCompanyViewController {
            addCompanyViewController.selectCompanyViewController = self
            self.presentViewController(navigationController, animated: true, completion: nil)
        }
    }
}