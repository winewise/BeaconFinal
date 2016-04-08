//
//  SwitchCell.swift
//  BeaconSearchApp
//
//  Created by Hafiz Usama on 2016-02-18.
//  Copyright © 2016 Ap1. All rights reserved.
//

import UIKit

class SwitchCell: UITableViewCell {

    var indexPath: NSIndexPath?
    var data: SettingsRow?
    var delegate: SettingsFormDelegate?
    
    @IBOutlet weak var title: UILabel!
    @IBOutlet weak var switchView: UISwitch!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

    @IBAction func valueChanged(sender: UISwitch) {
        if let indexPath = indexPath, row = data {
            if case .SwitchView(let title, _, let type) = row {
                self.delegate?.updateFormField(indexPath, row: .SwitchView(title, switchView.on, type))
            }
        }
    }
}