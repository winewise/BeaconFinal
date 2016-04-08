//
//  AddCompanyViewController.swift
//  BeaconSearchApp
//
//  Created by Hafiz Usama on 2015-12-10.
//  Copyright © 2015 Ap1. All rights reserved.
//

import UIKit
import BeaconSearch

let addCompanyUrl = "http://159.203.15.175/filemaker/addCompany.php"
let updateCompanyUrl = "http://159.203.15.175/filemaker/editCompany.php"

enum FieldType {
    case LabelTextField
    case Select
    case Picker
}
enum CompanyField
{
    case LabelText(String, String, String, FieldType)
}

class AddCompanyViewController: UITableViewController, ColorPickerDelegate {

    var dataFields: [CompanyField] = []
    weak var selectCompanyViewController: SelectCompanyViewController?
    var colorPickerViewController: ColorPickerViewController?
    var company: Company?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        var latitude = ""
        var longitude = ""
        if let _ = self.company {
            self.title = "Company Detail"
            latitude = self.company?.latitude ?? ""
            longitude = self.company?.longitude ?? ""
            
        }
        else if let currentLocation = (UIApplication.sharedApplication().delegate as? AppDelegate)?.currentLocation {
            latitude = currentLocation.coordinate.latitude.description
            longitude = currentLocation.coordinate.longitude.description
        }
        
        dataFields.append(CompanyField.LabelText("Name", "Type name", company?.name ?? "", .LabelTextField))
        dataFields.append(CompanyField.LabelText("Color", "Type color", company?.color ?? "", .Select))
        dataFields.append(CompanyField.LabelText("Latitude", "Type latitude", latitude, .LabelTextField))
        dataFields.append(CompanyField.LabelText("Longitude", "Type longitude", longitude, .LabelTextField))
        
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(AddCompanyViewController.dismissKeyboard(_:)))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
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
        return dataFields.count
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var cell: UITableViewCell!
        
        switch(self.dataFields[indexPath.row]) {
        case .LabelText(let label, let placeholder, let text, let type):
            if .LabelTextField == type {
                let labelTextFieldCell = tableView.dequeueReusableCellWithIdentifier("LabelTextFieldCell", forIndexPath: indexPath) as! LabelTextFieldCell
                labelTextFieldCell.label.text = label
                labelTextFieldCell.textField.placeholder = placeholder
                labelTextFieldCell.textField.text = text
                
                labelTextFieldCell.addCompanyViewController = self
                labelTextFieldCell.currentIndexPath = indexPath
                cell = labelTextFieldCell
            }
            else if .Select == type {
                let selectCell = tableView.dequeueReusableCellWithIdentifier("SelectCell", forIndexPath: indexPath) as! SelectCell
                selectCell.label.text = label
                selectCell.valueTextField.text = text
                selectCell.addCompanyViewController = self
                selectCell.currentIndexPath = indexPath
                cell = selectCell
            }
            else if .Picker == type {
                let colorPickerCell = tableView.dequeueReusableCellWithIdentifier("ColorPickerCell", forIndexPath: indexPath) as! ColorPickerCell
                colorPickerCell.addCompanyViewController = self
                colorPickerCell.currentIndexPath = indexPath
                cell = colorPickerCell
            }
        }
        
        return cell
    }

    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        switch(self.dataFields[indexPath.row]) {
        case .LabelText( _,  _,  _, let type):
            if .Select == type {
                self.tableView.beginUpdates()
                if dataFields.count == 5 {
                    dataFields.removeAtIndex(2)
                    self.tableView.deleteRowsAtIndexPaths([NSIndexPath(forItem: 2, inSection: 0)], withRowAnimation: UITableViewRowAnimation.Automatic)
                }
                else {
                    dataFields.insert(CompanyField.LabelText("", "", "", .Picker), atIndex: 2)
                    self.tableView.insertRowsAtIndexPaths([NSIndexPath(forItem: 2, inSection: 0)], withRowAnimation: UITableViewRowAnimation.Automatic)
                }
                
                self.tableView.endUpdates()
            }
        }
    }
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        if dataFields.count == 5 && indexPath.row == 2 {
            return 200
        }
        
        return super.tableView(tableView, heightForRowAtIndexPath: indexPath)
    }
    
    func updateDataField(indexPath: NSIndexPath, value: String) {
        if case .LabelText(let label, let placeholder, _, let type) = self.dataFields[indexPath.row] {
            if type == .Picker {
                let selectIndex = NSIndexPath(forItem: 1, inSection: 0)
                if case .LabelText(let label, let placeholder, _, let type) = self.dataFields[selectIndex.row] {
                    self.dataFields[selectIndex.row] = CompanyField.LabelText(label, placeholder, value, type)
                }
                
                self.tableView.reloadRowsAtIndexPaths([selectIndex], withRowAnimation: UITableViewRowAnimation.None)
            }
            else {
                self.dataFields[indexPath.row] = CompanyField.LabelText(label, placeholder, value, type)
                self.tableView.reloadRowsAtIndexPaths([indexPath], withRowAnimation: UITableViewRowAnimation.None)
            }
        }
    }
    
    func dismissKeyboard(sender: AnyObject) {
        view.endEditing(true)
    }
    
    @IBAction func cancelButtonTapped(sender: UIBarButtonItem) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    @IBAction func saveButtonTapped(sender: UIBarButtonItem) {
        self.view.endEditing(true)
        
        if let company = self.company, idHash = company.idHash, findBeacon = self.selectCompanyViewController?.findBeaconContext {
            if case .LabelText(_, _, let name, _) = self.dataFields[0], case .LabelText(_, _, let color, _) = self.dataFields[1], case .LabelText(_, _, let latitude, _) = self.dataFields[2], case .LabelText(_, _, let longitude, _) = self.dataFields[3] {
                self.showLoading()
                self.navigationItem.rightBarButtonItem?.enabled = false
                findBeacon.updateCompany(updateCompanyUrl, company: company, hasdId: idHash, companyName: name, color: color, latitude: latitude, longitude: longitude, completionHandler: { (result, message) -> Void in
                    dispatch_async(dispatch_get_main_queue(), {
                        self.hideLoading()
                        self.navigationItem.rightBarButtonItem?.enabled = true
                        
                        self.tableView.resignFirstResponder()
                        let alert = UIAlertController(title: "Alert", message: message, preferredStyle: UIAlertControllerStyle.Alert)
                        let okAction = UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: { (alert: UIAlertAction) -> Void in
                            if result {
                                self.dismissViewControllerAnimated(true, completion: { () -> Void in
                                    self.selectCompanyViewController?.tableView.reloadData()
                                })
                            }
                        })
                        
                        alert.addAction(okAction)
                        
                        self.navigationController?.presentViewController(alert, animated: true, completion: { () -> Void in
                        })
                    })
                })
            }
        }
        else {
            if let findBeacon = self.selectCompanyViewController?.findBeaconContext {
                if case .LabelText(_, _, let name, _) = self.dataFields[0], case .LabelText(_, _, let color, _) = self.dataFields[1], case .LabelText(_, _, let latitude, _) = self.dataFields[2], case .LabelText(_, _, let longitude, _) = self.dataFields[3] {
                    
                    self.showLoading()
                    self.navigationItem.rightBarButtonItem?.enabled = false
                    let bundleIdentifier = NSBundle.mainBundle().bundleIdentifier ?? ""
                    findBeacon.addCompany(addCompanyUrl, username: PFUser.currentUser()?.username ?? "", bundleId: bundleIdentifier, companyName: name, color: color, latitude: latitude, longitude: longitude, completionHandler: { (result, message) -> Void in
                        
                        dispatch_async(dispatch_get_main_queue(), {
                            self.hideLoading()
                            self.navigationItem.rightBarButtonItem?.enabled = true
                            
                            self.tableView.resignFirstResponder()
                            let alert = UIAlertController(title: "Alert", message: message, preferredStyle: UIAlertControllerStyle.Alert)
                            let okAction = UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: { (alert: UIAlertAction) -> Void in
                                if result {
                                    self.dismissViewControllerAnimated(true, completion: { () -> Void in
                                        self.selectCompanyViewController?.updateCompanies()
                                    })
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
}