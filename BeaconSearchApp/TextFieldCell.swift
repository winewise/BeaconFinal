//
//  TextFieldCell.swift
//  BeaconSearchApp
//
//  Created by Hafiz Usama on 2016-02-18.
//  Copyright © 2016 Ap1. All rights reserved.
//

import UIKit

class TextFieldCell: UITableViewCell, UITextFieldDelegate {

    var indexPath: NSIndexPath?
    var data: SettingsRow?
    var delegate: SettingsFormDelegate?
    
    @IBOutlet weak var textField: UITextField!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func textFieldShouldEndEditing(textField: UITextField) -> Bool {
        if let indexPath = indexPath, row = data, text = self.textField.text {
            if case .TextField(let title, _, let type) = row {
                self.delegate?.updateFormField(indexPath, row: .TextField(title, text, type))
            }
        }
        
        return true
    }
}
