//
//  SelectCell.swift
//  BeaconSearchApp
//
//  Created by Developer 1 on 2015-12-17.
//  Copyright © 2015 Ap1. All rights reserved.
//

import UIKit

class SelectCell: UITableViewCell, UITextFieldDelegate {
    
    weak var addCompanyViewController: AddCompanyViewController?
    var currentIndexPath: NSIndexPath?
    var delegate: ColorPickerDelegate?
    
    @IBOutlet weak var label: UILabel!
    @IBOutlet weak var valueTextField: UITextField!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.valueTextField.delegate = self
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

    func textField(textField: UITextField, shouldChangeCharactersInRange range: NSRange, replacementString string: String) -> Bool {
        
        guard let text = textField.text else { return true }
        
        let inverseSet = NSCharacterSet(charactersInString:"0123456789abcdef").invertedSet

        let components = string.componentsSeparatedByCharactersInSet(inverseSet)
        
        let filtered = components.joinWithSeparator("")
        
        let newLength = text.utf16.count + string.utf16.count - range.length
        return newLength <= 6 && string == filtered
    }
    
    func textFieldShouldEndEditing(textField: UITextField) -> Bool {
        if let indexPath = self.currentIndexPath, text = textField.text {
            self.delegate?.updateDataField(indexPath, value: text)
        }
        
        return true
    }
    
    @IBAction func addButtonTapped(sender: AnyObject) {
        if let navigationController = UIStoryboard(name: "ColorPicker", bundle: nil).instantiateInitialViewController() as? UINavigationController, colorPickerViewController = navigationController.topViewController as? ColorPickerViewController {
            colorPickerViewController.currentIndexPath = currentIndexPath
            colorPickerViewController.delegate = self.addCompanyViewController
            colorPickerViewController.initialColor = self.valueTextField.text!.isEmpty ? UIColor.redColor() : UIColor(hexString: self.valueTextField.text!)
            
            self.addCompanyViewController?.colorPickerViewController = colorPickerViewController
            self.addCompanyViewController?.navigationController?.pushViewController(colorPickerViewController, animated: true)
        }
    }
}