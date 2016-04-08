//
//  LabelTextFieldCell.swift
//  BeaconSearchApp
//
//  Created by Hafiz Usama on 2015-12-10.
//  Copyright © 2015 Ap1. All rights reserved.
//

import UIKit

class LabelTextFieldCell: UITableViewCell {
    
    var currentIndexPath: NSIndexPath?
    weak var addCompanyViewController: AddCompanyViewController?
    
    @IBOutlet weak var label: UILabel!
    @IBOutlet weak var textField: UITextField!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

    @IBAction func textFieldEditingDidEnd(sender: UITextField) {
        if let indexPath = currentIndexPath, value = sender.text {
            self.addCompanyViewController?.updateDataField(indexPath, value: value)
        }
    }
}