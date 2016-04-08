//
//  SettingsViewController.swift
//  BeaconSearchApp
//
//  Created by Hafiz Usama on 2016-01-20.
//  Copyright © 2016 Ap1. All rights reserved.
//

import UIKit
import BeaconSearch

enum UserField {
    case FirstName
    case LastName
    case Nickname
    case AboutMe
    case Visible
    case ShowPicture
    case Incognito
    case Color
    
    var key: String {
        switch self {
        case FirstName:
            return "first_name"
        case LastName:
            return "last_name"
        case Nickname:
            return "nickname"
        case AboutMe:
            return "about_me"
        case Visible:
            return "visible"
        case ShowPicture:
            return "show_picture"
        case Incognito:
            return "incognito"
        case Color:
            return "color"
        }
    }
}

enum SettingsRow {
    case UploadImage(UIImage?)
    case TextField(String, String, UserField)
    case SwitchView(String, Bool, UserField)
    case ColorSelect(String, String, UserField)
    case ColorPicker
}

let kUploadImageCell = "UploadImageCell"
let kTextFieldCell = "TextFieldCell"
let kSwitchCell = "SwitchCell"

protocol SettingsFormDelegate {
    func updateFormField(indexPath: NSIndexPath, row: SettingsRow)
}

class SettingsViewController: UITableViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, SettingsFormDelegate, ColorPickerDelegate {

    var rows: [SettingsRow] = []
    let imagePicker = UIImagePickerController()
    weak var mainTabBarController: MainTabBarController?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(SettingsViewController.dismissKeyboard(_:)))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
        
        imagePicker.delegate = self
        self.prepareData()
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
        return rows.count
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var requiredCell: UITableViewCell!
        
        switch(self.rows[indexPath.row]) {
        case .UploadImage(let image):
            if let cell = tableView.dequeueReusableCellWithIdentifier(kUploadImageCell, forIndexPath: indexPath) as? UploadImageCell {
                cell.settingsViewController = self
                if let image = image {
                    cell.uploadImageView?.image = image
                    cell.setNeedsLayout()
                }
                
                requiredCell = cell
            }
        case .TextField(let title, let value, _):
            if let cell = tableView.dequeueReusableCellWithIdentifier(kTextFieldCell, forIndexPath: indexPath) as? TextFieldCell {
                cell.delegate = self
                cell.indexPath = indexPath
                cell.data = self.rows[indexPath.row]
                cell.textField.placeholder = title
                cell.textField.text = value
                
                requiredCell = cell
            }
        case .SwitchView(let title, let value, _):
            if let cell = tableView.dequeueReusableCellWithIdentifier(kSwitchCell, forIndexPath: indexPath) as? SwitchCell {
                cell.delegate = self
                cell.indexPath = indexPath
                cell.data = self.rows[indexPath.row]
                cell.title.text = title
                cell.switchView.on = value
                
                requiredCell = cell
            }
        case .ColorSelect(let title, let value, _):
            if let selectCell = tableView.dequeueReusableCellWithIdentifier("SelectCell", forIndexPath: indexPath) as? SelectCell {
                selectCell.label.text = title
                selectCell.valueTextField.text = value
                selectCell.delegate = self
                selectCell.currentIndexPath = indexPath
                requiredCell = selectCell
            }
            
        default:
            break
        }

        return requiredCell
    }
    
    override func tableView(tableView: UITableView, accessoryButtonTappedForRowWithIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        switch(self.rows[indexPath.row]) {
        case .ColorSelect(_,  let value, _):
            if let navigationController = UIStoryboard(name: "ColorPicker", bundle: nil).instantiateInitialViewController() as? UINavigationController, colorPickerViewController = navigationController.topViewController as? ColorPickerViewController {
                colorPickerViewController.currentIndexPath = indexPath
                colorPickerViewController.delegate = self
                colorPickerViewController.initialColor = value.isEmpty ? UIColor.redColor() : UIColor(hexString: value)
                self.navigationController?.pushViewController(colorPickerViewController, animated: true)
            }
        default:
            break
        }
    }
    
    override func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 0.01
    }
    
    override func tableView(tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 0.01
    }
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        if indexPath.row == 0 {
            return 170
        }
        
        return 46
    }

    func prepareData() {
        
        var currentUserImage: UIImage?
        if let user = PFUser.currentUser() {
            if let pfFile = user.objectForKey("profile_picture") as? PFFile {
                do {
                    let data = try pfFile.getData()
                    if let image = UIImage(data: data) {
                        currentUserImage = image
                    }
                }
                catch {
                }
            }
            
            self.rows.append(.UploadImage(currentUserImage))
            let firstName = (user.objectForKey("first_name") ?? "") as! String
            let lastName = (user.objectForKey("last_name") ?? "") as! String
            let nickname = (user.objectForKey("nickname") ?? "") as! String
            let aboutMe = (user.objectForKey("about_me") ?? "") as! String
            let visible = (user.objectForKey("visible") ?? false) as! Bool
            let showPicture = (user.objectForKey("show_picture") ?? false) as! Bool
            let incognito = (user.objectForKey("incognito") ?? false) as! Bool
            let color = (user.objectForKey("color") ?? "") as! String
            
            self.rows.append(.TextField("First name", firstName, .FirstName))
            self.rows.append(.TextField("Last name", lastName, .LastName))
            self.rows.append(.TextField("Nickname", nickname, .Nickname))
            self.rows.append(.TextField("About me", aboutMe, .AboutMe))
            self.rows.append(.SwitchView("Visible", visible, .Visible))
            self.rows.append(.SwitchView("Show picture", showPicture, .ShowPicture))
            self.rows.append(.SwitchView("Incognito", incognito, .Incognito))
            self.rows.append(.ColorSelect("Color", color, .Color))
        }
    }

    func loadImagePicker() {
        imagePicker.allowsEditing = false
        imagePicker.sourceType = .PhotoLibrary
        
        self.presentViewController(imagePicker, animated: true, completion: nil)
    }
    
    // UIImagePickerControllerDelegate
    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : AnyObject]) {
        if let pickedImage = info[UIImagePickerControllerOriginalImage] as? UIImage {
            self.rows[0] = .UploadImage(pickedImage)
            self.tableView.reloadRowsAtIndexPaths([NSIndexPath(forRow: 0, inSection: 0)], withRowAnimation: UITableViewRowAnimation.Automatic)
            //uploadImageView.contentMode = .ScaleAspectFit
            //uploadImageView.image = pickedImage
        }
        
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(picker: UIImagePickerController) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func dismissKeyboard(sender: AnyObject) {
        view.endEditing(true)
    }
    
    func updateFormField(indexPath: NSIndexPath, row: SettingsRow) {
        self.rows[indexPath.row] = row
        
        if case .SwitchView(_, let value, let type) = row {
            if type == .Incognito && value {
                var i = 0
                for row in self.rows {
                    switch row {
                    case .SwitchView(let title, _, let userField):
                        if userField == .ShowPicture || userField == .Visible {
                            self.rows[i] = .SwitchView(title, false, userField)
                        }
                    default:
                        break
                    }
                    
                    i += 1
                }
                
                self.tableView.reloadData()
            }
        }
    }
    
    func updateDataField(indexPath: NSIndexPath, value: String) {
        if case .ColorSelect(let title, _, let type) = self.rows[indexPath.row] {
            self.rows[indexPath.row] = .ColorSelect(title, value, type)
        }
        
        self.tableView.reloadData()
    }
    
    @IBAction func doneTapped(sender: UIBarButtonItem) {
        view.endEditing(true)
        self.showLoading()
        
        var incognito = false
        for row in self.rows {
            switch row {
            case .UploadImage(let pickedImage):
                if let image = pickedImage, data = UIImageJPEGRepresentation(image, 0.5), profileFileObject = PFFile(data: data) {
                    PFUser.currentUser()?.setObject(profileFileObject, forKey: "profile_picture")
                }
            case .TextField(_, let value, let userField):
                PFUser.currentUser()?.setObject(value, forKey: userField.key)
            case .SwitchView(_, let value, let userField):
                PFUser.currentUser()?.setObject(value, forKey: userField.key)
                if userField == .Incognito && value {
                    incognito = true
                }
            case .ColorSelect(_, let value, let userField):
                PFUser.currentUser()?.setObject(value, forKey: userField.key)
            default:
                continue
            }
        }
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), {
            do {
                try PFUser.currentUser()?.save()
            }
            catch {
                print("Error Saving PFUser")
            }
            
            dispatch_async(dispatch_get_main_queue(), {
                if let user = PFUser.currentUser() {
                    self.mainTabBarController?.loginViewController?.setKeenUserGlobalProperties(user)
                }
                
                self.mainTabBarController?.chatViewController?.resetForUserRefresh()
                if incognito {
                    self.mainTabBarController?.chatViewController?.stop()
                }
                
                self.hideLoading()
                self.dismissViewControllerAnimated(true, completion: nil)
            })
        })
    }
    
    @IBAction func cancelTapped(sender: UIBarButtonItem) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
}