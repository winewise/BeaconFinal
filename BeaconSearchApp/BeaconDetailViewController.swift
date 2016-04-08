//
//  BeaconDetailViewController.swift
//  FindBeaconTest
//
//  Created by Developer 1 on 2015-09-24.
//  Copyright © 2015 Ap1. All rights reserved.
//

import UIKit
import BeaconSearch
import CoreLocation

let addBeaconUrl = "http://159.203.15.175/filemaker/addBeaconv7.php"
let updateBeaconUrl = "http://159.203.15.175/filemaker/editBeaconv3.php"
let deleteBeaconUrl = "http://159.203.15.175/filemaker/deleteBeaconv4.php"

class BeaconDetailViewController: UITableViewController, UITextFieldDelegate {
    var beacon: Beacon?
    var clBeacon: CLBeacon?
    var findBeacon: FindBeacon?
    weak var viewController: ViewController?
    var selectedCompanyId: String?
    
    @IBOutlet weak var uuidValueLabel: UILabel!
    @IBOutlet weak var majorValueLabel: UILabel!
    @IBOutlet weak var minorValueLabel: UILabel!
    @IBOutlet weak var accuracyValueLabel: UILabel?
    @IBOutlet weak var rssiValueLabel: UILabel!
    @IBOutlet weak var macAddressValueLabel: UILabel!
    @IBOutlet weak var nickNameTextField: UITextField!
    @IBOutlet weak var latValueLabel: UILabel!
    @IBOutlet weak var lngValueLabel: UILabel!
    @IBOutlet weak var outUrlValueTextField: UITextField!
    @IBOutlet weak var inUrlValueTextField: UITextField!
    @IBOutlet weak var notifyTitleTextField: UITextField!
    @IBOutlet weak var notifyTextTextField: UITextField!
    @IBOutlet weak var notifyTitleNearTextField: UITextField!
    @IBOutlet weak var notifyTextNearTextField: UITextField!
    //@IBOutlet weak var updateButton: UIButton!
    @IBOutlet weak var companyValueLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.tableView.delaysContentTouches = false
        for case let x as UIScrollView in self.tableView.subviews {
            x.delaysContentTouches = false
        }
        
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(BeaconDetailViewController.dismissKeyboard(_:)))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
        
        let barButtonItemText = beacon != nil ? "Remove" : "Add"
        let barButtonItem = UIBarButtonItem(title: barButtonItemText, style: UIBarButtonItemStyle.Plain, target: self, action: #selector(BeaconDetailViewController.beaconOperation(_:)))
        self.navigationItem.rightBarButtonItem = barButtonItem
        
        self.macAddressValueLabel.text = UIDevice().identifierForVendor?.UUIDString
        
        if let clBeaconValue = self.clBeacon {
            self.uuidValueLabel.text = clBeaconValue.proximityUUID.UUIDString
            self.majorValueLabel.text = clBeaconValue.major.stringValue
            self.minorValueLabel.text = clBeaconValue.minor.stringValue
            self.accuracyValueLabel?.text = clBeaconValue.accuracy.description
            self.rssiValueLabel.text = clBeaconValue.rssi.description
            
            let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
            self.latValueLabel.text = appDelegate.currentLocation?.coordinate.latitude.description ?? ""
            self.lngValueLabel.text = appDelegate.currentLocation?.coordinate.longitude.description ?? ""
        }
        
        if let beaconValue = self.beacon {
            if beaconValue.macAddress != nil && !beaconValue.macAddress!.isEmpty {
                self.macAddressValueLabel.text = beaconValue.macAddress
            }
            self.nickNameTextField.text = beaconValue.nickName ?? ""
            self.latValueLabel.text = beaconValue.latitude ?? ""
            self.lngValueLabel.text = beaconValue.longitude ?? ""
            self.outUrlValueTextField.text = beaconValue.urlFar ?? ""
            self.inUrlValueTextField.text = beaconValue.urlNear ?? ""
            self.selectedCompanyId = beaconValue.companyId
            self.companyValueLabel.text = beaconValue.companyName ?? ""
            self.notifyTitleTextField.text = beaconValue.notifyTitleFar ?? ""
            self.notifyTextTextField.text = beaconValue.notifyTextFar ?? ""
            self.notifyTitleNearTextField.text = beaconValue.notifyTitleNear ?? ""
            self.notifyTextNearTextField.text = beaconValue.notifyTextNear ?? ""
        }
        else {
            //self.updateButton.hidden = true
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func dismissKeyboard(sender: AnyObject) {
        view.endEditing(true)
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        
        let nextTage=textField.tag+1
        // Try to find next responder
        let nextResponder = tableView.viewWithTag(nextTage) as UIResponder!
        
        if (nextResponder != nil) {
            // Found next responder, so set it.
            nextResponder?.becomeFirstResponder()
        }
        else {
            // Try to find next responder
            tableView.viewWithTag(1)?.becomeFirstResponder()
        }
        
        return false // We do not want UITextField to insert line-breaks.
    }
    
    func beaconOperation(sender: AnyObject) {
        self.navigationItem.rightBarButtonItem?.enabled = false
        self.tableView.resignFirstResponder()
        
        // delete
        if let beaconId = beacon?.id {
            self.showLoading()
            let bundleIdentifier = NSBundle.mainBundle().bundleIdentifier ?? ""
            findBeacon?.deleteBeacon(deleteBeaconUrl, bundleId: bundleIdentifier, username: PFUser.currentUser()?.username ?? "", beaconId: beaconId, completionHandler: { result in
                if result {
                    dispatch_async(dispatch_get_main_queue(), {
                        self.hideLoading()
                        //self.viewController?.reset()
                        self.viewController?.mainTabBarController?.reload()
                        self.navigationController?.popViewControllerAnimated(true)
                    })
                }
                else {
                    dispatch_async(dispatch_get_main_queue(), {
                        self.hideLoading()
                        self.navigationItem.rightBarButtonItem?.enabled = true
                        let alert = UIAlertController(title: "Alert", message: "Operation Failed", preferredStyle: UIAlertControllerStyle.Alert)
                        let okAction = UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: { (alert: UIAlertAction) -> Void in
                        })
                        
                        alert.addAction(okAction)
                        
                        self.navigationController?.presentViewController(alert, animated: true, completion: { () -> Void in
                        })
                    })
                }
            })
        }
        else {
            // add
            if let clBeaconValue = self.clBeacon, beaconTypes = self.viewController?.mainTabBarController?.beaconTypes {
                self.navigationItem.rightBarButtonItem?.enabled = true
                if beaconTypes.filter({
                    $0.uuid == clBeaconValue.proximityUUID.UUIDString && $0.usable != nil && $0.usable!.boolValue
                }).count <= 0 {
                    let alert = UIAlertController(title: "Alert", message: "Apengage showcase is limited to certain beacon types, please try again with different beacon type", preferredStyle: UIAlertControllerStyle.Alert)
                    let okAction = UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: { (alert: UIAlertAction) -> Void in
                    })
                    
                    alert.addAction(okAction)
                    self.navigationController?.presentViewController(alert, animated: true, completion: nil)
                    return
                }
            }
            
            if self.selectedCompanyId == nil {
                self.navigationItem.rightBarButtonItem?.enabled = true
                let alert = UIAlertController(title: "Alert", message: "Please select a company", preferredStyle: UIAlertControllerStyle.Alert)
                let okAction = UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: { (alert: UIAlertAction) -> Void in
                })
                
                alert.addAction(okAction)
                self.navigationController?.presentViewController(alert, animated: true, completion: nil)
            }
            
            if let findBeacon = self.findBeacon, selectedCompanyId = self.selectedCompanyId {
                if let clBeaconValue = self.clBeacon {
                    let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
                    let urlFar = self.outUrlValueTextField.text != nil && self.outUrlValueTextField.text != "http://" ? self.outUrlValueTextField!.text! : ""
                    let urlNear = self.inUrlValueTextField.text != nil && self.inUrlValueTextField.text != "http://" ? self.inUrlValueTextField!.text! : ""
                    let lat = appDelegate.currentLocation?.coordinate.latitude.description ?? ""
                    let long = appDelegate.currentLocation?.coordinate.longitude.description ?? ""
                    
                    self.showLoading()
                    findBeacon.addBeacon(addBeaconUrl, username: PFUser.currentUser()?.username ?? "", uuid: clBeaconValue.proximityUUID.UUIDString, major: clBeaconValue.major.stringValue, minor: clBeaconValue.minor.stringValue, accuracy: clBeaconValue.accuracy.description, rssi: clBeaconValue.rssi.description, macAddress: UIDevice().identifierForVendor?.UUIDString ?? "", nickName: self.nickNameTextField.text ?? "", lat: lat, long: long, urlFar: urlFar, urlNear: urlNear, companyId: selectedCompanyId, notifyTitleFar: self.notifyTitleTextField.text ?? "", notifyTextFar: self.notifyTextTextField.text ?? "", notifyTitleNear: self.notifyTitleNearTextField.text ?? "", notifyTextNear: self.notifyTextNearTextField.text ?? "", completionHandler:  { result, message in
                        
                        dispatch_async(dispatch_get_main_queue(), {
                            self.navigationItem.rightBarButtonItem?.enabled = true
                            self.hideLoading()
                            
                            self.tableView.resignFirstResponder()
                            let title = result ? "Success!" : "Alert"
                            let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.Alert)
                            let okAction = UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: { (alert: UIAlertAction) -> Void in
                                if result {
                                    //self.viewController?.reset()
                                    self.viewController?.mainTabBarController?.reload()
                                    self.navigationController?.popViewControllerAnimated(true)
                                }
                            })
                            
                            alert.addAction(okAction)
                            
                            self.navigationController?.presentViewController(alert, animated: true, completion: { () -> Void in
                            })
                        })
                    })
                    
                }
            }
        }
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        self.tableView.deselectRowAtIndexPath(indexPath, animated: true)
        
        if indexPath.row == 3 {
            if let selectCompanyViewController = self.storyboard?.instantiateViewControllerWithIdentifier("SelectCompanyViewController") as? SelectCompanyViewController {
                selectCompanyViewController.beaconDetailViewController = self
                self.navigationController?.pushViewController(selectCompanyViewController, animated: true)
            }
        }
    }
    
    func updateSelectedCompanyValue(company: Company) {
        self.selectedCompanyId = company.idHash
        self.companyValueLabel.text = company.name
    }
    
    func updateAccuracy() {
        if let currentClBeacon = self.clBeacon, clBeacon = (self.viewController?.foundBeacons.filter { $0 == currentClBeacon }.first) {
            self.clBeacon = clBeacon
            self.accuracyValueLabel?.text = clBeacon.accuracy.description
            self.rssiValueLabel.text = clBeacon.rssi.description
        }
    }
    
    @IBAction func updateTapped(sender: UIButton) {
        self.navigationItem.rightBarButtonItem?.enabled = false
        self.tableView.resignFirstResponder()
        if let findBeacon = self.findBeacon, selectedCompanyId = self.selectedCompanyId {
            if let clBeaconValue = self.clBeacon, beacon = self.beacon, beaconId = beacon.id {
                let urlFar = self.outUrlValueTextField.text != nil && self.outUrlValueTextField.text != "http://" ? self.outUrlValueTextField!.text! : ""
                let urlNear = self.inUrlValueTextField.text != nil && self.inUrlValueTextField.text != "http://" ? self.inUrlValueTextField!.text! : ""
                let lat = beacon.latitude ?? ""
                let long = beacon.longitude ?? ""
                
                findBeacon.updateBeacon(updateBeaconUrl, username: PFUser.currentUser()?.username ?? "", beaconId: beaconId, uuid: clBeaconValue.proximityUUID.UUIDString, major: clBeaconValue.major.stringValue, minor: clBeaconValue.minor.stringValue, accuracy: clBeaconValue.accuracy.description, rssi: clBeaconValue.rssi.description, macAddress: UIDevice().identifierForVendor?.UUIDString ?? "", nickName: self.nickNameTextField.text ?? "", lat: lat, long: long, urlFar: urlFar, urlNear: urlNear, companyId: selectedCompanyId, notifyTitle: self.notifyTitleTextField.text ?? "", notifyText: self.notifyTextTextField.text ?? "", completionHandler:  { result, message in
                    
                    dispatch_async(dispatch_get_main_queue(), {
                        self.navigationItem.rightBarButtonItem?.enabled = true
                        
                        self.tableView.resignFirstResponder()
                        let alert = UIAlertController(title: "Alert", message: message, preferredStyle: UIAlertControllerStyle.Alert)
                        let okAction = UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: { (alert: UIAlertAction) -> Void in
                            if result {
                                self.viewController?.reset()
                                self.navigationController?.popViewControllerAnimated(true)
                            }
                            else {
                                self.navigationItem.rightBarButtonItem?.enabled = true
                            }
                        })
                        
                        alert.addAction(okAction)
                        
                        self.navigationController?.presentViewController(alert, animated: true, completion: { () -> Void in
                        })
                    })
                })
                
            }
        }
    }
}